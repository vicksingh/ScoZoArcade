import Testing
@testable import Scozo_Play

@MainActor
struct ScoZoArcadeTests {
    @Test func rosterIsFiveOnFive() {
        let context = MatchContext(config: .debug)
        #expect(context.roster(for: .home).count == 5)
        #expect(context.roster(for: .away).count == 5)
        #expect(Set(context.roster(for: .home).map(\.id.role)) == Set(PositionRole.allCases))
        #expect(!PositionRole.allCases.map(\.rawValue).contains("wa"))
    }

    @Test func formationSpreadsPlayersOffCentreLine() {
        let geometry = CourtGeometry.make(config: .debug)
        let homeXs = PositionRole.allCases.map { $0.defaultFormation(in: geometry, team: .home).x }
        let awayXs = PositionRole.allCases.map { $0.defaultFormation(in: geometry, team: .away).x }
        #expect(Set(homeXs.map { ($0 * 10).rounded() }).count == 5)
        #expect(homeXs.max()! - homeXs.min()! > geometry.size.width * 0.4)
        #expect(awayXs.max()! - awayXs.min()! > geometry.size.width * 0.4)
        #expect(Formation.isSeparated(in: geometry, playerRadius: GameConfig.debug.playerRadius))
        let homeGD = Formation.spawn(role: .gd, team: .home, in: geometry)
        #expect(homeGD.y < geometry.thirdHeight)
        let distToCentre = hypot(homeGD.x - geometry.centreMark.x, homeGD.y - geometry.centreMark.y)
        #expect(distToCentre > 80)
        let homeC = Formation.spawn(role: .c, team: .home, in: geometry)
        let awayC = Formation.spawn(role: .c, team: .away, in: geometry)
        #expect(homeC.x < geometry.midX)
        #expect(awayC.x > geometry.midX)
        #expect(hypot(homeC.x - geometry.centreMark.x, homeC.y - geometry.centreMark.y) > 38)
        let homeGS = Formation.spawn(role: .gs, team: .home, in: geometry)
        let awayGK = Formation.spawn(role: .gk, team: .away, in: geometry)
        #expect(hypot(homeGS.x - awayGK.x, homeGS.y - awayGK.y) >= Formation.minimumSeparation(playerRadius: 13))
        let board = CGRect(x: 0, y: 0, width: 300, height: 360)
        let screens = PositionRole.allCases.map {
            geometry.displayPoint(fromCourt: $0.defaultFormation(in: geometry, team: .home), in: board).x
        }
        #expect(screens.max()! - screens.min()! > 80)
    }

    @Test func centrePassGivesBallToAttackingCentre() {
        let context = MatchContext(config: .debug)
        MatchRules().ensureInitialSelection(context: context)
        PossessionSystem().enforce(context: context)
        #expect(context.state.phase == .centrePass)
        #expect(context.state.ballOwner == PlayerID(side: .home, role: .c))
        #expect(context.athletes[PlayerID(side: .home, role: .c)]?.hasBall == true)
        #expect(context.athletes.values.filter(\.hasBall).count == 1)
        #expect(context.selectedHome()?.id.role == .c)
        #expect(PossessionSystem().selectedCanPass(context: context))
        MatchRules().applySelection(PlayerID(side: .home, role: .gd), context: context)
        #expect(!PossessionSystem().selectedCanPass(context: context))
    }

    @Test func homeAttackersStartTowardTopHoop() {
        let geometry = CourtGeometry.make(config: .production)
        let gs = Formation.spawn(role: .gs, team: .home, in: geometry)
        let gk = Formation.spawn(role: .gk, team: .home, in: geometry)
        #expect(gs.y > geometry.size.height * 0.7)
        #expect(gk.y < geometry.thirdHeight)
        let awayGS = Formation.spawn(role: .gs, team: .away, in: geometry)
        let awayGK = Formation.spawn(role: .gk, team: .away, in: geometry)
        #expect(awayGS.y < geometry.thirdHeight)
        #expect(awayGK.y > geometry.size.height * 0.7)
    }

    @Test func zoneRectsHaveRealWidth() {
        let geometry = CourtGeometry.make(config: .production)
        for role in PositionRole.allCases {
            let zone = role.legalZone(in: geometry, team: .home)
            #expect(zone.width > geometry.size.width * 0.7)
        }
    }

