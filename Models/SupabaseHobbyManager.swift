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
    
    // Background tracking timer management (since parent's are private)
    private var backgroundTrackingStartTimes: [UUID: Date] = [:]
    private var backgroundTimers: [UUID: Timer] = [:]
    
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
            
            // Resume any active tracking sessions after loading hobbies
            await resumeActiveTrackingSessions()
            
            // Load rankings for all hobbies after loading hobbies
            await loadRankingsForAllHobbies()
            
        } catch {
            print("Error loading hobbies: \(error)")
        }
    }
    
    // Resume tracking sessions that were active when app was closed
    @MainActor
    private func resumeActiveTrackingSessions() async {
        for hobby in hobbies {
            if hobby.isCurrentlyTracking, let backgroundStartTime = hobby.trackingStartTime {
                // Set up local tracking state to match background state
                trackingStates[hobby.id] = true
                backgroundTrackingStartTimes[hobby.id] = backgroundStartTime  // Use our own property
                
                // Calculate current elapsed time including background time
                let backgroundTime = Date().timeIntervalSince(backgroundStartTime)
                currentElapsedTimes[hobby.id] = hobby.totalTime + backgroundTime
                
                // Start the UI update timer
                let hobbyId = hobby.id
                let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                    DispatchQueue.main.async {
                        guard let self = self else { return }
                        if let hobbyIndex = self.hobbies.firstIndex(where: { $0.id == hobbyId }) {
                            let currentHobby = self.hobbies[hobbyIndex]
                            self.updateElapsedTimeForBackgroundHobby(currentHobby, originalStartTime: backgroundStartTime)
                        }
                    }
                }
                backgroundTimers[hobby.id] = timer
            }
        }
    }
    
    // Custom elapsed time update for hobbies resumed from background
    @MainActor
    private func updateElapsedTimeForBackgroundHobby(_ hobby: Hobby, originalStartTime: Date) {
        guard self.isTracking(hobby: hobby) else { return }
        
        // Calculate total elapsed time from original background start time
        let totalElapsedTime = Date().timeIntervalSince(originalStartTime)
        self.currentElapsedTimes[hobby.id] = hobby.totalTime + totalElapsedTime
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
        // Calculate total elapsed time including background time
        if let index = hobbies.firstIndex(where: { $0.id == hobby.id }),
           let startTime = hobbies[index].trackingStartTime {
            
            // Calculate total session time (background + active)
            let totalSessionTime = Date().timeIntervalSince(startTime)
            hobbies[index].totalTime += totalSessionTime
            
            // Clear tracking state
            hobbies[index].isCurrentlyTracking = false
            hobbies[index].trackingStartTime = nil
            
            // Save to database
            updateHobby(hobbies[index])
        }
        
        // Clean up our background timers
        backgroundTimers[hobby.id]?.invalidate()
        backgroundTimers.removeValue(forKey: hobby.id)
        backgroundTrackingStartTimes.removeValue(forKey: hobby.id)
        
        // Update local tracking state
        super.pauseTracking(for: hobby)
        
        // Update ranking after tracking session ends
        Task {
            await updateRankingForHobby(hobby.name)
        }
    }
    
    // Override start tracking to persist state to database
    override func startTracking(for hobby: Hobby) {
        // If already tracking locally, don't restart
        if super.isTracking(hobby: hobby) { return }
        
        // Check if this hobby is already tracking in background (database state)
        if let index = hobbies.firstIndex(where: { $0.id == hobby.id }),
           hobbies[index].isCurrentlyTracking {
            // Resume background tracking by syncing local state
            if let backgroundStartTime = hobbies[index].trackingStartTime {
                trackingStates[hobby.id] = true
                backgroundTrackingStartTimes[hobby.id] = backgroundStartTime
                
                let backgroundTime = Date().timeIntervalSince(backgroundStartTime)
                currentElapsedTimes[hobby.id] = hobbies[index].totalTime + backgroundTime
                
                let hobbyId = hobby.id
                let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                    DispatchQueue.main.async {
                        guard let self = self else { return }
                        if let hobbyIndex = self.hobbies.firstIndex(where: { $0.id == hobbyId }) {
                            let currentHobby = self.hobbies[hobbyIndex]
                            self.updateElapsedTimeForBackgroundHobby(currentHobby, originalStartTime: backgroundStartTime)
                        }
                    }
                }
                backgroundTimers[hobby.id] = timer
            }
            return
        }
        
        // Start new tracking session
        super.startTracking(for: hobby)
        
        // Update hobby with tracking state and save to database
        if let index = hobbies.firstIndex(where: { $0.id == hobby.id }) {
            hobbies[index].isCurrentlyTracking = true
            hobbies[index].trackingStartTime = Date()
            
            // Save tracking state to database
            updateHobby(hobbies[index])
        }
    }
    
    // Override elapsed time calculation to handle background tracking
    override func currentElapsedTime(for hobby: Hobby) -> TimeInterval {
        // Use parent implementation now that local state is properly synced
        // The timer-based currentElapsedTimes will be accurate for both local and resumed background tracking
        return super.currentElapsedTime(for: hobby)
    }
    
    // Override isTracking to check persistent state
    override func isTracking(hobby: Hobby) -> Bool {
        // Check both local state and persistent state
        if let index = hobbies.firstIndex(where: { $0.id == hobby.id }) {
            return hobbies[index].isCurrentlyTracking || super.isTracking(hobby: hobby)
        }
        return super.isTracking(hobby: hobby)
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
    
    // Override cancel tracking to clear persistent state
    override func cancelTracking(for hobby: Hobby) {
        // Clear persistent tracking state
        if let index = hobbies.firstIndex(where: { $0.id == hobby.id }) {
            hobbies[index].isCurrentlyTracking = false
            hobbies[index].trackingStartTime = nil
            
            // Save to database
            updateHobby(hobbies[index])
        }
        
        // Clean up our background timers
        backgroundTimers[hobby.id]?.invalidate()
        backgroundTimers.removeValue(forKey: hobby.id)
        backgroundTrackingStartTimes.removeValue(forKey: hobby.id)
        
        // Cancel local tracking
        super.cancelTracking(for: hobby)
    }
    
    // Private methods to prevent UserDefaults usage (parent class methods are private)
    private func saveHobbies() {
        // Do nothing - Supabase handles persistence
    }
    
    private func loadHobbies() {
        // Do nothing - hobbies are loaded from Supabase
    }
    
    deinit {
        // Clean up background timers
        backgroundTimers.values.forEach { $0.invalidate() }
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
    let isCurrentlyTracking: Bool
    let trackingStartTime: Date?
    
    private enum CodingKeys: String, CodingKey {
        case id, name, description, color, theme, sessions
        case userId = "user_id"
        case totalTime = "total_time"
        case createdDate = "created_date"
        case isCurrentlyTracking = "is_currently_tracking"
        case trackingStartTime = "tracking_start_time"
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
            createdDate: hobby.createdDate,
            isCurrentlyTracking: hobby.isCurrentlyTracking,
            trackingStartTime: hobby.trackingStartTime
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
        hobby.isCurrentlyTracking = isCurrentlyTracking
        hobby.trackingStartTime = trackingStartTime
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
