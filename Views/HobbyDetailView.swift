import SwiftUI

// MARK: - Color Theme System
enum HobbyTheme {
    case red, green, blue
    
    var backgroundColor: Color {
        switch self {
        case .red: return Color(hex: "#FFF2F2")
        case .green: return Color(hex: "#F2FFF5") 
        case .blue: return Color(hex: "#F2F9FF")
        }
    }
    
    var textColor: Color {
        switch self {
        case .red: return Color(hex: "#471515")
        case .green: return Color(hex: "#14401D")
        case .blue: return Color(hex: "#153047")
        }
    }
    
    var startStopButtonColor: Color {
        switch self {
        case .red: return Color(hex: "#FF7C7C")
        case .green: return Color(hex: "#8CE8A1")
        case .blue: return Color(hex: "#8BCAFF")
        }
    }
    
    var otherButtonColor: Color {
        switch self {
        case .red: return Color(hex: "#FFD9D9")
        case .green: return Color(hex: "#DAFAE0")
        case .blue: return Color(hex: "#D9EEFF")
        }
    }
}



struct HobbyDetailView: View {
    let hobby: Hobby
    @ObservedObject var hobbyManager: HobbyManager
    // COMMENTED OUT: Session-related state variables
    // @State private var showingSessionNotes = false
    // @State private var sessionNotes = ""
    
    // Determine theme based on hobby name (you can modify this logic)
    private var theme: HobbyTheme {
        let hobbyName = hobby.name.lowercased()
        if hobbyName.contains("cook") || hobbyName.contains("baking") || hobbyName.contains("chef") {
            return .green
        } else if hobbyName.contains("guitar") || hobbyName.contains("music") || hobbyName.contains("piano") || hobbyName.contains("instrument") {
            return .red
        } else if hobbyName.contains("cod") || hobbyName.contains("program") || hobbyName.contains("tech") || hobbyName.contains("computer") || hobbyName.contains("photo") {
            return .blue
        } else {
            // Default cycle based on hash of hobby name
            let hash = abs(hobby.name.hashValue)
            switch hash % 3 {
            case 0: return .red
            case 1: return .green
            default: return .blue
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Hobby name pill
            HStack {
                // Icon based on hobby type
                Image(systemName: getHobbyIcon())
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(theme.textColor)
                
                Text(hobby.name)
                    .font(.system(size: 22, weight: .bold, design: .default))
                    .foregroundColor(theme.textColor)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(theme.otherButtonColor)
            .cornerRadius(25)
            
            Spacer()
            
            // Large timer display - shows total time for hobby
            VStack(spacing: 8) {
                if hobbyManager.isTracking && hobbyManager.selectedHobby?.id == hobby.id {
                    Text(hobbyManager.formattedElapsedTimeMMSS)
                        .font(.system(size: 120, weight: .black, design: .monospaced))
                        .foregroundColor(theme.textColor)
                        .contentTransition(.numericText())
                        .animation(.smooth(duration: 0.6), value: hobbyManager.formattedElapsedTimeMMSS)
                        .scaleEffect(hobbyManager.isTracking ? 1.02 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: hobbyManager.isTracking)
                } else {
                    Text(formattedHobbyTotalTime)
                        .font(.system(size: 120, weight: .black, design: .monospaced))
                        .foregroundColor(theme.textColor)
                }
            }
            
            Spacer()
            
            // Control buttons
            HStack(spacing: 40) {
                // Menu/Options button
                Button(action: {
                    // TODO: Add menu functionality
                }) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(theme.textColor)
                        .frame(width: 60, height: 60)
                        .background(theme.otherButtonColor)
                        .cornerRadius(30)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Start/Stop button (larger)
                Button(action: {
                    if hobbyManager.isTracking && hobbyManager.selectedHobby?.id == hobby.id {
                        hobbyManager.pauseTracking()
                    } else {
                        hobbyManager.startTracking(for: hobby)
                    }
                }) {
                    Image(systemName: hobbyManager.isTracking && hobbyManager.selectedHobby?.id == hobby.id ? "pause.fill" : "play.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(theme.textColor)
                        .frame(width: 80, height: 60)
                        .background(theme.startStopButtonColor)
                        .cornerRadius(30)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(hobbyManager.isTracking && hobbyManager.selectedHobby?.id != hobby.id)
                
                // Skip/Next button
                Button(action: {
                    // TODO: Add skip functionality
                }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(theme.textColor)
                        .frame(width: 60, height: 60)
                        .background(theme.otherButtonColor)
                        .cornerRadius(30)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.backgroundColor)
        
        // COMMENTED OUT: Session notes functionality
        /*
        .sheet(isPresented: $showingSessionNotes) {
            SessionNotesView(
                notes: $sessionNotes,
                onSave: {
                    hobbyManager.stopTracking(with: sessionNotes)
                    sessionNotes = ""
                },
                onCancel: {
                    hobbyManager.cancelTracking()
                    sessionNotes = ""
                }
            )
        }
        */
    }
    
    private var formattedHobbyTotalTime: String {
        let totalSeconds = Int(hobby.totalTime)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func getHobbyIcon() -> String {
        let hobbyName = hobby.name.lowercased()
        if hobbyName.contains("cook") || hobbyName.contains("baking") || hobbyName.contains("chef") {
            return "cup.and.saucer.fill"
        } else if hobbyName.contains("guitar") || hobbyName.contains("music") || hobbyName.contains("piano") || hobbyName.contains("instrument") {
            return "guitars.fill"
        } else if hobbyName.contains("cod") || hobbyName.contains("program") || hobbyName.contains("tech") || hobbyName.contains("computer") || hobbyName.contains("photo") {
            return "laptopcomputer"
        } else {
            return "star.fill"
        }
    }
}

// MARK: - Commented out Recent Sessions (for later use)
/*
// Recent Sessions
VStack(alignment: .leading, spacing: 12) {
    Text("Recent Sessions")
        .font(.system(size: 20, weight: .semibold))
        .foregroundColor(.black)
    
    if hobby.sessions.isEmpty {
        Text("No sessions yet. Start tracking to see your progress!")
            .foregroundColor(.gray)
            .italic()
    } else {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(hobby.sessions.sorted { $0.startTime > $1.startTime }.prefix(10)) { session in
                    SessionRowView(session: session)
                }
            }
        }
    }
}
*/

struct SessionRowView: View {
    let session: TimeSession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(session.formattedDuration)
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Text(session.startTime, style: .date)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                if !session.notes.isEmpty {
                    Text(session.notes)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

struct HobbyDetailView_Previews: PreviewProvider {
    static var previews: some View {
        HobbyDetailView(
            hobby: Hobby(name: "Guitar", description: "Learning acoustic guitar", color: "#FF6B6B"),
            hobbyManager: HobbyManager()
        )
    }
} 
