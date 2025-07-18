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
        
        print("🚀 Loading rankings for all hobbies...")
        
        // Debug: Print all hobbies data first
        await debugAllHobbiesRankings()
        
        for hobby in hobbies {
            print("\n🔄 Processing ranking for: '\(hobby.name)'")
            await updateRankingForHobby(hobby.name)
        }
        
        print("\n✅ Finished loading all rankings")
        print("🏆 Current rankings: \(currentHobbyRankings)")
    }
    
    @MainActor
    func updateRankingForHobby(_ hobbyName: String) async {
        guard let currentUserId = authManager.currentUser?.id.uuidString else { return }
        
        do {
            print("🔍 Fetching ALL users' hobbies for ranking '\(hobbyName)'...")
            print("👤 Current user ID: \(currentUserId.prefix(8))...")
            
            // Ensure we get ALL hobbies from ALL users, not just current user
            // Remove any potential user filtering by explicitly not filtering by user_id
            let allHobbiesResponse: [SupabaseHobby] = try await supabase
                .from("hobbies")
                .select("*")  // Select all columns explicitly
                .execute()
                .value
            
            print("📊 Total hobbies from ALL users: \(allHobbiesResponse.count)")
            print("👥 All users in database:")
            let uniqueUsers = Set(allHobbiesResponse.map { $0.userId })
            for userId in uniqueUsers {
                let isCurrentUser = userId.lowercased() == currentUserId.lowercased() ? "← CURRENT USER" : ""
                print("   User: \(userId.prefix(8))... \(isCurrentUser)")
            }
            
            // Filter for matching hobby names (case-insensitive)
            let response = allHobbiesResponse
                .filter { $0.name.lowercased() == hobbyName.lowercased() }
                .sorted { $0.totalTime > $1.totalTime }  // Sort by time descending
            
            print("🔍 Ranking debug for '\(hobbyName)':")
            print("📊 Found \(response.count) hobbies with this name across ALL users")
            
            // Debug: Print all found hobbies
            for (index, hobby) in response.enumerated() {
                let isCurrentUser = hobby.userId.lowercased() == currentUserId.lowercased() ? "← YOU" : ""
                print("   \(index + 1). User: \(hobby.userId.prefix(8))..., Time: \(hobby.totalTime)s, Name: '\(hobby.name)' \(isCurrentUser)")
            }
            
            // Calculate rankings
            var currentRank = 1
            var actualRank: Int? = nil
            var foundCurrentUser = false
            
            for (index, hobbyData) in response.enumerated() {
                // Update rank only when time changes (handle ties)
                if index > 0 && hobbyData.totalTime < response[index - 1].totalTime {
                    currentRank = index + 1
                }
                
                print("🔍 Comparing users:")
                print("   hobbyData.userId: '\(hobbyData.userId)'")
                print("   currentUserId: '\(currentUserId)'")
                print("   Are they equal? \(hobbyData.userId.lowercased() == currentUserId.lowercased())")
                
                // Case-insensitive comparison for UUID matching
                if hobbyData.userId.lowercased() == currentUserId.lowercased() {
                    actualRank = currentRank
                    foundCurrentUser = true
                    print("✅ Found current user rank: #\(actualRank!) with \(hobbyData.totalTime)s")
                    break
                }
            }
            
            // Handle case where current user doesn't have this hobby yet
            if !foundCurrentUser {
                print("⚠️ Current user doesn't have this hobby yet - no ranking to display")
                // Don't set any ranking - leave it nil so no rank is displayed
                currentHobbyRankings.removeValue(forKey: hobbyName.lowercased())
                return
            }
            
            // Update the ranking for this hobby
            if let rank = actualRank {
                currentHobbyRankings[hobbyName.lowercased()] = rank
                print("🏆 Set rank for '\(hobbyName)': #\(rank)")
            }
            
        } catch {
            print("❌ Error calculating ranking for \(hobbyName): \(error)")
            print("📊 Error details: \(error.localizedDescription)")
        }
    }
    
    // Debug method to test ranking system
    @MainActor
    func debugAllHobbiesRankings() async {
        print("🔧 DEBUG: All hobbies rankings")
        
        do {
            // Explicitly fetch ALL hobbies from ALL users
            let allHobbies: [SupabaseHobby] = try await supabase
                .from("hobbies")
                .select("*")  // Select all columns explicitly
                .execute()
                .value
            
            print("📋 Total hobbies in database from ALL users: \(allHobbies.count)")
            
            // Show unique users
            let uniqueUsers = Set(allHobbies.map { $0.userId })
            print("👥 Unique users in database: \(uniqueUsers.count)")
            for userId in uniqueUsers {
                print("   User: \(userId.prefix(8))...")
            }
            
            // Group by hobby name (case-insensitive)
            var hobbyGroups: [String: [SupabaseHobby]] = [:]
            for hobby in allHobbies {
                let key = hobby.name.lowercased()
                if hobbyGroups[key] == nil {
                    hobbyGroups[key] = []
                }
                hobbyGroups[key]?.append(hobby)
            }
            
            print("🏷️ Unique hobby names: \(hobbyGroups.keys.sorted())")
            
            for (hobbyName, hobbies) in hobbyGroups {
                print("\n📊 Hobby: '\(hobbyName)' (\(hobbies.count) users)")
                let sortedHobbies = hobbies.sorted { $0.totalTime > $1.totalTime }
                for (index, hobby) in sortedHobbies.enumerated() {
                    print("   Rank #\(index + 1): User \(hobby.userId.prefix(8))... - \(hobby.totalTime)s - '\(hobby.name)'")
                }
            }
            
        } catch {
            print("❌ Debug error: \(error)")
            print("📊 Debug error details: \(error.localizedDescription)")
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
