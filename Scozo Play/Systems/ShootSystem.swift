import CoreGraphics
import Foundation
import UIKit

struct ShootSystem {
    func update(context: MatchContext, dt: TimeInterval) {
        if context.input.consumeShootPressed() {
            beginCharge(context: context)
        }
        if context.input.shootHeld {
            tickMeter(context: context, dt: dt)
        }
        if context.input.consumeShootReleased() {
            releaseShot(context: context)
        }
        advanceShot(context: context, dt: dt)
    }

    func canShoot(_ athlete: Athlete, context: MatchContext) -> Bool {
        guard athlete.hasBall, athlete.id.role.canShoot else { return false }
        return context.geometry.containsShootingCircle(athlete.courtPosition, for: athlete.id.side)
    }

    func beginCharge(context: MatchContext) {
        guard context.state.phase == .inPlay || context.state.phase == .overtime else { return }
        guard let shooter = context.carrier() else {
            context.emit(.hint("NEED THE BALL"))
            return
        }
        guard shooter.id.side == .home else { return }
        if let selected = context.selectedHome(), selected.id != shooter.id {
            context.emit(.hint("SWITCH TO BALL"))
            return
        }
        guard shooter.id.role.canShoot else {
            context.emit(.hint("ONLY GS / GA"))
            context.emit(.illegalShoot)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            return
        }
        guard context.geometry.containsShootingCircle(shooter.courtPosition, for: shooter.id.side) else {
            context.emit(.hint("ENTER THE CIRCLE"))
            context.emit(.illegalShoot)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            return
        }
        context.state.shootMeter = ShootMeterState(value: 0.08, charging: true, direction: 1)
    }

    func beginAICharge(context: MatchContext) {
        guard let shooter = context.carrier(), shooter.id.side == .away, canShoot(shooter, context: context) else { return }
        context.state.shootMeter = ShootMeterState(value: 0.12, charging: true, direction: 1)
    }

    func releaseAIShot(context: MatchContext) {
        releaseShot(context: context)
    }

    private func tickMeter(context: MatchContext, dt: TimeInterval) {
        guard var meter = context.state.shootMeter, meter.charging else { return }
        meter.value += meter.direction * context.config.shotChargeSpeed * CGFloat(dt)
        if meter.value >= 1 {
            meter.value = 1
            meter.direction = -1
        } else if meter.value <= 0 {
            meter.value = 0
            meter.direction = 1
        }
        context.state.shootMeter = meter
    }

    private func releaseShot(context: MatchContext) {
        guard var meter = context.state.shootMeter, meter.charging else { return }
        meter.charging = false
        context.state.shootMeter = meter
        guard let shooter = context.carrier(), canShoot(shooter, context: context) else {
            context.state.shootMeter = nil
            return
        }

        let hoop = context.geometry.hoopPosition(for: shooter.id.side)
        let distance = hypot(hoop.x - shooter.courtPosition.x, hoop.y - shooter.courtPosition.y)
        shooter.hasBall = false
        context.state.clearPossession()
        if shooter.id.side == .home {
            context.state.stats.homeShots += 1
        } else {
            context.state.stats.awayShots += 1
        }
        context.ball.launch(
            kind: .shot,
            from: shooter.courtPosition,
            to: hoop,
            duration: context.config.shotFlightTime,
            lift: 48,
            shooter: shooter.id
        )
        _ = distance
    }

    func shotSuccessChance(meter: CGFloat, distance: CGFloat, contested: Bool, config: GameConfig) -> CGFloat {
        let inSweet = meter >= config.shotSweetMin && meter <= config.shotSweetMax
        let sweetError = inSweet ? 0 : min(abs(meter - (config.shotSweetMin + config.shotSweetMax) * 0.5), 1)
        var chance: CGFloat = inSweet ? 0.86 : max(0.12, 0.72 - sweetError * 1.1)
        chance -= min(0.28, distance / 520)
        if contested { chance -= config.defenderBlockChance }
        return min(0.94, max(0.08, chance))
    }

    private func advanceShot(context: MatchContext, dt: TimeInterval) {
        guard context.ball.flight == .shot else { return }
        context.ball.elapsed += dt
        let t = min(1, CGFloat(context.ball.elapsed / context.ball.duration))
        let eased = 1 - pow(1 - t, 2)
        let lift = context.ball.lift * 4 * t * (1 - t)
        context.ball.courtPosition = CGPoint(
            x: context.ball.start.x + (context.ball.end.x - context.ball.start.x) * eased,
            y: context.ball.start.y + (context.ball.end.y - context.ball.start.y) * eased
        )
        context.ball.courtPosition.y += lift * 0.01

        if t >= 1 {
            resolveShot(context: context)
        }
    }

    private func resolveShot(context: MatchContext) {
        guard let shooterID = context.ball.shooter, let shooter = context.athletes[shooterID] else {
            context.ball.drop(at: context.ball.end)
            return
        }
        let hoop = context.geometry.hoopPosition(for: shooterID.side)
        let distance = hypot(hoop.x - context.ball.start.x, hoop.y - context.ball.start.y)
        let contested = context.roster(for: shooterID.side.opposing).contains {
            hypot($0.courtPosition.x - context.ball.start.x, $0.courtPosition.y - context.ball.start.y) < 36
        }
        let meter = context.state.shootMeter?.value ?? 0.4
        let chance = shotSuccessChance(
            meter: meter,
            distance: distance,
            contested: contested,
            config: context.config
        )
        context.state.shootMeter = nil

        if context.random01() <= chance {
            context.ball.attach(to: shooterID, at: hoop)
            context.emit(.goal(shooterID.side))
        } else {
            let scatter = CGPoint(
                x: hoop.x + (context.random01() - 0.5) * 40,
                y: hoop.y + (shooterID.side == .home ? -28 : 28)
            )
            context.ball.drop(at: context.geometry.clampToCourt(scatter, radius: 8))
            context.emit(.rebound)
            context.state.cueMessage = "REBOUND"
        }
        _ = shooter
    }
}
