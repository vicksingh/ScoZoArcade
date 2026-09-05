import Foundation
import SpriteKit
import UIKit

final class ShootoutScene: SKScene {
    private let config: GameConfig
    private let context: ShootoutContext
    private let court: ShootoutCourtNode
    private let hoop: HoopNode
    private let ballNode: BallNode
    private var playerNodes: [PlayerID: PlayerNode] = [:]
    private let world = SKNode()
    private let fx = SKNode()
    private let hud: ShootoutHUD
    private let controls: VirtualControlsNode
    private let hints = TouchHints()
    private let overlays: OverlayLayer
    private let footwork = FootworkSystem()
    private let passing: ShootoutPassSystem
    private let shooting = ShootSystem()
    private let possession = PossessionSystem()
    private let ai = ShootoutAI()
    private let rules = ShootoutRules()
    private var lastTime: TimeInterval = 0
    private var presentingResult = false
    private var lastFlashToken = 0
    private let trajectory = SKNode()
    private let meterArc = SKShapeNode()
    private let passLane = SKShapeNode()
    
    init(size: CGSize, config: GameConfig) {
        self.config = config
        self.context = ShootoutContext(config: config)
        self.court = ShootoutCourtNode(geometry: context.geometry, config: config)
        self.hoop = HoopNode(side: .home, config: config)
        self.ballNode = BallNode(config: config)
        self.hud = ShootoutHUD(config: config)
        self.controls = VirtualControlsNode(config: config, input: context.input)
        self.overlays = OverlayLayer(config: config)
        self.passing = ShootoutPassSystem()
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
            world.addChild(hoop)
            world.addChild(fx)
            fx.addChild(trajectory)
            fx.addChild(meterArc)
            fx.addChild(passLane)
            meterArc.strokeColor = config.palette.teal
            meterArc.fillColor = .clear
            meterArc.lineWidth = 3
            meterArc.zPosition = ZLayer.effects
            trajectory.zPosition = ZLayer.effects
            passLane.zPosition = ZLayer.effects - 1
            passLane.strokeColor = config.palette.teal.withAlphaComponent(0.4)
            passLane.fillColor = .clear
            passLane.lineWidth = 2
            passLane.lineCap = .round
            
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
        possession.enforceShootout(context: context)
        layoutAll()
        controls.setPassLegal(canPass())
        controls.setShootLegal(canShoot())
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
        let hoopPoint = context.geometry.hoopPosition(for: .home)
        hoop.position = court.displayPoint(fromCourt: hoopPoint)
        hoop.setScale(context.geometry.depthScale(forCourtY: hoopPoint.y, config: config))
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
        case .inPlay, .ready:
            footworkShootout(dt: dt)
            passing.update(context: context, dt: dt)
            shootingUpdate(dt: dt)
            ai.update(context: context, dt: dt)
            zoneClamp(dt: dt)
            possession.enforceShootout(context: context)
        case .paused, .roundOver, .goalScored, .turnover:
            break
        }
        
        if context.state.phase != .paused {
            rules.update(context: context, dt: dt)
        }
        
        syncVisuals()
        refreshShotPreview()
        refreshPassLane()
        
