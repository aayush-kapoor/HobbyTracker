import Foundation
import SwiftUI
import Supabase

class SupabaseHobbyManager: HobbyManager {
    private let supabase: SupabaseClient
    private let authManager: AuthManager
    
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
                
            } catch {
                print("Error updating hobby: \(error)")
            }
        }
    }
    
    func addSession(to hobby: Hobby, session: TimeSession) {
        Task { @MainActor in
            guard let hobbyIndex = hobbies.firstIndex(where: { $0.id == hobby.id }) else { return }
            
            hobbies[hobbyIndex].sessions.append(session)
            hobbies[hobbyIndex].totalTime += session.duration
            
            updateHobby(hobbies[hobbyIndex])
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
