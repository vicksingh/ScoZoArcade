import CoreGraphics

/// 5v5 MVP roles. WA/WD are deferred to a later 7v7 mode.
enum PositionRole: String, CaseIterable {
    case gs
    case ga
    case c
    case gd
    case gk

    var displayLabel: String {
        rawValue.uppercased()
    }

    var canShoot: Bool {
        self == .gs || self == .ga
    }

    /// Attack-circle access for shooters; defence-circle access for GD/GK.
    var canEnterShootingCircle: Bool {
        self != .c
    }

    /// Simplified 5v5 lanes. GD/GK stay in their defensive third (not the centre circle).
    /// C roams the middle and is barred from both shooting circles.
    func legalZone(in geometry: CourtGeometry, team: TeamSide) -> CGRect {
        let w = geometry.size.width
        let third = geometry.thirdHeight
        let inset: CGFloat = 8

        let rect: CGRect
        switch (team, self) {
        case (.home, .gs):
            rect = CGRect(x: inset, y: third * 2 - 24, width: w - inset * 2, height: third + 24)
        case (.home, .ga):
            rect = CGRect(x: inset, y: third - 20, width: w - inset * 2, height: third * 2 + 20)
        case (.home, .c):
            rect = CGRect(x: inset, y: third - 28, width: w - inset * 2, height: third + 56)
        case (.home, .gd):
            rect = CGRect(x: inset, y: 0, width: w - inset * 2, height: third + 40)
        case (.home, .gk):
            rect = CGRect(x: inset, y: 0, width: w - inset * 2, height: third + 16)
        case (.away, .gs):
            rect = CGRect(x: inset, y: 0, width: w - inset * 2, height: third + 24)
        case (.away, .ga):
            rect = CGRect(x: inset, y: 0, width: w - inset * 2, height: third * 2 + 20)
        case (.away, .c):
            rect = CGRect(x: inset, y: third - 28, width: w - inset * 2, height: third + 56)
        case (.away, .gd):
            rect = CGRect(x: inset, y: third * 2 - 40, width: w - inset * 2, height: third + 40)
        case (.away, .gk):
            rect = CGRect(x: inset, y: third * 2 - 16, width: w - inset * 2, height: third + 16)
        }
        return rect.intersection(CGRect(origin: .zero, size: geometry.size))
    }

    func defaultFormation(in geometry: CourtGeometry, team: TeamSide) -> CGPoint {
        Formation.spawn(role: self, team: team, in: geometry)
    }
}
