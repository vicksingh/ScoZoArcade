import Foundation

struct Club: Equatable, Codable, Identifiable {
    let id: String
    let displayName: String
    let shortName: String
    
    static let premierLeague: [Club] = [
        Club(id: "contax", displayName: "Contax", shortName: "CTX"),
        Club(id: "garville", displayName: "Garville", shortName: "GAR"),
        Club(id: "matrics", displayName: "Matrics", shortName: "MAT"),
        Club(id: "norwood", displayName: "Norwood", shortName: "NOR"),
        Club(id: "oakdale", displayName: "Oakdale", shortName: "OAK"),
        Club(id: "south_adelaide", displayName: "South Adelaide", shortName: "SOU"),
        Club(id: "tango", displayName: "Tango", shortName: "TAN"),
        Club(id: "walkerville", displayName: "Walkerville", shortName: "WAL")
    ]
    
    static func random(excluding: Club? = nil) -> Club {
        let candidates = excluding == nil
            ? premierLeague
            : premierLeague.filter { $0.id != excluding!.id }
        return candidates.randomElement() ?? premierLeague[0]
    }
    
    static func find(id: String) -> Club? {
        premierLeague.first { $0.id == id }
    }
}

final class ClubSelection {
    static let shared = ClubSelection()
    
    private let key = "scozo_last_club_id"
    
    var lastClubID: String? {
        get { UserDefaults.standard.string(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
    
    var lastClub: Club? {
        guard let id = lastClubID else { return nil }
        return Club.find(id: id)
    }
    
    func save(_ club: Club) {
        lastClubID = club.id
    }
    
    private init() {}
}
