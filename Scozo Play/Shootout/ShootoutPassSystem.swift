import CoreGraphics
import Foundation

struct ShootoutPassSystem {
    func update(context: ShootoutContext, dt: TimeInterval) {
        if context.input.consumePass() {
            attemptPass(context: context)
        }
        advanceFlight(context: context, dt: dt)
        tryPickup(context: context)
    }
    
    func attemptPass(context: ShootoutContext) {
        guard context.state.phase == .inPlay else { return }
        guard !context.ball.isInFlight else { return }
        guard let passer = homePasser(in: context) else {
            context.emit(.hint("WIN THE BALL"))
            return
        }
        
        guard let receiver = chooseReceiver(from: passer, context: context) else {
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
        context.state.stats.homePasses += 1
        context.passTargetID = nil
        
        let duration = TimeInterval(distance / max(context.config.passSpeed, 1))
        context.ball.launch(
            kind: .pass,
            from: passer.courtPosition,
            to: receiver.courtPosition,
            duration: duration,
            lift: 26,
            shooter: passer.id
        )
    }
    
    private func homePasser(in context: ShootoutContext) -> Athlete? {
        guard let selected = context.selectedHome(), selected.hasBall else { return nil }
        guard context.state.ballOwner == selected.id else { return nil }
        return selected
    }
    
    func chooseReceiver(from passer: Athlete, context: ShootoutContext) -> Athlete? {
        if let targetID = context.passTargetID, let target = context.athletes[targetID], target.id.side == .home {
            return target
        }
        return context.otherAttacker(from: passer.id)
    }
    
    private func advanceFlight(context: ShootoutContext, dt: TimeInterval) {
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
    
    private func interceptingOpponent(context: ShootoutContext) -> Athlete? {
        context.roster(for: .away).first { athlete in
            hypot(athlete.courtPosition.x - context.ball.courtPosition.x,
                  athlete.courtPosition.y - context.ball.courtPosition.y) < context.config.interceptionRadius
        }
    }
    
    private func resolveArrival(context: ShootoutContext) {
        if let receiver = context.nearest(to: context.ball.end, side: .home) {
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
    
    private func completeCatch(_ athlete: Athlete, context: ShootoutContext) {
        for other in context.athletes.values { other.hasBall = false }
        athlete.hasBall = true
        context.ball.attach(to: athlete.id, at: athlete.courtPosition)
        context.state.setPossession(owner: athlete.id)
    }
    
    private func tryPickup(context: ShootoutContext) {
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
