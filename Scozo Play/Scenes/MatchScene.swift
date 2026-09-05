import Foundation
import SpriteKit
import UIKit

/// Owns the match loop. Systems run in this order each frame:
/// input → footwork → pass → shoot → AI → zones → rules → visuals → HUD.
final class MatchScene: SKScene {
    private let config: GameConfig
    private let context: MatchContext
    private let court: CourtNode
    private let homeHoop: HoopNode
    private let awayHoop: HoopNode
    private let ballNode: BallNode
    private var playerNodes: [PlayerID: PlayerNode] = [:]
    private let world = SKNode()
    private let fx = SKNode()
    private let hud: HUDNode
    private let controls: VirtualControlsNode
    private let hints = TouchHints()
    private let overlays: OverlayLayer
    private let footwork = FootworkSystem()
    private let zones = ZoneSystem()
    private let passing = PassSystem()
    private let shooting = ShootSystem()
    private let possession = PossessionSystem()
    private let ai = AISystem()
    private let rules = MatchRules()
    private var lastTime: TimeInterval = 0
    private var presentingResult = false
    private var lastFlashToken = 0
    private let trajectory = SKNode()
    private let meterArc = SKShapeNode()

    init(size: CGSize, config: GameConfig) {
        self.config = config
        self.context = MatchContext(config: config)
        self.court = CourtNode(geometry: context.geometry, config: config)
        self.homeHoop = HoopNode(side: .home, config: config)
        self.awayHoop = HoopNode(side: .away, config: config)
        self.ballNode = BallNode(config: config)
        self.hud = HUDNode(config: config)
        self.controls = VirtualControlsNode(config: config, input: context.input)
        self.overlays = OverlayLayer(config: config)
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = config.palette.arenaDeep
    }

    required init?(coder: NSCoder) { nil }

    override func didMove(to view: SKView) {
        isUserInteractionEnabled = true
        if world.parent == nil {
            addChild(world)
            world.addChild(court)
            world.addChild(homeHoop)
            world.addChild(awayHoop)
            world.addChild(fx)
            fx.addChild(trajectory)
            fx.addChild(meterArc)
            meterArc.strokeColor = config.palette.teal
            meterArc.fillColor = .clear
            meterArc.lineWidth = 3
            meterArc.zPosition = ZLayer.effects
            trajectory.zPosition = ZLayer.effects
            for athlete in context.athletes.values {
                let node = PlayerNode(athlete: athlete, config: config)
                playerNodes[athlete.id] = node
                world.addChild(node)
            }
            world.addChild(ballNode)
            addChild(hud)
            addChild(controls)
            addChild(hints)
            addChild(overlays)
        }
        rules.ensureInitialSelection(context: context)
        possession.enforce(context: context)
        layoutAll()
        controls.setPassLegal(possession.selectedCanPass(context: context))
        controls.setShootLegal(possession.selectedCanShoot(context: context, shooting: shooting))
        hints.showIfNeeded()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard view != nil else { return }
        layoutAll()
    }

    private func layoutAll() {
        let insets = view?.safeAreaInsets ?? .zero
        court.layout(in: size, safeTop: insets.top, safeBottom: insets.bottom)
        context.boardRect = court.boardRect
        let homePoint = context.geometry.hoopPosition(for: .home)
        let awayPoint = context.geometry.hoopPosition(for: .away)
        homeHoop.position = court.displayPoint(fromCourt: homePoint)
        awayHoop.position = court.displayPoint(fromCourt: awayPoint)
        homeHoop.setScale(context.geometry.depthScale(forCourtY: homePoint.y, config: config))
        awayHoop.setScale(context.geometry.depthScale(forCourtY: awayPoint.y, config: config) * 1.12)
        hud.layout(in: size, safeTop: insets.top, safeBottom: insets.bottom)
        controls.layout(in: size, safeBottom: insets.bottom)
        hints.layout(in: size, safeBottom: insets.bottom)
        overlays.layout(in: size)
        syncVisuals()
    }

