import Foundation
import SwiftUI
import Supabase

// MARK: - Ranking Models

struct HobbyRanking: Codable {
    let userId: String
    let rank: Int
    let totalTime: TimeInterval
    let hobbyName: String
    
    init(userId: String, rank: Int, totalTime: TimeInterval, hobbyName: String) {
        self.userId = userId
        self.rank = rank
        self.totalTime = totalTime
        self.hobbyName = hobbyName
    }
}

struct UserRanking: Codable {
    let userId: String
    let userName: String?
    let totalTime: TimeInterval
    
    private enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case userName = "user_name"
        case totalTime = "total_time"
    }
}

class SupabaseHobbyManager: HobbyManager {
    private let supabase: SupabaseClient
    private let authManager: AuthManager
    
    // Published ranking state
    @Published var currentHobbyRankings: [String: Int] = [:] // hobbyName -> rank
    @Published var isLoadingRankings: Bool = false
    
    init(authManager: AuthManager) {
        self.authManager = authManager
        // Use configuration file
        self.supabase = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.supabaseURL)!,
            supabaseKey: SupabaseConfig.supabaseAnonKey
        )
        
        // Initialize with empty hobbies array first
        super.init()
        
        // Clear any sample data that might have been loaded by parent
        self.hobbies = []
        
        // Note: Hobbies will be loaded when user signs in via ContentView's onReceive handler
    }
    
    // MARK: - Theme Queue System
    
    private func getNextTheme() -> HobbyTheme {
        let themes: [HobbyTheme] = [.green, .red, .blue]
        let currentCount = hobbies.count
        let themeIndex = currentCount % themes.count
        return themes[themeIndex]
    }
    
    // MARK: - Supabase Operations
    
    @MainActor
    func loadHobbiesFromSupabase() async {
        guard let userId = authManager.currentUser?.id.uuidString else { return }
        
        do {
            let response: [SupabaseHobby] = try await supabase
                .from("hobbies")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value
            
            self.hobbies = response.map { $0.toHobby() }
            
            // Load rankings for all hobbies after loading hobbies
            await loadRankingsForAllHobbies()
            
        } catch {
            print("Error loading hobbies: \(error)")
        }
    }
    
    override func addHobby(_ hobby: Hobby) {
        Task { @MainActor in
            guard let userId = authManager.currentUser?.id.uuidString else { return }
            
            var newHobby = hobby
            newHobby.userId = userId
            // Automatically assign theme based on queue
            newHobby.theme = getNextTheme()
            
            let supabaseHobby = SupabaseHobby.from(hobby: newHobby)
            
            do {
                try await supabase
                    .from("hobbies")
                    .insert(supabaseHobby)
                    .execute()
                
                self.hobbies.append(newHobby)
                
            } catch {
                print("Error adding hobby: \(error)")
            }
        }
    }
    
    override func deleteHobby(_ hobby: Hobby) {
        Task {
            do {
                try await supabase
                    .from("hobbies")
                    .delete()
                    .eq("id", value: hobby.id.uuidString)
                    .execute()
                
                await MainActor.run {
                    self.hobbies.removeAll { $0.id == hobby.id }
                    if self.selectedHobby?.id == hobby.id {
                        self.selectedHobby = self.hobbies.first
                    }
                    self.stopTracking(for: hobby)
                }
                
            } catch {
                print("Error deleting hobby: \(error)")
            }
        }
    }
    
    func addSession(to hobby: Hobby, session: TimeSession) {
        Task { @MainActor in
            guard let hobbyIndex = hobbies.firstIndex(where: { $0.id == hobby.id }) else { return }
            
            hobbies[hobbyIndex].sessions.append(session)
            hobbies[hobbyIndex].totalTime += session.duration
            
            updateHobby(hobbies[hobbyIndex])
            
            // Update rankings after adding session
            await updateRankingForHobby(hobbies[hobbyIndex].name)
        }
    }
    
    // MARK: - Ranking System
    
    @MainActor
    func loadRankingsForAllHobbies() async {
        isLoadingRankings = true
        defer { isLoadingRankings = false }
        
        for hobby in hobbies {
            await updateRankingForHobby(hobby.name)
        }
    }
    
    @MainActor
    func updateRankingForHobby(_ hobbyName: String) async {
        guard let currentUserId = authManager.currentUser?.id.uuidString else { return }
        
        do {
            // Ensure we get ALL hobbies from ALL users, not just current user
            // Remove any potential user filtering by explicitly not filtering by user_id
            let allHobbiesResponse: [SupabaseHobby] = try await supabase
                .from("hobbies")
                .select("*")  // Select all columns explicitly
                .execute()
                .value
            
            // Filter for matching hobby names (case-insensitive)
            let response = allHobbiesResponse
                .filter { $0.name.lowercased() == hobbyName.lowercased() }
                .sorted { $0.totalTime > $1.totalTime }  // Sort by time descending
            
            // Calculate rankings
            var currentRank = 1
            var actualRank: Int? = nil
            var foundCurrentUser = false
            
            for (index, hobbyData) in response.enumerated() {
                // Update rank only when time changes (handle ties)
                if index > 0 && hobbyData.totalTime < response[index - 1].totalTime {
                    currentRank = index + 1
                }
                
                // Case-insensitive comparison for UUID matching
                if hobbyData.userId.lowercased() == currentUserId.lowercased() {
                    actualRank = currentRank
                    foundCurrentUser = true
                    break
                }
            }
            
            // Handle case where current user doesn't have this hobby yet
            if !foundCurrentUser {
                currentHobbyRankings.removeValue(forKey: hobbyName.lowercased())
                return
            }
            
            // Update the ranking for this hobby
            if let rank = actualRank {
                currentHobbyRankings[hobbyName.lowercased()] = rank
            }
            
        } catch {
            print("❌ Error calculating ranking for \(hobbyName): \(error)")
        }
    }
    
    func getRankForHobby(_ hobbyName: String) -> Int? {
        return currentHobbyRankings[hobbyName.lowercased()]
    }
    
    // Override updateHobby to trigger ranking updates
    override func updateHobby(_ hobby: Hobby) {
        let hobbyToUpdate = hobby
        
        Task {
            do {
                let supabaseHobby = SupabaseHobby.from(hobby: hobbyToUpdate)
                try await supabase
                    .from("hobbies")
                    .update(supabaseHobby)
                    .eq("id", value: hobbyToUpdate.id.uuidString)
                    .execute()
                
                await MainActor.run {
                    if let index = self.hobbies.firstIndex(where: { $0.id == hobbyToUpdate.id }) {
                        self.hobbies[index] = hobbyToUpdate
                    }
                }
                
                // Update ranking after hobby time changes
                await updateRankingForHobby(hobbyToUpdate.name)
                
            } catch {
                print("Error updating hobby: \(error)")
            }
        }
    }
    
    // Override pause tracking to update rankings when session ends
    override func pauseTracking(for hobby: Hobby) {
        super.pauseTracking(for: hobby)
        
        // Update ranking after tracking session ends
        Task {
            await updateRankingForHobby(hobby.name)
        }
    }
    
    // Real-time ranking refresh for currently tracking hobbies
    func refreshRankingsForActiveHobbies() {
        Task { @MainActor in
            for hobby in hobbies {
                if isTracking(hobby: hobby) {
                    await updateRankingForHobby(hobby.name)
                }
            }
        }
    }
    
    // Private methods to prevent UserDefaults usage (parent class methods are private)
    private func saveHobbies() {
        // Do nothing - Supabase handles persistence
    }
    
    private func loadHobbies() {
        // Do nothing - hobbies are loaded from Supabase
    }
}

