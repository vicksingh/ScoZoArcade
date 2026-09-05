import CoreGraphics
import Foundation

struct PassSystem {
    func update(context: MatchContext, dt: TimeInterval) {
        if context.input.consumePass() {
            attemptPass(context: context)
        }
        advanceFlight(context: context, dt: dt)
        tryPickup(context: context)
    }

    func attemptPass(context: MatchContext) {
        guard context.state.phase == .inPlay
                || context.state.phase == .centrePass
                || context.state.phase == .overtime else {
            return
        }
        guard !context.ball.isInFlight else { return }
        guard let passer = homePasser(in: context) else {
            context.emit(.hint("WIN THE BALL"))
            return
        }

        let target = chooseReceiver(from: passer, context: context)
        guard let receiver = target else {
            context.emit(.hint("NO TARGET"))
            return
        }

        let distance = hypot(
            receiver.courtPosition.x - passer.courtPosition.x,
            receiver.courtPosition.y - passer.courtPosition.y
        )
        if distance > context.config.passMaxRange {
            context.emit(.hint("TOO FAR"))
            return
        }

        passer.hasBall = false
        context.state.clearPossession()
        if passer.id.side == .home {
            context.state.stats.homePasses += 1
        } else {
            context.state.stats.awayPasses += 1
        }

        let duration = TimeInterval(distance / max(context.config.passSpeed, 1))
        context.ball.launch(
            kind: .pass,
            from: passer.courtPosition,
            to: receiver.courtPosition,
            duration: duration,
            lift: 26,
            shooter: passer.id
        )
        if context.state.phase == .centrePass {
            context.state.enterInPlay()
        }
    }

    func launchAIPass(from passer: Athlete, to receiver: Athlete, context: MatchContext) {
        guard !context.ball.isInFlight, passer.hasBall else { return }
        let distance = hypot(
            receiver.courtPosition.x - passer.courtPosition.x,
            receiver.courtPosition.y - passer.courtPosition.y
        )
        guard distance <= context.config.passMaxRange else { return }
        passer.hasBall = false
        context.state.clearPossession()
        context.state.stats.awayPasses += 1
        context.ball.launch(
            kind: .pass,
            from: passer.courtPosition,
            to: receiver.courtPosition,
            duration: TimeInterval(distance / max(context.config.passSpeed, 1)),
            lift: 24,
            shooter: passer.id
        )
        if context.state.phase == .centrePass {
            context.state.enterInPlay()
        }
    }

    private func homePasser(in context: MatchContext) -> Athlete? {
        guard let selected = context.selectedHome(), selected.hasBall else { return nil }
        guard context.state.ballOwner == selected.id else { return nil }
        return selected
    }

    func chooseReceiver(from passer: Athlete, context: MatchContext) -> Athlete? {
        let teammates = context.roster(for: passer.id.side).filter { $0.id != passer.id }
        guard !teammates.isEmpty else { return nil }

        let aim = aimVector(from: passer, context: context)
        var best: Athlete?
        var bestScore: CGFloat = -.greatestFiniteMagnitude

        for mate in teammates {
            let dx = mate.courtPosition.x - passer.courtPosition.x
            let dy = mate.courtPosition.y - passer.courtPosition.y
            let dist = hypot(dx, dy)
            guard dist > 8, dist <= context.config.passMaxRange else { continue }
            let dir = CGVector(dx: dx / dist, dy: dy / dist)
            let alignment = dir.dx * aim.dx + dir.dy * aim.dy
            let forward = dir.dx * passer.id.side.attackDirection.dx + dir.dy * passer.id.side.attackDirection.dy
            let pressure = nearestOpponentDistance(to: mate.courtPosition, passerSide: passer.id.side, context: context)
            let score = alignment * 1.4 + forward * 0.55 + (pressure / 80) - dist / 400
            if score > bestScore {
                bestScore = score
                best = mate
            }
        }
        return best ?? teammates.min {
            hypot($0.courtPosition.x - passer.courtPosition.x, $0.courtPosition.y - passer.courtPosition.y)
                < hypot($1.courtPosition.x - passer.courtPosition.x, $1.courtPosition.y - passer.courtPosition.y)
        }
    }