    override func update(_ currentTime: TimeInterval) {
        let raw = lastTime == 0 ? 0 : currentTime - lastTime
        lastTime = currentTime
        let dt = max(0, min(raw, 1.0 / 20.0))
        processInput()
        switch context.state.phase {
        case .inPlay, .centrePass, .overtime:
            footwork.update(context: context, dt: dt)
            passing.update(context: context, dt: dt)
            shooting.update(context: context, dt: dt)
            ai.update(context: context, dt: dt)
            zones.update(context: context, dt: dt)
            possession.enforce(context: context)
        case .paused, .matchOver, .menu, .goalScored, .quarterBreak:
            break
        }
        if context.state.phase != .paused {
            rules.update(context: context, dt: dt)
        }
        syncVisuals()
        refreshShotPreview()
        var held: TimeInterval?
        if let carrier = context.carrier(), carrier.hasBall {
            held = max(0, config.heldBallLimit - context.state.heldBallElapsed)
        }
        hud.refresh(context.state, heldRemaining: held)
        controls.setPassLegal(possession.selectedCanPass(context: context))
        controls.setShootLegal(possession.selectedCanShoot(context: context, shooting: shooting))
        presentResultIfNeeded()
    }

    private func processInput() {
        if context.input.consumePause() {
            togglePause()
        }
        if context.input.consumeStats() {
            toggleStats()
        }
        if context.input.consumeSwitch(), context.state.phase != .paused, context.state.phase != .matchOver {
            rules.selectHomePlayer(context: context)
            context.selectedHome().map { playerNodes[$0.id]?.pulse() }
        }
        if let aim = context.input.consumeAimPoint() {
            context.lastHumanAim = CGVector(dx: aim.x, dy: aim.y)
            if let selected = context.selectedHome() {
                let dx = aim.x - selected.courtPosition.x
                let dy = aim.y - selected.courtPosition.y
                if hypot(dx, dy) > 4 {
                    selected.facing = atan2(dy, dx)
                    context.input.lastAimDirection = CGVector(dx: dx, dy: dy)
                }
            }
        }
    }

    private func togglePause() {
        if overlays.kind == .pause {
            overlays.hide()
            context.state.resume()
        } else if context.state.phase != .matchOver {
            overlays.hide()
            context.state.pause()
            overlays.showPause()
        }
    }

    private func toggleStats() {
        if overlays.kind == .stats {
            overlays.hide()
            if context.state.phase == .paused {
                context.state.resume()
            }
        } else {
            if context.state.phase != .paused && context.state.phase != .matchOver {
                context.state.pause()
            }
            overlays.showStats(context.state)
        }
    }

    private func syncVisuals() {
        for (id, node) in playerNodes {
            guard let athlete = context.athletes[id] else { continue }
            let display = court.displayPoint(fromCourt: athlete.courtPosition)
            let scale = context.geometry.depthScale(forCourtY: athlete.courtPosition.y, config: config)
            var remaining: TimeInterval?
            if athlete.hasBall {
                remaining = max(0, config.heldBallLimit - context.state.heldBallElapsed)
            }
            node.sync(from: athlete, display: display, scale: scale, heldRemaining: remaining)
        }
        if let owner = context.carrier() {
            let offset = CGPoint(
                x: owner.courtPosition.x + owner.facingVector.dx * 10,
                y: owner.courtPosition.y + owner.facingVector.dy * 8 + 8
            )
            context.ball.courtPosition = offset
        }
        let airborne = context.ball.isInFlight
        ballNode.sync(
            runtime: context.ball,
            display: court.displayPoint(fromCourt: context.ball.courtPosition),
            scale: context.geometry.depthScale(forCourtY: context.ball.courtPosition.y, config: config),
            airborne: airborne
        )
        handleCues()
    }

    private func handleCues() {
        let token = context.state.lastGoalToken
        guard token != lastFlashToken, context.state.cueMessage == "GOAL" else { return }
        lastFlashToken = token
        let side = context.state.lastScoringSide ?? .home
        (side == .home ? homeHoop : awayHoop).playScoreFlash()
    }