        var held: TimeInterval?
        if let carrier = context.carrier(), carrier.hasBall {
            held = max(0, config.heldBallLimit - context.state.heldBallElapsed)
        }
        hud.refresh(context.state, heldRemaining: held)
        controls.setPassLegal(canPass())
        controls.setShootLegal(canShoot())
        presentResultIfNeeded()
    }
    
    private func processInput() {
        if context.input.consumePause() {
            togglePause()
        }
        if context.input.consumeSwitch(), context.state.phase != .paused, context.state.phase != .roundOver {
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
            updatePassTarget(aim: aim)
        }
    }
    
    private func updatePassTarget(aim: CGPoint) {
        guard let selected = context.selectedHome(), selected.hasBall else { return }
        if let other = context.otherAttacker(from: selected.id) {
            let dist = hypot(other.courtPosition.x - aim.x, other.courtPosition.y - aim.y)
            if dist < 40 {
                context.passTargetID = other.id
            }
        }
    }
    
    private func togglePause() {
        if overlays.kind == .pause {
            overlays.hide()
            context.state.resume()
        } else if context.state.phase != .roundOver {
            overlays.hide()
            context.state.pause()
            overlays.showPause()
        }
    }
    
    private func footworkShootout(dt: TimeInterval) {
        let clamped = max(0, min(dt, 1.0 / 20.0))
        
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
            
            applyMovement(athlete: athlete, intent: intent, dt: clamped, human: human)
        }
        
        updateHeldBall(dt: clamped)
    }
    
    private func applyMovement(athlete: Athlete, intent: CGVector, dt: TimeInterval, human: Bool) {
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
    
    private func updateHeldBall(dt: TimeInterval) {
        guard context.state.phase == .inPlay else { return }
        guard context.state.ballOwner != nil, !context.ball.isInFlight else { return }
        
        context.state.heldBallElapsed += dt
        if context.state.heldBallElapsed + 0.0001 >= config.heldBallLimit {
            forceTurnover()
        }
    }
    
    private func forceTurnover() {
        guard let ownerID = context.state.ballOwner, let owner = context.athletes[ownerID] else { return }
        guard ownerID.side == .home else { return }
        owner.hasBall = false
        context.ball.drop(at: owner.courtPosition)
        context.state.clearPossession()
        context.emit(.turnover(.home))
    }
    
    private func shootingUpdate(dt: TimeInterval) {
        if context.input.consumeShootPressed() {
            beginCharge()
        }
        if context.input.shootHeld {
            tickMeter(dt: dt)
        }
        if context.input.consumeShootReleased() {
            releaseShot()
        }
        advanceShot(dt: dt)
    }
    
    private func beginCharge() {
        guard context.state.phase == .inPlay else { return }
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
        guard context.geometry.containsShootingCircle(shooter.courtPosition, for: .home) else {
            context.emit(.hint("ENTER THE CIRCLE"))
            context.emit(.illegalShoot)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            return
        }
        context.state.shootMeter = ShootMeterState(value: 0.08, charging: true, direction: 1)
    }
    
    private func tickMeter(dt: TimeInterval) {
        guard var meter = context.state.shootMeter, meter.charging else { return }
        meter.value += meter.direction * config.shotChargeSpeed * CGFloat(dt)
        if meter.value >= 1 {
            meter.value = 1
            meter.direction = -1
        } else if meter.value <= 0 {
            meter.value = 0
            meter.direction = 1
        }
        context.state.shootMeter = meter
    }
    
    private func releaseShot() {
        guard var meter = context.state.shootMeter, meter.charging else { return }
        meter.charging = false
        context.state.shootMeter = meter
        guard let shooter = context.carrier(),
              shooter.id.role.canShoot,
              context.geometry.containsShootingCircle(shooter.courtPosition, for: .home) else {
            context.state.shootMeter = nil
            return
        }
        
        let hoop = context.geometry.hoopPosition(for: .home)
        shooter.hasBall = false
        context.state.clearPossession()
        context.state.stats.homeShots += 1
        context.ball.launch(
            kind: .shot,
            from: shooter.courtPosition,
            to: hoop,
            duration: config.shotFlightTime,
            lift: 48,
            shooter: shooter.id
        )
    }
    
    private func advanceShot(dt: TimeInterval) {
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
            resolveShot()
        }
    }
    
    private func resolveShot() {
        guard let shooterID = context.ball.shooter, let shooter = context.athletes[shooterID] else {
            context.ball.drop(at: context.ball.end)
            return
        }
        let hoop = context.geometry.hoopPosition(for: .home)
        let distance = hypot(hoop.x - context.ball.start.x, hoop.y - context.ball.start.y)
        let contested = context.roster(for: .away).contains {
            hypot($0.courtPosition.x - context.ball.start.x, $0.courtPosition.y - context.ball.start.y) < 36
        }
        let meter = context.state.shootMeter?.value ?? 0.4
        let chance = shooting.shotSuccessChance(
            meter: meter,
            distance: distance,
            contested: contested,
            config: config
        )
        context.state.shootMeter = nil
        
        if context.random01() <= chance {
            context.ball.attach(to: shooterID, at: hoop)
            context.emit(.goal(.home))
            hoop.playScoreFlash()
        } else {
            let scatter = CGPoint(
                x: hoop.x + (context.random01() - 0.5) * 40,
                y: hoop.y - 28
            )
            context.ball.drop(at: context.geometry.clampToCourt(scatter, radius: 8))
            context.emit(.rebound)
        }
        _ = shooter
    }
    
    private func zoneClamp(dt: TimeInterval) {
        let pull = 220 * CGFloat(max(0, min(dt, 0.05)))
        
        for athlete in context.athletes.values {
            var point = context.geometry.clampToCourt(athlete.courtPosition, radius: config.playerRadius)
            let zone = context.shootoutZone(for: athlete.id.role, team: athlete.id.side)
            if !zone.contains(point) {
                let nearest = context.geometry.nearestPoint(in: zone, to: point)
                let dx = nearest.x - point.x
                let dy = nearest.y - point.y
                let dist = hypot(dx, dy)
                if dist > 0.01 {
                    let step = min(dist, pull)
                    point.x += dx / dist * step
                    point.y += dy / dist * step
                }
            }
            athlete.courtPosition = context.geometry.clampToCourt(point, radius: config.playerRadius)
        }
        separateOverlaps(dt: dt)
    }
    
    private func separateOverlaps(dt: TimeInterval) {
        let minDist = Formation.minimumSeparation(playerRadius: config.playerRadius) * 0.85
        let push = 160 * CGFloat(max(0, min(dt, 0.05)))
        let athletes = Array(context.athletes.values)
        guard athletes.count > 1 else { return }
        for i in 0..<athletes.count {
            for j in (i + 1)..<athletes.count {
                let a = athletes[i]
                let b = athletes[j]
                let dx = b.courtPosition.x - a.courtPosition.x
                let dy = b.courtPosition.y - a.courtPosition.y
                let dist = hypot(dx, dy)
                if dist >= minDist { continue }
                let nx: CGFloat
                let ny: CGFloat
                if dist < 0.5 {
                    nx = 1
                    ny = 0
                } else {
                    nx = dx / dist
                    ny = dy / dist
                }
                let need = (minDist - max(dist, 0.5)) * 0.5
                let step = min(need, max(push, 4))
                a.courtPosition.x -= nx * step
                a.courtPosition.y -= ny * step
                b.courtPosition.x += nx * step
                b.courtPosition.y += ny * step
                a.courtPosition = context.geometry.clampToCourt(a.courtPosition, radius: config.playerRadius)
                b.courtPosition = context.geometry.clampToCourt(b.courtPosition, radius: config.playerRadius)
            }
        }
    }
    
    private func canPass() -> Bool {
        guard context.state.phase == .inPlay else { return false }
        guard !context.ball.isInFlight else { return false }
        guard let selected = context.selectedHome() else { return false }
        return selected.hasBall && context.state.ballOwner == selected.id
    }
    
    private func canShoot() -> Bool {
        guard context.state.phase == .inPlay else { return false }
        guard let selected = context.selectedHome() else { return false }
        guard selected.hasBall && context.state.ballOwner == selected.id else { return false }
        guard selected.id.role.canShoot else { return false }
        return context.geometry.containsShootingCircle(selected.courtPosition, for: .home)
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
        guard token != lastFlashToken, context.state.cueMessage == "GOAL!" else { return }
        lastFlashToken = token
        hoop.playScoreFlash()
    }
    
    private func refreshShotPreview() {
        trajectory.removeAllChildren()
        meterArc.path = nil
        meterArc.position = .zero
        meterArc.isHidden = true
        guard let meter = context.state.shootMeter,
              let shooter = context.carrier(),
              shooter.id.role.canShoot,
              context.geometry.containsShootingCircle(shooter.courtPosition, for: .home) else { return }
        
        let start = court.displayPoint(fromCourt: shooter.courtPosition)
        let hoopPos = court.displayPoint(fromCourt: context.geometry.hoopPosition(for: .home))
        let mid = CGPoint(
            x: (start.x + hoopPos.x) * 0.5,
            y: max(start.y, hoopPos.y) + 56
        )
        let path = CGMutablePath()
        path.move(to: CGPoint(x: start.x, y: start.y + 18))
        path.addQuadCurve(to: hoopPos, control: mid)
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
        end.position = hoopPos
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
    
    private func refreshPassLane() {
        passLane.path = nil
        guard let selected = context.selectedHome(),
              selected.hasBall,
              let target = context.passTargetID,
              let receiver = context.athletes[target] else { return }
        
        let start = court.displayPoint(fromCourt: selected.courtPosition)
        let end = court.displayPoint(fromCourt: receiver.courtPosition)
        let path = CGMutablePath()
        path.move(to: start)
        path.addLine(to: end)
        passLane.path = path.copy(dashingWithPhase: 0, lengths: [6, 4])
    }
    
    private func presentResultIfNeeded() {
        guard context.state.phase == .roundOver, !presentingResult else { return }
        presentingResult = true
        let snapshot = context.state
        run(.sequence([
            .wait(forDuration: 1.2),
            .run { [weak self] in
                guard let self else { return }
                let result = ShootoutResultScene(size: self.size, config: self.config, state: snapshot)
                self.view?.presentScene(result, transition: .fade(withDuration: 0.4))
            }
        ]))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        if !overlays.isHidden {
            togglePause()
            return
        }
        if hud.hitPause(point) {
            context.input.requestPause()
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
