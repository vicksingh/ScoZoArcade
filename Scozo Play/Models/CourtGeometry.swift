import CoreGraphics

/// Logical court space. Origin is the bottom-left of the playable rectangle.
/// Home attacks toward +Y. Visual isometric projection is display-only.
struct CourtGeometry: Equatable {
    var size: CGSize
    var shootingCircleRadius: CGFloat
    var hoopInset: CGFloat
    var circleInset: CGFloat

    static func make(config: GameConfig) -> CourtGeometry {
        CourtGeometry(
            size: CGSize(width: config.courtWidth, height: config.courtHeight),
            shootingCircleRadius: config.shootingCircleRadius,
            hoopInset: config.hoopInset,
            circleInset: config.circleInset
        )
    }

    var thirdHeight: CGFloat { size.height / 3 }
    var midX: CGFloat { size.width * 0.5 }
    var midY: CGFloat { size.height * 0.5 }

    var bounds: CGRect { CGRect(origin: .zero, size: size) }

    var centreMark: CGPoint { CGPoint(x: midX, y: midY) }

    var centreThird: CGRect {
        CGRect(x: 0, y: thirdHeight, width: size.width, height: thirdHeight)
    }

    func hoopPosition(for side: TeamSide) -> CGPoint {
        switch side {
        case .home: return CGPoint(x: midX, y: size.height - hoopInset)
        case .away: return CGPoint(x: midX, y: hoopInset)
        }
    }

    /// Shooting circle belonging to the attacking end of `side`.
    func shootingCircleCenter(for attackSide: TeamSide) -> CGPoint {
        switch attackSide {
        case .home: return CGPoint(x: midX, y: size.height - circleInset)
        case .away: return CGPoint(x: midX, y: circleInset)
        }
    }

    func containsShootingCircle(_ point: CGPoint, for attackSide: TeamSide) -> Bool {
        let center = shootingCircleCenter(for: attackSide)
        return hypot(point.x - center.x, point.y - center.y) <= shootingCircleRadius
    }

    func isInsideCourt(_ point: CGPoint) -> Bool {
        bounds.insetBy(dx: 6, dy: 6).contains(point)
    }

    func clampToCourt(_ point: CGPoint, radius: CGFloat) -> CGPoint {
        CGPoint(
            x: min(max(point.x, radius + 4), size.width - radius - 4),
            y: min(max(point.y, radius + 4), size.height - radius - 4)
        )
    }

    func nearestPoint(in rect: CGRect, to point: CGPoint) -> CGPoint {
        CGPoint(
            x: min(max(point.x, rect.minX), rect.maxX),
            y: min(max(point.y, rect.minY), rect.maxY)
        )
    }

    /// Perspective projector: strong ¾ trapezoid (near edge wide, far edge pinched).
    /// Visual-only — gameplay stays in axis-aligned court space.
    private var farWidthScale: CGFloat { 0.62 }

    func displayPoint(fromCourt point: CGPoint, in board: CGRect) -> CGPoint {
        let nx = point.x / max(size.width, 1)
        let ny = point.y / max(size.height, 1)
        let topWidth = board.width * farWidthScale
        let widthAtY = board.width + (topWidth - board.width) * ny
        let xOffset = (board.width - widthAtY) * 0.5
        return CGPoint(
            x: board.minX + xOffset + nx * widthAtY,
            y: board.minY + ny * board.height
        )
    }

    func courtPoint(fromDisplay point: CGPoint, in board: CGRect) -> CGPoint {
        let ny = (point.y - board.minY) / max(board.height, 1)
        let clampedNY = min(max(ny, 0), 1)
        let topWidth = board.width * farWidthScale
        let widthAtY = board.width + (topWidth - board.width) * clampedNY
        let xOffset = (board.width - widthAtY) * 0.5
        let nx = (point.x - board.minX - xOffset) / max(widthAtY, 1)
        return CGPoint(
            x: min(max(nx, 0), 1) * size.width,
            y: clampedNY * size.height
        )
    }

    func depthScale(forCourtY y: CGFloat, config: GameConfig) -> CGFloat {
        let t = min(max(y / max(size.height, 1), 0), 1)
        return config.depthScaleNear + (config.depthScaleFar - config.depthScaleNear) * t
    }
}

enum ZLayer {
    static let arena: CGFloat = 0
    static let surround: CGFloat = 1
    static let court: CGFloat = 2
    static let lines: CGFloat = 3
    static let shadows: CGFloat = 4
    static let players: CGFloat = 10
    static let effects: CGFloat = 50
    static let hud: CGFloat = 100
    static let controls: CGFloat = 120
    static let overlays: CGFloat = 200
    static let hints: CGFloat = 180
}