    private func refreshShotPreview() {
        trajectory.removeAllChildren()
        meterArc.path = nil
        meterArc.position = .zero
        meterArc.isHidden = true
        guard let meter = context.state.shootMeter,
              let shooter = context.carrier(),
              shooting.canShoot(shooter, context: context) else { return }

        let start = court.displayPoint(fromCourt: shooter.courtPosition)
        let hoop = court.displayPoint(fromCourt: context.geometry.hoopPosition(for: shooter.id.side))
        let mid = CGPoint(
            x: (start.x + hoop.x) * 0.5,
            y: max(start.y, hoop.y) + 56
        )
        let path = CGMutablePath()
        path.move(to: CGPoint(x: start.x, y: start.y + 18))
        path.addQuadCurve(to: hoop, control: mid)
        let glow = SKShapeNode(path: path)
        glow.strokeColor = config.palette.teal.withAlphaComponent(0.25)
        glow.lineWidth = 6
        glow.fillColor = .clear
        trajectory.addChild(glow)
        let line = SKShapeNode(path: path)
        line.strokeColor = config.palette.teal
        line.lineWidth = 2.4
        line.lineDash = [7, 6]
        line.fillColor = .clear
        trajectory.addChild(line)

        let end = SKShapeNode(circleOfRadius: 5)
        end.fillColor = config.palette.teal
        end.strokeColor = .white
        end.lineWidth = 0.8
        end.position = hoop
        trajectory.addChild(end)

        let inSweet = meter.value >= config.shotSweetMin && meter.value <= config.shotSweetMax
        meterArc.position = start
        meterArc.strokeColor = inSweet ? config.palette.success : (meter.value > config.shotSweetMax ? config.palette.magenta : config.palette.warning)
        meterArc.glowWidth = 5
        meterArc.lineWidth = 4.5
        meterArc.yScale = 0.45
        meterArc.xScale = 1
        let arc = CGMutablePath()
        let radius: CGFloat = 32
        arc.addArc(
            center: .zero,
            radius: radius,
            startAngle: .pi * 1.08,
            endAngle: .pi * 1.08 - .pi * 1.05 * meter.value,
            clockwise: true
        )
        meterArc.path = arc
        meterArc.isHidden = false
    }

    private func presentResultIfNeeded() {
        guard context.state.phase == .matchOver, !presentingResult else { return }
        presentingResult = true
        let snapshot = context.state
        run(.sequence([
            .wait(forDuration: 0.9),
            .run { [weak self] in
                guard let self else { return }
                let result = ResultScene(size: self.size, config: self.config, match: snapshot)
                self.view?.presentScene(result, transition: .fade(withDuration: 0.4))
            }
        ]))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        if !overlays.isHidden {
            if overlays.kind == .pause { togglePause() } else { toggleStats() }
            return
        }
        if hud.hitPause(point) {
            context.input.requestPause()
            return
        }
        if hud.hitStats(point) {
            context.input.requestStats()
            return
        }
        if controls.containsControl(point) { return }
        context.input.aimPoint = court.courtPoint(fromDisplay: point)
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            guard let key = press.key else { continue }
            switch key.keyCode {
            case .keyboardUpArrow, .keyboardW: context.input.setMove(CGVector(dx: 0, dy: 1), deadZone: 0)
            case .keyboardDownArrow, .keyboardS: context.input.setMove(CGVector(dx: 0, dy: -1), deadZone: 0)
            case .keyboardLeftArrow, .keyboardA: context.input.setMove(CGVector(dx: -1, dy: 0), deadZone: 0)
            case .keyboardRightArrow, .keyboardD: context.input.setMove(CGVector(dx: 1, dy: 0), deadZone: 0)
            case .keyboardP, .keyboardSpacebar: context.input.requestPass()
            case .keyboardF: context.input.pressShoot()
            case .keyboardTab: context.input.requestSwitch()
            case .keyboardEscape: context.input.requestPause()
            default: break
            }
        }
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            guard let key = press.key else { continue }
            switch key.keyCode {
            case .keyboardUpArrow, .keyboardDownArrow, .keyboardLeftArrow, .keyboardRightArrow,
                    .keyboardW, .keyboardA, .keyboardS, .keyboardD:
                context.input.clearMove()
            case .keyboardF:
                context.input.releaseShoot()
            default:
                break
            }
        }
    }
}

private extension SKShapeNode {
    var lineDash: [CGFloat] {
        get { [] }
        set {
            if let path {
                let dashed = path.copy(dashingWithPhase: 0, lengths: newValue)
                self.path = dashed
            }
        }
    }
}
