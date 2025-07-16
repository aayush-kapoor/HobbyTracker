import Foundation
import SwiftUI

class HobbyManager: ObservableObject {
    @Published var hobbies: [Hobby] = []
    @Published var selectedHobby: Hobby?
    @Published var currentSession: TimeSession?
    
    // Track multiple hobbies simultaneously
    @Published var trackingStates: [UUID: Bool] = [:]
    @Published var currentElapsedTimes: [UUID: TimeInterval] = [:]
    
    private let saveKey = "SavedHobbies"
    private var trackingStartTimes: [UUID: Date] = [:]
    private var timers: [UUID: Timer] = [:]
    
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
        // Clean up tracking state
        stopTracking(for: hobby)
        trackingStates.removeValue(forKey: hobby.id)
        currentElapsedTimes.removeValue(forKey: hobby.id)
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
        guard !isTracking(hobby: hobby) else { return }
        
        trackingStates[hobby.id] = true
        trackingStartTimes[hobby.id] = Date()
        currentElapsedTimes[hobby.id] = hobby.totalTime
        
        // Start the timer to update elapsed time every 0.1 seconds for smooth updates
        let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateElapsedTime(for: hobby)
            }
        }
        timers[hobby.id] = timer
        RunLoop.main.add(timer, forMode: .common)
    }
    
    private func updateElapsedTime(for hobby: Hobby) {
        guard let startTime = trackingStartTimes[hobby.id],
              isTracking(hobby: hobby) else { return }
        
        // Add the session elapsed time to the hobby's existing total
        currentElapsedTimes[hobby.id] = hobby.totalTime + Date().timeIntervalSince(startTime)
    }
    
    func pauseTracking(for hobby: Hobby) {
        guard isTracking(hobby: hobby) else { return }
        
        // Stop the timer and save the current total time
        timers[hobby.id]?.invalidate()
        timers.removeValue(forKey: hobby.id)
        
        // Save the current elapsed time as the hobby's total time
        if let currentTime = currentElapsedTimes[hobby.id] {
            var updatedHobby = hobby
            updatedHobby.totalTime = currentTime
            updateHobby(updatedHobby)
        }
        
        // Reset tracking state for this hobby
        trackingStates[hobby.id] = false
        trackingStartTimes.removeValue(forKey: hobby.id)
    }
    
    func stopTracking(for hobby: Hobby) {
        // Same as pause for now - just stop and save
        pauseTracking(for: hobby)
    }
    
    func cancelTracking(for hobby: Hobby) {
        // Stop the timer without saving
        timers[hobby.id]?.invalidate()
        timers.removeValue(forKey: hobby.id)
        
        // Reset tracking state without saving time
        trackingStates[hobby.id] = false
        trackingStartTimes.removeValue(forKey: hobby.id)
        currentElapsedTimes[hobby.id] = hobby.totalTime
    }
    
    // MARK: - Helper Methods
    
    func isTracking(hobby: Hobby) -> Bool {
        return trackingStates[hobby.id] ?? false
    }
    
    func currentElapsedTime(for hobby: Hobby) -> TimeInterval {
        return currentElapsedTimes[hobby.id] ?? hobby.totalTime
    }
    
    func formattedElapsedTime(for hobby: Hobby) -> String {
        let totalSeconds = Int(currentElapsedTime(for: hobby))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    func formattedElapsedTimeMMSS(for hobby: Hobby) -> String {
        let totalSeconds = Int(currentElapsedTime(for: hobby))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    deinit {
        // Clean up all timers
        timers.values.forEach { $0.invalidate() }
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
