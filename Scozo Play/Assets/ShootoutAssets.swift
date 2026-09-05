import SpriteKit

/// Asset loader for Shootout 2D art pack.
/// Falls back to procedural shapes when PNG assets are not yet available.
/// 
/// Expected asset names in Assets.xcassets:
/// - court
/// - ball
/// - selection-ring
/// - gs-idle, gs-shuffle, gs-pass, gs-shoot
/// - ga-idle, ga-shuffle, ga-pass, ga-shoot
/// - gd-idle, gd-shuffle, gd-defend
/// - gk-idle, gk-shuffle, gk-defend
enum ShootoutAssets {
    
    enum PlayerPose: String, CaseIterable {
        case idle
        case shuffle
        case pass
        case shoot
        case defend
    }
    
    enum PlayerRole: String {
        case gs, ga, gd, gk
        
        var availablePoses: [PlayerPose] {
            switch self {
            case .gs, .ga:
                return [.idle, .shuffle, .pass, .shoot]
            case .gd, .gk:
                return [.idle, .shuffle, .defend]
            }
        }
        
        func assetName(for pose: PlayerPose) -> String {
            "\(rawValue)-\(pose.rawValue)"
        }
    }
    
    static func courtTexture() -> SKTexture? {
        textureIfExists(named: "court")
    }
    
    static func ballTexture() -> SKTexture? {
        textureIfExists(named: "ball")
    }
    
    static func selectionRingTexture() -> SKTexture? {
        textureIfExists(named: "selection-ring")
    }
    
    static func playerTexture(role: PlayerRole, pose: PlayerPose) -> SKTexture? {
        textureIfExists(named: role.assetName(for: pose))
    }
    
    static func playerTextures(role: PlayerRole) -> [PlayerPose: SKTexture] {
        var textures: [PlayerPose: SKTexture] = [:]
        for pose in role.availablePoses {
            if let texture = playerTexture(role: role, pose: pose) {
                textures[pose] = texture
            }
        }
        return textures
    }
    
    static var hasArtPack: Bool {
        courtTexture() != nil
    }
    
    private static func textureIfExists(named name: String) -> SKTexture? {
        guard let _ = UIImage(named: name) else { return nil }
        return SKTexture(imageNamed: name)
    }
    
    static func allExpectedAssetNames() -> [String] {
        var names = ["court", "ball", "selection-ring"]
        for role in [PlayerRole.gs, .ga, .gd, .gk] {
            for pose in role.availablePoses {
                names.append(role.assetName(for: pose))
            }
        }
        return names
    }
    
    static func missingAssets() -> [String] {
        allExpectedAssetNames().filter { textureIfExists(named: $0) == nil }
    }
}