    private func aimVector(from passer: Athlete, context: MatchContext) -> CGVector {
        if let aim = context.input.aimPoint {
            let dx = aim.x - passer.courtPosition.x
            let dy = aim.y - passer.courtPosition.y
            let len = hypot(dx, dy)
            if len > 1 {
                return CGVector(dx: dx / len, dy: dy / len)
            }
        }
        let move = context.input.moveVector
        if hypot(move.dx, move.dy) > context.config.inputDeadZone {
            return move
        }
        if hypot(context.input.lastAimDirection.dx, context.input.lastAimDirection.dy) > 0.2 {
            return context.input.lastAimDirection
        }
        return passer.facingVector
    }

    private func nearestOpponentDistance(to point: CGPoint, passerSide: TeamSide, context: MatchContext) -> CGFloat {
        context.roster(for: passerSide.opposing)
            .map { hypot($0.courtPosition.x - point.x, $0.courtPosition.y - point.y) }
            .min() ?? 120
    }

    private func advanceFlight(context: MatchContext, dt: TimeInterval) {
        guard context.ball.flight == .pass else { return }
        context.ball.elapsed += dt
        let t = min(1, CGFloat(context.ball.elapsed / context.ball.duration))
        let eased = t * t * (3 - 2 * t)
        let lift = context.ball.lift * 4 * eased * (1 - eased)
        context.ball.courtPosition = CGPoint(
            x: context.ball.start.x + (context.ball.end.x - context.ball.start.x) * eased,
            y: context.ball.start.y + (context.ball.end.y - context.ball.start.y) * eased + lift * 0.02
        )

        if let interceptor = interceptingOpponent(context: context), t > 0.18, t < 0.92 {
            if context.random01() < context.config.interceptionChance {
                completeCatch(interceptor, context: context)
                context.emit(.intercept)
                return
            }
        }

        if t >= 1 {
            resolveArrival(context: context)
        }
    }

    private func interceptingOpponent(context: MatchContext) -> Athlete? {
        let side = context.ball.passerSide?.opposing ?? context.state.possessionSide?.opposing ?? .away
        return context.roster(for: side).first { athlete in
            hypot(athlete.courtPosition.x - context.ball.courtPosition.x,
                  athlete.courtPosition.y - context.ball.courtPosition.y) < context.config.interceptionRadius
        }
    }

    private func resolveArrival(context: MatchContext) {
        if let receiver = context.nearest(to: context.ball.end, side: nil) {
            let dist = hypot(receiver.courtPosition.x - context.ball.end.x,
                             receiver.courtPosition.y - context.ball.end.y)
            if dist <= context.config.catchRadius {
                completeCatch(receiver, context: context)
                return
            }
        }
        context.ball.drop(at: context.ball.end)
        context.state.clearPossession()
        context.emit(.hint("LOOSE BALL"))
    }

    private func completeCatch(_ athlete: Athlete, context: MatchContext) {
        for other in context.athletes.values { other.hasBall = false }
        athlete.hasBall = true
        context.ball.attach(to: athlete.id, at: athlete.courtPosition)
        context.state.setPossession(owner: athlete.id)
    }

    private func tryPickup(context: MatchContext) {
        guard context.ball.flight == .loose else { return }
        guard let nearest = context.nearest(to: context.ball.courtPosition, side: nil) else { return }
        let dist = hypot(
            nearest.courtPosition.x - context.ball.courtPosition.x,
            nearest.courtPosition.y - context.ball.courtPosition.y
        )
        if dist <= context.config.pickupRadius {
            completeCatch(nearest, context: context)
        }
    }
}
