import CoreGraphics

/// Control contract for the mock layout. UI writes intents; systems consume them.
final class InputSystem {
    var moveVector: CGVector = .zero
    var passRequested = false
    var shootPressed = false
    var shootHeld = false
    var shootReleased = false
    var switchRequested = false
    var aimPoint: CGPoint?
    var pauseRequested = false
    var statsRequested = false
    var lastAimDirection: CGVector = CGVector(dx: 0, dy: 1)

    func setMove(_ vector: CGVector, deadZone: CGFloat) {
        let length = hypot(vector.dx, vector.dy)
        if length < deadZone {
            moveVector = .zero
            return
        }
        let scaled = min(1, length)
        let nx = vector.dx / length * scaled
        let ny = vector.dy / length * scaled
        moveVector = CGVector(dx: nx, dy: ny)
        lastAimDirection = moveVector
    }

    func clearMove() {
        moveVector = .zero
    }

    func requestPass() {
        passRequested = true
    }

    func pressShoot() {
        shootPressed = true
        shootHeld = true
        shootReleased = false
    }

    func releaseShoot() {
        shootHeld = false
        shootReleased = true
    }

    func requestSwitch() {
        switchRequested = true
    }

    func requestPause() {
        pauseRequested = true
    }

    func requestStats() {
        statsRequested = true
    }

    func consumePass() -> Bool {
        defer { passRequested = false }
        return passRequested
    }

    func consumeSwitch() -> Bool {
        defer { switchRequested = false }
        return switchRequested
    }

    func consumeShootPressed() -> Bool {
        defer { shootPressed = false }
        return shootPressed
    }

    func consumeShootReleased() -> Bool {
        defer { shootReleased = false }
        return shootReleased
    }

    func consumePause() -> Bool {
        defer { pauseRequested = false }
        return pauseRequested
    }

    func consumeStats() -> Bool {
        defer { statsRequested = false }
        return statsRequested
    }

    func consumeAimPoint() -> CGPoint? {
        defer { aimPoint = nil }
        return aimPoint
    }
}
