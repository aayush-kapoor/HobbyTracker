import Foundation

struct Hobby: Identifiable, Codable {
    let id = UUID()
    var name: String
    var description: String
    var color: String // Store as hex string
    var totalTime: TimeInterval // Total time spent in seconds
    var sessions: [TimeSession]
    var createdDate: Date
    
    init(name: String, description: String = "", color: String = "#007AFF") {
        self.name = name
        self.description = description
        self.color = color
        self.totalTime = 0
        self.sessions = []
        self.createdDate = Date()
    }
    
    var formattedTotalTime: String {
        let totalSeconds = Int(totalTime)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            // Show hours and minutes for 1+ hours
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            // Show minutes and seconds for 1+ minutes but less than 1 hour
            return "\(minutes)m \(seconds)s"
        } else {
            // Show just seconds for less than 1 minute
            return "\(seconds)s"
        }
    }
}

struct TimeSession: Identifiable, Codable {
    let id = UUID()
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    var notes: String
    
    init(startTime: Date, endTime: Date, notes: String = "") {
        self.startTime = startTime
        self.endTime = endTime
        self.duration = endTime.timeIntervalSince(startTime)
        self.notes = notes
    }
    
    var formattedDuration: String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            // Show hours and minutes for 1+ hours
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            // Show minutes and seconds for 1+ minutes but less than 1 hour
            return "\(minutes)m \(seconds)s"
        } else {
            // Show just seconds for less than 1 minute
            return "\(seconds)s"
        }
    }
} 
