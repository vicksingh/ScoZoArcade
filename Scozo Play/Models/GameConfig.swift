import Foundation
import SpriteKit

struct GamePalette {
    let teal: SKColor
    let tealDark: SKColor
    let magenta: SKColor
    let magentaDark: SKColor
    let wood: SKColor
    let woodDark: SKColor
    let woodLight: SKColor
    let cream: SKColor
    let arena: SKColor
    let arenaDeep: SKColor
    let warning: SKColor
    let success: SKColor
    let panel: SKColor
    let panelStroke: SKColor

    static let standard = GamePalette(
        teal: SKColor(hex: 0x00C2C7),
        tealDark: SKColor(hex: 0x067A82),
        magenta: SKColor(hex: 0xE21B70),
        magentaDark: SKColor(hex: 0x9A124C),
        wood: SKColor(hex: 0xC9A06A),
        woodDark: SKColor(hex: 0x8C6840),
        woodLight: SKColor(hex: 0xE4C899),
        cream: SKColor(hex: 0xF4EDE0),
        arena: SKColor(hex: 0x07131C),
        arenaDeep: SKColor(hex: 0x04090E),
        warning: SKColor(hex: 0xF5A524),
        success: SKColor(hex: 0x3DDC97),
        panel: SKColor(hex: 0x061018, alpha: 0.78),
        panelStroke: SKColor(hex: 0x00C2C7, alpha: 0.55)
    )

    func primary(for side: TeamSide) -> SKColor {
        side == .home ? teal : magenta
    }

    func secondary(for side: TeamSide) -> SKColor {
        side == .home ? tealDark : magentaDark
    }
}

struct GameConfig {
    var courtWidth: CGFloat
    var courtHeight: CGFloat
    var arenaMargin: CGFloat
    var shootingCircleRadius: CGFloat
    var hoopInset: CGFloat
    var circleInset: CGFloat

    var playerRadius: CGFloat
    var ballRadius: CGFloat
    var depthScaleNear: CGFloat
    var depthScaleFar: CGFloat
    var shadowScale: CGFloat

    var moveSpeed: CGFloat
    var acceleration: CGFloat
    var damping: CGFloat
    var controlledBoost: CGFloat
    var pivotShuffleSpeed: CGFloat
    var pivotShuffleMax: CGFloat
    var inputDeadZone: CGFloat

    var passSpeed: CGFloat
    var passMaxRange: CGFloat
    var catchRadius: CGFloat
    var interceptionRadius: CGFloat
    var passAssist: CGFloat
    var pickupRadius: CGFloat
    var interceptionChance: CGFloat

    var heldBallLimit: TimeInterval

    var quarterCount: Int
    var quarterDuration: TimeInterval
    var centrePassPause: TimeInterval
    var goalResetDuration: TimeInterval
    var quarterBreakDuration: TimeInterval
    var overtimeDuration: TimeInterval

    var shotChargeSpeed: CGFloat
    var shotSweetMin: CGFloat
    var shotSweetMax: CGFloat
    var shotFlightTime: TimeInterval
    var defenderBlockChance: CGFloat

    var aiReactionDelay: TimeInterval
    var aiMarkDistance: CGFloat
    var aiDecisionInterval: TimeInterval
    var aiPassSafety: CGFloat
    var rngSeed: UInt64

    var mercyEnabled: Bool
    var mercyLead: Int
    var mercyFromQuarter: Int

    var palette: GamePalette
    var titleSize: CGFloat
    var scoreSize: CGFloat
    var clockSize: CGFloat
    var controlAlpha: CGFloat
    var liveViewerBase: Int

    var isDebug: Bool

    static let production = GameConfig(
        courtWidth: 360,
        courtHeight: 640,
        arenaMargin: 16,
        shootingCircleRadius: 92,
        hoopInset: 26,
        circleInset: 74,
        playerRadius: 13,
        ballRadius: 6,
        depthScaleNear: 1.22,
        depthScaleFar: 0.70,
        shadowScale: 1.15,
        moveSpeed: 148,
        acceleration: 720,
        damping: 8.5,
        controlledBoost: 1.12,
        pivotShuffleSpeed: 18,
        pivotShuffleMax: 10,
        inputDeadZone: 0.18,
        passSpeed: 340,
        passMaxRange: 280,
        catchRadius: 22,
        interceptionRadius: 16,
        passAssist: 0.55,
        pickupRadius: 18,
        interceptionChance: 0.42,
        heldBallLimit: 3.0,
        quarterCount: 4,
        quarterDuration: 150,
        centrePassPause: 1.15,
        goalResetDuration: 1.35,
        quarterBreakDuration: 2.2,
        overtimeDuration: 60,
        shotChargeSpeed: 1.35,
        shotSweetMin: 0.62,
        shotSweetMax: 0.86,
        shotFlightTime: 0.72,
        defenderBlockChance: 0.28,
        aiReactionDelay: 0.38,
        aiMarkDistance: 34,
        aiDecisionInterval: 0.42,
        aiPassSafety: 0.55,
        rngSeed: 0,
        mercyEnabled: false,
        mercyLead: 8,
        mercyFromQuarter: 3,
        palette: .standard,
        titleSize: 34,
        scoreSize: 26,
        clockSize: 22,
        controlAlpha: 0.78,
        liveViewerBase: 128,
        isDebug: false
    )

    /// Short quarters and a fixed seed so development and tests stay fast.
    static let debug = GameConfig(
        courtWidth: 360,
        courtHeight: 640,
        arenaMargin: 16,
        shootingCircleRadius: 92,
        hoopInset: 26,
        circleInset: 74,
        playerRadius: 13,
        ballRadius: 6,
        depthScaleNear: 1.22,
        depthScaleFar: 0.70,
        shadowScale: 1.15,
        moveSpeed: 160,
        acceleration: 780,
        damping: 8.5,
        controlledBoost: 1.12,
        pivotShuffleSpeed: 18,
        pivotShuffleMax: 10,
        inputDeadZone: 0.18,
        passSpeed: 360,
        passMaxRange: 280,
        catchRadius: 22,
        interceptionRadius: 16,
        passAssist: 0.6,
        pickupRadius: 18,
        interceptionChance: 0.35,
        heldBallLimit: 3.0,
        quarterCount: 4,
        quarterDuration: 20,
        centrePassPause: 0.55,
        goalResetDuration: 0.7,
        quarterBreakDuration: 0.8,
        overtimeDuration: 15,
        shotChargeSpeed: 1.5,
        shotSweetMin: 0.62,
        shotSweetMax: 0.86,
        shotFlightTime: 0.55,
        defenderBlockChance: 0.2,
        aiReactionDelay: 0.22,
        aiMarkDistance: 34,
        aiDecisionInterval: 0.28,
        aiPassSafety: 0.5,
        rngSeed: 42,
        mercyEnabled: false,
        mercyLead: 8,
        mercyFromQuarter: 3,
        palette: .standard,
        titleSize: 34,
        scoreSize: 26,
        clockSize: 22,
        controlAlpha: 0.78,
        liveViewerBase: 128,
        isDebug: true
    )

    static let current = GameConfig.production
}

extension SKColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0xC0FFEE : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
