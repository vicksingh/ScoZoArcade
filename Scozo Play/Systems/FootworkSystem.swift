import CoreGraphics
import Foundation

struct FootworkSystem {
    func update(context: MatchContext, dt: TimeInterval) {
        let clamped = max(0, min(dt, 1.0 / 20.0))
        let config = context.config
        guard context.state.phase != .paused, context.state.phase != .matchOver else { return }

        for athlete in context.athletes.values {
            let human = athlete.isHumanControlled && athlete.isSelected
            let intent: CGVector
            if human {
                intent = context.input.moveVector
            } else if let target = athlete.targetPoint {
                let dx = target.x - athlete.courtPosition.x
                let dy = target.y - athlete.courtPosition.y
                let len = hypot(dx, dy)
                intent = len < 6 ? .zero : CGVector(dx: dx / len, dy: dy / len)
            } else {
                intent = .zero
            }

            applyMovement(athlete: athlete, intent: intent, dt: clamped, config: config, human: human)
        }

        updateHeldBall(context: context, dt: clamped)
    }

    private func applyMovement(athlete: Athlete, intent: CGVector, dt: TimeInterval, config: GameConfig, human: Bool) {
        let hasBall = athlete.hasBall
        let length = hypot(intent.dx, intent.dy)

        if hasBall {
            if length > config.inputDeadZone {
                athlete.facing = atan2(intent.dy, intent.dx)
                let shuffle = min(config.pivotShuffleSpeed * CGFloat(dt), config.pivotShuffleMax)
                athlete.courtPosition.x += intent.dx * shuffle
                athlete.courtPosition.y += intent.dy * shuffle
            }
            athlete.velocity = .zero
            return
        }

        let speed = config.moveSpeed * (human ? config.controlledBoost : 1)
        if length > 0.001 {
            athlete.facing = atan2(intent.dy, intent.dx)
            athlete.velocity.dx += intent.dx * config.acceleration * CGFloat(dt)
            athlete.velocity.dy += intent.dy * config.acceleration * CGFloat(dt)
        }

        let damp = exp(-config.damping * CGFloat(dt))
        athlete.velocity.dx *= damp
        athlete.velocity.dy *= damp

        let vLen = hypot(athlete.velocity.dx, athlete.velocity.dy)
        if vLen > speed {
            athlete.velocity.dx = athlete.velocity.dx / vLen * speed
            athlete.velocity.dy = athlete.velocity.dy / vLen * speed
        }

        athlete.courtPosition.x += athlete.velocity.dx * CGFloat(dt)
        athlete.courtPosition.y += athlete.velocity.dy * CGFloat(dt)
    }

    private func updateHeldBall(context: MatchContext, dt: TimeInterval) {
        guard context.state.phase == .inPlay || context.state.phase == .overtime else { return }
        guard context.state.ballOwner != nil, !context.ball.isInFlight else { return }

        context.state.heldBallElapsed += dt
        if context.state.heldBallElapsed + 0.0001 >= context.config.heldBallLimit {
            forceTurnover(context: context)
        }
    }

    func forceTurnover(context: MatchContext) {
        guard let ownerID = context.state.ballOwner, let owner = context.athletes[ownerID] else { return }
        owner.hasBall = false
        let drop = owner.courtPosition
        if let opponent = context.nearest(to: drop, side: ownerID.side.opposing) {
            opponent.hasBall = true
            context.ball.attach(to: opponent.id, at: opponent.courtPosition)
            context.state.setPossession(owner: opponent.id)
        } else {
            context.ball.drop(at: drop)
            context.state.clearPossession()
        }
        if ownerID.side == .home {
            context.state.stats.homeTurnovers += 1
        } else {
            context.state.stats.awayTurnovers += 1
        }
        context.emit(.turnover(ownerID.side))
        context.state.cueMessage = "HELD BALL"
    }
}
