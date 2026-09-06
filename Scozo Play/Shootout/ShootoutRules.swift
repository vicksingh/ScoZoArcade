import Foundation

struct ShootoutRules {
    private let goalResetDuration: TimeInterval = 1.2
    private let turnoverResetDuration: TimeInterval = 1.0
    
    func update(context: ShootoutContext, dt: TimeInterval) {
        let clamped = max(0, min(dt, 1.0 / 20.0))
        processEvents(context: context)
        tickPhase(context: context, dt: clamped)
    }
    
    func processEvents(context: ShootoutContext) {
        let events = context.events
        context.events.removeAll(keepingCapacity: true)
        for event in events {
            switch event.kind {
            case .goal(let side):
                if side == .home {
                    _ = context.state.awardGoal()
                }
            case .turnover(let side):
                if side == .home {
                    context.state.awardStop(reason: "HELD BALL")
                    context.state.stats.heldBalls += 1
                }
            case .intercept:
                context.state.awardStop(reason: "INTERCEPTED!")
                context.state.stats.intercepts += 1
            case .rebound:
                context.state.awardStop(reason: "MISS!")
            case .hint, .illegalShoot:
                break
            }
        }
    }
    
    func tickPhase(context: ShootoutContext, dt: TimeInterval) {
        var state = context.state
        
        switch state.phase {
        case .paused, .roundOver:
            context.state = state
            return
            
        case .ready:
            state.phaseElapsed += dt
            if state.phaseElapsed >= 0.8 {
                state.beginPlay()
            }
            
        case .inPlay:
            state.clockRemaining = max(0, state.clockRemaining - dt)
            if state.clockRemaining <= 0 {
                let homeWins = state.homeScore > 0
                state.finishRound(winner: homeWins ? .home : .away)
            }
            
        case .goalScored:
            state.phaseElapsed += dt
            if state.phaseElapsed >= goalResetDuration, state.phase != .roundOver {
                context.resetRoster()
                state.beginPlay()
            }
            
        case .turnover:
            state.phaseElapsed += dt
            if state.phaseElapsed >= turnoverResetDuration, state.phase != .roundOver {
                context.resetRoster()
                state.beginPlay()
            }
        }
        
        context.state = state
    }
    
    func selectHomePlayer(context: ShootoutContext) {
        let home = context.roster(for: .home)
        guard !home.isEmpty else { return }
        let current = context.selectedHome()
        
        if let carrier = context.carrier(), carrier.id.side == .home, current?.id != carrier.id {
            applySelection(carrier.id, context: context)
            return
        }
        
        if let current, let idx = home.firstIndex(where: { $0.id == current.id }) {
            let next = home[(idx + 1) % home.count]
            applySelection(next.id, context: context)
            return
        }
        
        if let first = home.first {
            applySelection(first.id, context: context)
        }
    }
    
    func applySelection(_ id: PlayerID, context: ShootoutContext) {
        for athlete in context.athletes.values {
            let selected = athlete.id == id
            athlete.isSelected = selected
            athlete.isHumanControlled = selected && id.side == .home
        }
    }
    
    func ensureInitialSelection(context: ShootoutContext) {
        if let owner = context.state.ballOwner, owner.side == .home {
            applySelection(owner, context: context)
        } else if let gs = context.athletes[PlayerID(side: .home, role: .gs)] {
            applySelection(gs.id, context: context)
        }
    }
}