    @Test func clubLabelsMatchBroadcastHUD() {
        let state = MatchState.fresh(config: .production)
        #expect(state.home.displayName == "STURT")
        #expect(state.away.displayName == "NORWOOD")
        #expect(TeamSide.home.opposing == .away)
    }

    @Test func onlyGoalAttackersCanShoot() {
        #expect(PositionRole.gs.canShoot)
        #expect(PositionRole.ga.canShoot)
        #expect(!PositionRole.c.canShoot)
        #expect(!PositionRole.gd.canShoot)
        #expect(!PositionRole.gk.canShoot)
    }

    @Test func centreCannotEnterShootingCircle() {
        let geometry = CourtGeometry.make(config: .production)
        #expect(!PositionRole.c.canEnterShootingCircle)
        let homeCircle = geometry.shootingCircleCenter(for: .home)
        let zone = PositionRole.c.legalZone(in: geometry, team: .home)
        #expect(zone.contains(geometry.centreMark))
        #expect(!geometry.containsShootingCircle(geometry.centreMark, for: .home))
        #expect(geometry.containsShootingCircle(homeCircle, for: .home))
    }

    @Test func awardGoalIsIdempotentOutsidePlay() {
        let context = MatchContext(config: .debug)
        context.state.phase = .inPlay
        let rules = MatchRules()
        #expect(rules.awardGoal(to: .home, context: context))
        #expect(context.state.homeScore == 1)
        #expect(context.state.phase == .goalScored)
        #expect(!rules.awardGoal(to: .home, context: context))
        #expect(context.state.homeScore == 1)
    }

    @Test func quartersPreserveScore() {
        var state = MatchState.fresh(config: .debug)
        state.phase = .inPlay
        #expect(state.awardGoal(to: .away))
        state.startQuarter(2, config: .debug, centre: .home)
        #expect(state.awayScore == 1)
        #expect(state.quarter == 2)
        #expect(state.phase == .centrePass)
    }

    @Test func resetMatchClearsScore() {
        var state = MatchState.fresh(config: .debug)
        state.homeScore = 4
        state.awayScore = 2
        state.resetForNewMatch(config: .debug)
        #expect(state.homeScore == 0)
        #expect(state.awayScore == 0)
        #expect(state.quarter == 1)
        #expect(state.phase == .centrePass)
    }

    @Test func tiedRegulationStartsOvertimeNotSilentWinner() {
        let context = MatchContext(config: .debug)
        context.state.phase = .inPlay
        context.state.quarter = 4
        context.state.homeScore = 3
        context.state.awayScore = 3
        context.state.quarterRemaining = 0
        MatchRules().tickPhase(context: context, dt: 0.016)
        #expect(context.state.winner == nil)
        #expect(context.state.overtimeActive)
        #expect(context.state.phase == .centrePass || context.state.phase == .overtime)
    }

    @Test func overtimeExpiryWithNoGoalIsDraw() {
        var state = MatchState.fresh(config: .debug)
        state.overtimeActive = true
        state.homeScore = 5
        state.awayScore = 5
        state.phase = .overtime
        state.quarterRemaining = 0
        let context = MatchContext(config: .debug)
        context.state = state
        MatchRules().tickPhase(context: context, dt: 0.016)
        #expect(context.state.phase == .matchOver)
        #expect(context.state.resultReason == .draw)
        #expect(context.state.winner == nil)
    }

    @Test func heldBallForcesTurnover() {
        let context = MatchContext(config: .debug)
        context.state.phase = .inPlay
        context.state.setPossession(owner: PlayerID(side: .home, role: .c))
        context.athletes[PlayerID(side: .home, role: .c)]?.hasBall = true
        context.state.heldBallElapsed = context.config.heldBallLimit
        FootworkSystem().forceTurnover(context: context)
        #expect(context.state.ballOwner?.side == .away || context.ball.flight == .loose)
        #expect(context.state.stats.homeTurnovers == 1)
        #expect(context.athletes.values.filter(\.hasBall).count <= 1)
    }