// MARK: - Supabase Models

struct SupabaseHobby: Codable {
    let id: String
    let userId: String
    let name: String
    let description: String
    let color: String
    let theme: String
    let totalTime: TimeInterval
    let sessions: [SupabaseTimeSession]
    let createdDate: Date
    
    private enum CodingKeys: String, CodingKey {
        case id, name, description, color, theme, sessions
        case userId = "user_id"
        case totalTime = "total_time"
        case createdDate = "created_date"
    }
    
    static func from(hobby: Hobby) -> SupabaseHobby {
        return SupabaseHobby(
            id: hobby.id.uuidString,
            userId: hobby.userId ?? "",
            name: hobby.name,
            description: hobby.description,
            color: hobby.color,
            theme: hobby.theme.rawValue,
            totalTime: hobby.totalTime,
            sessions: hobby.sessions.map { SupabaseTimeSession.from(session: $0) },
            createdDate: hobby.createdDate
        )
    }
    
    func toHobby() -> Hobby {
        // Convert string ID back to UUID
        let hobbyId = UUID(uuidString: id) ?? UUID()
        let hobbyTheme = HobbyTheme(rawValue: theme) ?? .green
        var hobby = Hobby(name: name, description: description, color: color, theme: hobbyTheme, userId: userId, id: hobbyId)
        hobby.totalTime = totalTime
        hobby.sessions = sessions.map { $0.toTimeSession() }
        hobby.createdDate = createdDate
        return hobby
    }
}

struct SupabaseTimeSession: Codable {
    let id: String
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    let notes: String
    
    private enum CodingKeys: String, CodingKey {
        case id, duration, notes
        case startTime = "start_time"
        case endTime = "end_time"
    }
    
    static func from(session: TimeSession) -> SupabaseTimeSession {
        return SupabaseTimeSession(
            id: session.id.uuidString,
            startTime: session.startTime,
            endTime: session.endTime,
            duration: session.duration,
            notes: session.notes
        )
    }
    
    func toTimeSession() -> TimeSession {
        var session = TimeSession(startTime: startTime, endTime: endTime, notes: notes)
        // Note: TimeSession has auto-generated UUID, preserving database relationship through timestamps
        return session
    }
} 
