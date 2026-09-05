import Foundation

/// Quarter-based match flow. Scoring and phase changes are idempotent.
///
/// Overtime / tie policy: if Q4 ends level, a single sudden-death overtime
/// period of `config.overtimeDuration` starts. First goal wins. If overtime
/// expires with no goal, the match is a draw. A winner is never invented.
struct MatchRules {
    func update(context: MatchContext, dt: TimeInterval) {
        let clamped = max(0, min(dt, 1.0 / 20.0))
        processEvents(context: context)
        tickPhase(context: context, dt: clamped)
    }

    func processEvents(context: MatchContext) {
        let events = context.events
        context.events.removeAll(keepingCapacity: true)
        for event in events {
            switch event.kind {
            case .goal(let side):
                awardGoal(to: side, context: context)
            case .turnover, .hint, .rebound, .intercept, .illegalShoot:
                break
            }
        }
    }

    @discardableResult
    func awardGoal(to side: TeamSide, context: MatchContext) -> Bool {
        guard context.state.awardGoal(to: side) else { return false }
        if context.state.overtimeActive {
            context.state.finishMatch(reason: .overtime)
            return true
        }
        if shouldApplyMercy(context: context) {
            context.state.finishMatch(reason: .mercy)
        }
        return true
    }

    func tickPhase(context: MatchContext, dt: TimeInterval) {
        var state = context.state
        switch state.phase {
        case .paused, .matchOver, .menu:
            context.state = state
            return
        case .centrePass:
            state.phaseElapsed += dt
            if state.phaseElapsed >= context.config.centrePassPause {
                state.enterInPlay()
            }
        case .inPlay, .overtime:
            state.quarterRemaining = max(0, state.quarterRemaining - dt)
            if state.quarterRemaining <= 0 {
                handleClockExpiry(state: &state, context: context)
            }
        case .goalScored:
            state.phaseElapsed += dt
            if state.phaseElapsed >= context.config.goalResetDuration, state.phase != .matchOver {
                finishGoalReset(state: &state, context: context)
            }
        case .quarterBreak:
            state.phaseElapsed += dt
            if state.phaseElapsed >= context.config.quarterBreakDuration {
                startNextQuarter(state: &state, context: context)
            }
        }
        context.state = state
    }

    private func handleClockExpiry(state: inout MatchState, context: MatchContext) {
        if state.overtimeActive {
            state.finishMatch(reason: state.winningSide == nil ? .draw : .overtime)
            return
        }
        if state.quarter >= state.quarterCount {
            if state.winningSide == nil {
                // Sudden-death mini-period. Documented above.
                state.overtimeActive = true
                state.quarter = state.quarterCount
                context.resetRosterToFormation()
                state.startQuarter(state.quarterCount, config: context.config, centre: state.centrePassSide)
                state.overtimeActive = true
                state.phase = .centrePass
                state.cueMessage = "OVERTIME"
            } else {
                state.finishMatch(reason: .regulation)
            }
        } else {
            state.endQuarter()
        }
    }

    private func finishGoalReset(state: inout MatchState, context: MatchContext) {
        let nextCentre = state.lastScoringSide?.opposing ?? state.centrePassSide.opposing
        context.resetRosterToFormation()
        state.beginCentrePass(for: nextCentre)
        applyCentreOwner(&state, context: context)
        context.state = state
        ensureInitialSelection(context: context)
    }

    private func startNextQuarter(state: inout MatchState, context: MatchContext) {
        let next = state.quarter + 1
        context.resetRosterToFormation()
        state.startQuarter(next, config: context.config, centre: state.centrePassSide.opposing)
        applyCentreOwner(&state, context: context)
        context.state = state
        ensureInitialSelection(context: context)
    }

    private func applyCentreOwner(_ state: inout MatchState, context: MatchContext) {
        let owner = PlayerID(side: state.centrePassSide, role: .c)
        for athlete in context.athletes.values {
            athlete.hasBall = athlete.id == owner
        }
        if let centre = context.athletes[owner] {
            context.ball.attach(to: owner, at: centre.courtPosition)
        }
        state.ballOwner = owner
        state.possessionSide = owner.side
    }

    private func shouldApplyMercy(context: MatchContext) -> Bool {
        let config = context.config
        guard config.mercyEnabled, context.state.quarter >= config.mercyFromQuarter else { return false }
        return abs(context.state.homeScore - context.state.awayScore) >= config.mercyLead
    }

    func selectHomePlayer(context: MatchContext) {
        let home = context.roster(for: .home)
        guard !home.isEmpty else { return }
        let current = context.selectedHome()
        let ballPoint = context.ball.courtPosition

        if let carrier = context.carrier(), carrier.id.side == .home, current?.id != carrier.id {
            applySelection(carrier.id, context: context)
            return
        }

        if let current {
            let ordered = home
            if let idx = ordered.firstIndex(where: { $0.id == current.id }) {
                let next = ordered[(idx + 1) % ordered.count]
                applySelection(next.id, context: context)
                return
            }
        }

        if let nearest = context.nearest(to: ballPoint, side: .home) {
            applySelection(nearest.id, context: context)
        }
    }

    func applySelection(_ id: PlayerID, context: MatchContext) {
        for athlete in context.athletes.values {
            let selected = athlete.id == id
            athlete.isSelected = selected
            athlete.isHumanControlled = selected && id.side == .home
        }
    }

    func ensureInitialSelection(context: MatchContext) {
        if context.state.phase == .centrePass {
            let taking = PlayerID(side: context.state.centrePassSide, role: .c)
            if taking.side == .home {
                applySelection(taking, context: context)
                return
            }
            let spot = context.athletes[taking]?.courtPosition ?? context.geometry.centreMark
            if let nearest = context.nearest(to: spot, side: .home) {
                applySelection(nearest.id, context: context)
            }
            return
        }
        if let owner = context.state.ballOwner, owner.side == .home {
            applySelection(owner, context: context)
        } else if let c = context.athletes[PlayerID(side: .home, role: .c)] {
            applySelection(c.id, context: context)
        }
    }
}