    @Test func shootChancePenalisesMissedSweetSpot() {
        let config = GameConfig.debug
        let good = ShootSystem().shotSuccessChance(meter: 0.74, distance: 40, contested: false, config: config)
        let late = ShootSystem().shotSuccessChance(meter: 0.99, distance: 40, contested: false, config: config)
        let contested = ShootSystem().shotSuccessChance(meter: 0.74, distance: 40, contested: true, config: config)
        #expect(good > late)
        #expect(good > contested)
    }

    @Test func mercyIsOffByDefault() {
        #expect(!GameConfig.production.mercyEnabled)
        #expect(GameConfig.production.quarterDuration == 150)
        #expect(GameConfig.production.quarterCount == 4)
    }

    // MARK: - Possession Invariant Tests

    @Test func possessionInvariantsSingleOwner() {
        let context = MatchContext(config: .debug)
        PossessionSystem().enforce(context: context)
        let hasBallCount = context.athletes.values.filter(\.hasBall).count
        #expect(hasBallCount <= 1, "At most one player can have the ball")
        if let owner = context.state.ballOwner {
            #expect(context.athletes[owner]?.hasBall == true, "Owner must have hasBall=true")
            #expect(context.state.possessionSide == owner.side, "possessionSide must match owner's side")
        }
    }

    @Test func possessionClearedWhenBallLoose() {
        let context = MatchContext(config: .debug)
        context.ball.drop(at: CGPoint(x: 100, y: 100))
        PossessionSystem().enforce(context: context)
        #expect(context.state.ballOwner == nil, "No owner when ball is loose")
        #expect(context.state.possessionSide == nil, "No possession side when ball is loose")
        #expect(context.athletes.values.allSatisfy { !$0.hasBall }, "No player has ball when loose")
    }

    @Test func possessionClearedWhenBallInFlight() {
        let context = MatchContext(config: .debug)
        let homeC = context.athletes[PlayerID(side: .home, role: .c)]!
        context.ball.launch(
            kind: .pass,
            from: homeC.courtPosition,
            to: CGPoint(x: 100, y: 200),
            duration: 0.5,
            lift: 20
        )
        PossessionSystem().enforce(context: context)
        #expect(context.state.ballOwner == nil, "No owner when ball in flight")
        #expect(context.athletes.values.allSatisfy { !$0.hasBall }, "No player has ball in flight")
    }

    @Test func carrierReturnsNilWhenBallLoose() {
        let context = MatchContext(config: .debug)
        context.state.setPossession(owner: PlayerID(side: .home, role: .c))
        context.athletes[PlayerID(side: .home, role: .c)]?.hasBall = true
        context.ball.drop(at: CGPoint(x: 100, y: 100))
        #expect(context.carrier() == nil, "carrier() should return nil when ball is loose")
    }

    @Test func carrierReturnsNilWhenHasBallFalse() {
        let context = MatchContext(config: .debug)
        context.state.setPossession(owner: PlayerID(side: .home, role: .c))
        context.athletes[PlayerID(side: .home, role: .c)]?.hasBall = false
        context.ball.flight = .none
        #expect(context.carrier() == nil, "carrier() should return nil when hasBall is false")
    }

    @Test func heldBallTimerOnlyTicksWithVerifiedCarrier() {
        let context = MatchContext(config: .debug)
        context.state.phase = .inPlay
        context.state.setPossession(owner: PlayerID(side: .home, role: .c))
        context.athletes[PlayerID(side: .home, role: .c)]?.hasBall = false
        context.ball.flight = .none
        let initialElapsed = context.state.heldBallElapsed
        FootworkSystem().update(context: context, dt: 0.5)
        #expect(context.state.heldBallElapsed == initialElapsed, "Timer should not tick without verified carrier")
    }

    @Test func goalResetSetsPossessionCorrectly() {
        let context = MatchContext(config: .debug)
        context.state.phase = .inPlay

        MatchRules().awardGoal(to: .away, context: context)
        #expect(context.state.phase == .goalScored)
        #expect(context.state.ballOwner == nil)

        context.state.phaseElapsed = context.config.goalResetDuration + 0.1
        MatchRules().tickPhase(context: context, dt: 0.016)

        #expect(context.state.phase == .centrePass)
        #expect(context.state.centrePassSide == .home, "After away scores, home gets centre pass")
        #expect(context.state.ballOwner == PlayerID(side: .home, role: .c))
        #expect(context.athletes[PlayerID(side: .home, role: .c)]?.hasBall == true)
        #expect(context.athletes.values.filter(\.hasBall).count == 1)
    }

