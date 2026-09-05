import CoreGraphics
import Foundation

final class AISystem {
    private var cooldown: TimeInterval = 0
    private var awayHold: TimeInterval = 0
    private var awayCharging: Bool = false

    func update(context: MatchContext, dt: TimeInterval) {
        guard context.state.phase == .inPlay
                || context.state.phase == .centrePass
                || context.state.phase == .overtime else {
            clearTargets(context)
            return
        }

        cooldown -= dt
        if cooldown <= 0 {
            cooldown = context.config.aiDecisionInterval
            decide(context: context)
        }

        handleAwayWithBall(context: context, dt: dt)
    }

    private func clearTargets(_ context: MatchContext) {
        for athlete in context.athletes.values where !athlete.isHumanControlled || !athlete.isSelected {
            athlete.targetPoint = nil
        }
    }

    private func decide(context: MatchContext) {
        for athlete in context.athletes.values {
            if athlete.isHumanControlled && athlete.isSelected { continue }
            athlete.targetPoint = desiredPoint(for: athlete, context: context)
        }
    }

    private func desiredPoint(for athlete: Athlete, context: MatchContext) -> CGPoint {
        let formation = athlete.id.role.defaultFormation(in: context.geometry, team: athlete.id.side)
        let ballPoint = context.ball.courtPosition
        let hoop = context.geometry.hoopPosition(for: athlete.id.side.opposing)

        // Tip-off / centre pass: hold lanes. Do not collapse onto the centre line.
        if context.state.phase == .centrePass {
            return formation
        }

        if athlete.hasBall {
            return formation
        }

        if athlete.id.side == .away {
            if let carrier = context.carrier(), carrier.id.side == .home {
                return markPoint(of: carrier, hoop: context.geometry.hoopPosition(for: .home), athlete: athlete, context: context, laneX: formation.x)
            }
            if let carrier = context.carrier(), carrier.id.side == .away, carrier.id != athlete.id {
                return supportLane(from: carrier, athlete: athlete, context: context, laneX: formation.x)
            }
            return blend(formation, ballPoint, t: 0.18)
        }

        if let carrier = context.carrier() {
            if carrier.id.side == .home, carrier.id != athlete.id {
                return supportLane(from: carrier, athlete: athlete, context: context, laneX: formation.x)
            }
            if carrier.id.side == .away {
                return markPoint(of: carrier, hoop: hoop, athlete: athlete, context: context, laneX: formation.x)
            }
        }
        return blend(formation, ballPoint, t: 0.12)
    }

    private func markPoint(of target: Athlete, hoop: CGPoint, athlete: Athlete, context: MatchContext, laneX: CGFloat) -> CGPoint {
        let dx = hoop.x - target.courtPosition.x
        let dy = hoop.y - target.courtPosition.y
        let len = max(1, hypot(dx, dy))
        let mark = context.config.aiMarkDistance
        let point = CGPoint(
            x: laneX * 0.65 + (target.courtPosition.x + dx / len * mark) * 0.35,
            y: target.courtPosition.y + dy / len * mark
        )
        let zone = athlete.id.role.legalZone(in: context.geometry, team: athlete.id.side)
        return context.geometry.nearestPoint(in: zone, to: point)
    }

    private func supportLane(from carrier: Athlete, athlete: Athlete, context: MatchContext, laneX: CGFloat) -> CGPoint {
        let attack = carrier.id.side.attackDirection
        let ahead: CGFloat = athlete.id.role.canShoot ? 70 : 40
        let raw = CGPoint(
            x: laneX,
            y: carrier.courtPosition.y + attack.dy * ahead
        )
        let zone = athlete.id.role.legalZone(in: context.geometry, team: athlete.id.side)
        return context.geometry.nearestPoint(in: zone, to: raw)
    }

    private func blend(_ a: CGPoint, _ b: CGPoint, t: CGFloat) -> CGPoint {
        CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
    }

    private func handleAwayWithBall(context: MatchContext, dt: TimeInterval) {
        guard let carrier = context.carrier(), carrier.id.side == .away else {
            awayHold = 0
            awayCharging = false
            return
        }
        if context.ball.isInFlight { return }

        if awayCharging {
            if var meter = context.state.shootMeter, meter.charging {
                meter.value += meter.direction * context.config.shotChargeSpeed * CGFloat(dt)
                if meter.value >= context.config.shotSweetMin + 0.08 {
                    context.state.shootMeter = meter
                    ShootSystem().releaseAIShot(context: context)
                    awayCharging = false
                    awayHold = 0
                    return
                }
                context.state.shootMeter = meter
            }
            return
        }

        awayHold += dt
        if awayHold < context.config.aiReactionDelay { return }

        let shoot = ShootSystem()
        if shoot.canShoot(carrier, context: context) {
            shoot.beginAICharge(context: context)
            awayCharging = true
            return
        }

        if let receiver = PassSystem().chooseReceiver(from: carrier, context: context) {
            let danger = context.roster(for: .home)
                .map { hypot($0.courtPosition.x - receiver.courtPosition.x, $0.courtPosition.y - receiver.courtPosition.y) }
                .min() ?? 80
            if danger > 22 || context.random01() > context.config.aiPassSafety * 0.4 {
                PassSystem().launchAIPass(from: carrier, to: receiver, context: context)
                awayHold = 0
                return
            }
        }

        let face = carrier.id.side.attackDirection
        carrier.facing = atan2(face.dy, face.dx)
        awayHold = 0
    }
}
