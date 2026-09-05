import Foundation

/// Keeps ball ownership, hasBall flags, and ball node in lockstep.
struct PossessionSystem {
    func enforce(context: MatchContext) {
        if context.ball.isInFlight {
            for athlete in context.athletes.values {
                athlete.hasBall = false
            }
            context.state.ballOwner = nil
            context.state.possessionSide = nil
            return
        }

        if let ownerID = context.state.ballOwner, let owner = context.athletes[ownerID] {
            for athlete in context.athletes.values {
                athlete.hasBall = athlete.id == ownerID
            }
            owner.hasBall = true
            context.ball.owner = ownerID
            context.ball.flight = .none
            let face = owner.facingVector
            context.ball.courtPosition = CGPoint(
                x: owner.courtPosition.x + face.dx * 10,
                y: owner.courtPosition.y + face.dy * 8 + 8
            )
            context.state.possessionSide = ownerID.side
            return
        }

        for athlete in context.athletes.values {
            athlete.hasBall = false
        }
        context.state.ballOwner = nil
        context.state.possessionSide = nil
        if context.ball.flight != .loose {
            context.ball.drop(at: context.ball.courtPosition)
        }
    }

    func selectedCanPass(context: MatchContext) -> Bool {
        guard context.state.phase == .inPlay
                || context.state.phase == .centrePass
                || context.state.phase == .overtime else {
            return false
        }
        guard !context.ball.isInFlight else { return false }
        guard let selected = context.selectedHome() else { return false }
        return selected.hasBall && context.state.ballOwner == selected.id
    }

    func selectedCanShoot(context: MatchContext, shooting: ShootSystem) -> Bool {
        guard context.state.phase == .inPlay || context.state.phase == .overtime else { return false }
        guard let selected = context.selectedHome() else { return false }
        return selected.hasBall && context.state.ballOwner == selected.id && shooting.canShoot(selected, context: context)
    }
}