    @Test func switchPrefersActualBallCarrier() {
        let context = MatchContext(config: .debug)
        PossessionSystem().enforce(context: context)
        MatchRules().applySelection(PlayerID(side: .home, role: .gk), context: context)
        #expect(context.selectedHome()?.id.role == .gk)

        MatchRules().selectHomePlayer(context: context)
        #expect(context.selectedHome()?.id.role == .c, "SWITCH should select ball carrier (home C)")
    }

    @Test func selectedCanPassOnlyWhenHoldingBall() {
        let context = MatchContext(config: .debug)
        context.state.phase = .inPlay
        let homeC = PlayerID(side: .home, role: .c)
        context.state.setPossession(owner: homeC)
        context.athletes[homeC]?.hasBall = true
        context.ball.flight = .none
        MatchRules().applySelection(homeC, context: context)

        #expect(PossessionSystem().selectedCanPass(context: context), "Can pass when holding ball")

        MatchRules().applySelection(PlayerID(side: .home, role: .gd), context: context)
        #expect(!PossessionSystem().selectedCanPass(context: context), "Cannot pass when not holding ball")
    }

    // MARK: - Loose Ball Handling Tests

    @Test func isBallLooseDetectsLooseState() {
        let context = MatchContext(config: .debug)
        #expect(!context.isBallLoose, "Initially ball is not loose")

        context.ball.drop(at: CGPoint(x: 100, y: 100))
        context.state.clearPossession()
        #expect(context.isBallLoose, "Ball should be loose after drop")
    }

    @Test func switchSelectsNearestToBallWhenLoose() {
        let context = MatchContext(config: .debug)
        context.state.phase = .inPlay

        let looseBallPos = CGPoint(x: 180, y: 200)
        context.ball.drop(at: looseBallPos)
        context.state.clearPossession()
        PossessionSystem().enforce(context: context)

        MatchRules().applySelection(PlayerID(side: .home, role: .gs), context: context)
        #expect(context.selectedHome()?.id.role == .gs)

        MatchRules().selectHomePlayer(context: context)
        let selected = context.selectedHome()
        #expect(selected != nil)
        #expect(selected?.id.role != .gs, "Should not stay on GS who is far from loose ball")
    }

    @Test func autoSwitchTriggersWhenBallBecomesLooseAndFar() {
        let context = MatchContext(config: .debug)
        context.state.phase = .inPlay

        let gsPos = context.athletes[PlayerID(side: .home, role: .gs)]!.courtPosition
        let looseBallPos = CGPoint(x: gsPos.x, y: gsPos.y - 300)
        context.ball.drop(at: looseBallPos)
        context.state.clearPossession()

        MatchRules().applySelection(PlayerID(side: .home, role: .gs), context: context)
        let distanceToBall = hypot(gsPos.x - looseBallPos.x, gsPos.y - looseBallPos.y)
        #expect(distanceToBall > context.config.looseBallAutoSwitchThreshold)

        MatchRules().handleLooseBallAutoSwitch(context: context)
        let selected = context.selectedHome()
        #expect(selected?.id.role != .gs, "Auto-switch should move away from far GS")
    }

    @Test func nearestHomeWhoCanReachConsidersZones() {
        let context = MatchContext(config: .debug)
        let midCourtPos = context.geometry.centreMark
        let nearest = context.nearestHomeWhoCanReach(point: midCourtPos)
        #expect(nearest != nil, "Should find a home player who can reach mid court")
        #expect(nearest?.id.role == .c || nearest?.id.role == .ga || nearest?.id.role == .gd,
                "Mid court should be reachable by C, GA, or GD")
    }

    @Test func pickupWhenPlayerTouchesLooseBall() {
        let context = MatchContext(config: .debug)
        context.state.phase = .inPlay

        let homeC = context.athletes[PlayerID(side: .home, role: .c)]!
        context.ball.drop(at: homeC.courtPosition)
        context.state.clearPossession()

        PassSystem().update(context: context, dt: 0.016)

        #expect(context.state.ballOwner == homeC.id, "Player touching loose ball should gain possession")
        #expect(homeC.hasBall, "Player should have ball after pickup")
        #expect(!context.isBallLoose, "Ball should no longer be loose after pickup")
    }
}
