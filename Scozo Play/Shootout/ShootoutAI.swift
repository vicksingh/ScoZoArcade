import CoreGraphics
import Foundation

final class ShootoutAI {
    private var cooldown: TimeInterval = 0
    
    func update(context: ShootoutContext, dt: TimeInterval) {
        guard context.state.phase == .inPlay else {
            clearTargets(context)
            return
        }
        
        cooldown -= dt
        if cooldown <= 0 {
            cooldown = context.config.aiDecisionInterval * 0.8
            decide(context: context)
        }
    }
    
    private func clearTargets(_ context: ShootoutContext) {
        for athlete in context.athletes.values where athlete.id.side == .away {
            athlete.targetPoint = nil
        }
    }
    
    private func decide(context: ShootoutContext) {
        guard let gk = context.athlete(PlayerID(side: .away, role: .gk)),
              let gd = context.athlete(PlayerID(side: .away, role: .gd)) else {
            return
        }
        
        let hoop = context.geometry.hoopPosition(for: .home)
        let circleCenter = context.geometry.shootingCircleCenter(for: .home)
        let ballPoint = context.ball.courtPosition
        let carrier = context.carrier()
        
        gk.targetPoint = gkTarget(
            gk: gk,
            hoop: hoop,
            circleCenter: circleCenter,
            carrier: carrier,
            context: context
        )
        
        gd.targetPoint = gdTarget(
            gd: gd,
            carrier: carrier,
            offBall: context.roster(for: .home).first { $0.id != carrier?.id },
            ballPoint: ballPoint,
            context: context
        )
    }
    
    private func gkTarget(
        gk: Athlete,
        hoop: CGPoint,
        circleCenter: CGPoint,
        carrier: Athlete?,
        context: ShootoutContext
    ) -> CGPoint {
        guard let carrier else {
            return CGPoint(x: hoop.x, y: hoop.y - 20)
        }
        
        let inCircle = context.geometry.containsShootingCircle(carrier.courtPosition, for: .home)
        
        if inCircle && carrier.hasBall {
            let dx = carrier.courtPosition.x - hoop.x
            let dy = carrier.courtPosition.y - hoop.y
            let dist = max(1, hypot(dx, dy))
            let contestDist: CGFloat = 28
            let target = CGPoint(
                x: hoop.x + dx / dist * contestDist,
                y: hoop.y + dy / dist * contestDist
            )
            return clampToCircle(target, center: circleCenter, radius: context.geometry.shootingCircleRadius, context: context)
        }
        
        if context.ball.flight == .shot {
            return CGPoint(x: hoop.x, y: hoop.y - 16)
        }
        
        let biasX = (carrier.courtPosition.x - hoop.x) * 0.25
        return clampToCircle(
            CGPoint(x: hoop.x + biasX, y: hoop.y - 22),
            center: circleCenter,
            radius: context.geometry.shootingCircleRadius * 0.7,
            context: context
        )
    }
    
    private func gdTarget(
        gd: Athlete,
        carrier: Athlete?,
        offBall: Athlete?,
        ballPoint: CGPoint,
        context: ShootoutContext
    ) -> CGPoint {
        let circleCenter = context.geometry.shootingCircleCenter(for: .home)
        
        if context.ball.flight == .pass, let end = Optional(context.ball.end) {
            let interceptPoint = CGPoint(
                x: (context.ball.courtPosition.x + end.x) * 0.5,
                y: (context.ball.courtPosition.y + end.y) * 0.5
            )
            return clampToCircle(interceptPoint, center: circleCenter, radius: context.geometry.shootingCircleRadius, context: context)
        }
        
        if let carrier, carrier.hasBall {
            let markDist: CGFloat = context.config.aiMarkDistance
            let dx = carrier.courtPosition.x - circleCenter.x
            let dy = carrier.courtPosition.y - circleCenter.y
            let dist = max(1, hypot(dx, dy))
            let markPoint = CGPoint(
                x: carrier.courtPosition.x - dx / dist * markDist,
                y: carrier.courtPosition.y - dy / dist * markDist
            )
            return clampToCircle(markPoint, center: circleCenter, radius: context.geometry.shootingCircleRadius, context: context)
        }
        
        if let offBall {
            let dx = offBall.courtPosition.x - circleCenter.x
            let dy = offBall.courtPosition.y - circleCenter.y
            let dist = max(1, hypot(dx, dy))
            let cutPoint = CGPoint(
                x: offBall.courtPosition.x - dx / dist * 30,
                y: offBall.courtPosition.y - dy / dist * 30
            )
            return clampToCircle(cutPoint, center: circleCenter, radius: context.geometry.shootingCircleRadius * 0.85, context: context)
        }
        
        return CGPoint(x: circleCenter.x - 25, y: circleCenter.y - 20)
    }
    
    private func clampToCircle(_ point: CGPoint, center: CGPoint, radius: CGFloat, context: ShootoutContext) -> CGPoint {
        let dx = point.x - center.x
        let dy = point.y - center.y
        let dist = hypot(dx, dy)
        if dist <= radius {
            return context.geometry.clampToCourt(point, radius: context.config.playerRadius)
        }
        let clamped = CGPoint(
            x: center.x + dx / dist * radius,
            y: center.y + dy / dist * radius
        )
        return context.geometry.clampToCourt(clamped, radius: context.config.playerRadius)
    }
}
