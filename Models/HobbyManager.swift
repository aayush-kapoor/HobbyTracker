import Foundation
import SwiftUI

class HobbyManager: ObservableObject {
    @Published var hobbies: [Hobby] = []
    @Published var selectedHobby: Hobby?
    @Published var currentSession: TimeSession?
    @Published var isTracking: Bool = false
    @Published var currentElapsedTime: TimeInterval = 0
    
    private let saveKey = "SavedHobbies"
    private var trackingStartTime: Date?
    private var timer: Timer?
    private var finalElapsedTime: TimeInterval = 0
    
    init() {
        loadHobbies()
    }
    
    // MARK: - Hobby Management
    
    func addHobby(_ hobby: Hobby) {
        hobbies.append(hobby)
        saveHobbies()
    }
    
    func deleteHobby(_ hobby: Hobby) {
        hobbies.removeAll { $0.id == hobby.id }
        if selectedHobby?.id == hobby.id {
            selectedHobby = nil
        }
        saveHobbies()
    }
    
    func selectHobby(_ hobby: Hobby) {
        selectedHobby = hobby
    }
    
    func updateHobby(_ updatedHobby: Hobby) {
        if let index = hobbies.firstIndex(where: { $0.id == updatedHobby.id }) {
            hobbies[index] = updatedHobby
            if selectedHobby?.id == updatedHobby.id {
                selectedHobby = updatedHobby
            }
            saveHobbies()
        }
    }
    
    // MARK: - Time Tracking
    
    func startTracking(for hobby: Hobby) {
        guard !isTracking else { return }
        
        isTracking = true
        trackingStartTime = Date()
        // Start from the hobby's existing total time
        currentElapsedTime = hobby.totalTime
        
        // Start the timer to update elapsed time every 0.1 seconds for smooth updates
        timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateElapsedTime()
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    private func updateElapsedTime() {
        guard let startTime = trackingStartTime, let hobby = selectedHobby else { return }
        // Add the session elapsed time to the hobby's existing total
        currentElapsedTime = hobby.totalTime + Date().timeIntervalSince(startTime)
    }
    
    func pauseTracking() {
        // Stop the timer and save the current total time
        guard isTracking, let hobby = selectedHobby else { return }
        
        timer?.invalidate()
        timer = nil
        
        // Save the current elapsed time as the hobby's total time
        var updatedHobby = hobby
        updatedHobby.totalTime = currentElapsedTime
        updateHobby(updatedHobby)
        
        // Reset tracking state
        isTracking = false
        trackingStartTime = nil
        finalElapsedTime = 0
    }
    
    func stopTracking(with notes: String = "") {
        guard let hobby = selectedHobby, let startTime = trackingStartTime else { return }
        
        // Simply update the hobby's total time with the current elapsed time
        var updatedHobby = hobby
        updatedHobby.totalTime = currentElapsedTime
        
        updateHobby(updatedHobby)
        
        // Reset tracking state
        isTracking = false
        trackingStartTime = nil
        currentElapsedTime = 0
        finalElapsedTime = 0
        
        // COMMENTED OUT: Session tracking code
        /*
        let endTime = startTime.addingTimeInterval(finalElapsedTime)
        let session = TimeSession(startTime: startTime, endTime: endTime, notes: notes)
        
        var updatedHobby = hobby
        updatedHobby.sessions.append(session)
        updatedHobby.totalTime += session.duration
        */
    }
    
    func cancelTracking() {
        // Stop the timer without saving a session
        timer?.invalidate()
        timer = nil
        
        // Reset tracking state
        isTracking = false
        trackingStartTime = nil
        currentElapsedTime = 0
        finalElapsedTime = 0
    }
    
    // MARK: - Helper Methods
    
    var formattedElapsedTime: String {
        let totalSeconds = Int(currentElapsedTime)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    var formattedElapsedTimeMMSS: String {
        let totalSeconds = Int(currentElapsedTime)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // MARK: - Persistence
    
    private func saveHobbies() {
        if let encoded = try? JSONEncoder().encode(hobbies) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadHobbies() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Hobby].self, from: data) {
            hobbies = decoded
        } else {
            // Add some sample data for testing
            hobbies = [
                Hobby(name: "Guitar", description: "Learning acoustic guitar", color: "#FF6B6B"),
                Hobby(name: "Cooking", description: "Exploring new recipes", color: "#4ECDC4"),
                Hobby(name: "Photography", description: "Street and landscape photography", color: "#45B7D1")
            ]
        }
    }
}
