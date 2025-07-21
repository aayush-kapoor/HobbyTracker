import SwiftUI

// MARK: - Visual Theme Colors mapped from HobbyTheme
struct VisualTheme {
    let backgroundColor: Color
    let textColor: Color
    let startStopButtonColor: Color
    let otherButtonColor: Color
    
    static func from(_ hobbyTheme: HobbyTheme) -> VisualTheme {
        switch hobbyTheme {
        case .red:
            return VisualTheme(
                backgroundColor: Color(hex: "#FFF2F2"),
                textColor: Color(hex: "#471515"),
                startStopButtonColor: Color(hex: "#FF7C7C"),
                otherButtonColor: Color(hex: "#FFD9D9")
            )
        case .green:
            return VisualTheme(
                backgroundColor: Color(hex: "#F2FFF5"),
                textColor: Color(hex: "#14401D"),
                startStopButtonColor: Color(hex: "#8CE8A1"),
                otherButtonColor: Color(hex: "#DAFAE0")
            )
        case .blue:
            return VisualTheme(
                backgroundColor: Color(hex: "#F2F9FF"),
                textColor: Color(hex: "#153047"),
                startStopButtonColor: Color(hex: "#8BCAFF"),
                otherButtonColor: Color(hex: "#D9EEFF")
            )
        }
    }
}

struct HobbyDetailView: View {
    let hobby: Hobby
    @ObservedObject var hobbyManager: HobbyManager
    // COMMENTED OUT: Session-related state variables
    // @State private var showingSessionNotes = false
    // @State private var sessionNotes = ""
    @State private var rankingUpdateTimer: Timer?
    
    // Use stored theme from hobby model
    private var theme: VisualTheme {
        return VisualTheme.from(hobby.theme)
    }
    
    // Cast to SupabaseHobbyManager for ranking access
    private var supabaseHobbyManager: SupabaseHobbyManager? {
        return hobbyManager as? SupabaseHobbyManager
    }
    
    var body: some View {
        ZStack {
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
                if hobbyManager.isTracking(hobby: hobby) {
                    Text(hobbyManager.formattedElapsedTimeMMSS(for: hobby))
                        .font(.system(size: 120, weight: .black, design: .monospaced))
                        .foregroundColor(theme.textColor)
                        .contentTransition(.numericText())
                        .animation(.smooth(duration: 0.6), value: hobbyManager.formattedElapsedTimeMMSS(for: hobby))
                        .scaleEffect(hobbyManager.isTracking(hobby: hobby) ? 1.0 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: hobbyManager.isTracking(hobby: hobby))
                } else {
                    Text(formattedHobbyTotalTime)
                        .font(.system(size: 120, weight: .black, design: .monospaced))
                        .foregroundColor(theme.textColor)
                }
            }
            
            Spacer()
            
            // Control button
            // Start/Stop button
            Button(action: {
                if hobbyManager.isTracking(hobby: hobby) {
                    hobbyManager.pauseTracking(for: hobby)
                } else {
                    hobbyManager.startTracking(for: hobby)
                }
            }) {
                Image(systemName: hobbyManager.isTracking(hobby: hobby) ? "pause.fill" : "play.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(theme.textColor)
                    .frame(width: 80, height: 60)
                    .background(theme.startStopButtonColor)
                    .cornerRadius(30)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
        }
        
        // Ranking display in top-right corner
        VStack {
            HStack {
                Spacer()
                
                if let rank = supabaseHobbyManager?.getRankForHobby(hobby.name) {
                    // Show trophy icons for top 3 ranks, text for others
                    if rank <= 3 {
                        Image("rank-\(rank)")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 48, height: 48)
                            .padding(.horizontal, 10)
                            // .shadow(color: theme.textColor.opacity(0.2), radius: 4, x: 0, y: 2)
                    } else {
                        Text("#\(rank)")
                            .font(.system(size: 20, weight: .black, design: .default))
                            .foregroundColor(theme.textColor)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(theme.otherButtonColor)
                            .cornerRadius(20)
                            // .shadow(color: theme.textColor.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                } else if supabaseHobbyManager?.isLoadingRankings == true {
                    Text("--")
                        .font(.system(size: 20, weight: .black, design: .default))
                        .foregroundColor(theme.textColor.opacity(0.6))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(theme.otherButtonColor)
                        .cornerRadius(20)
                }
            }
            .padding(.top, 60) // Safe area padding for top
            .padding(.trailing, 20)
            
            Spacer()
        }
    }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.backgroundColor)
        .onAppear {
            // Load ranking when view appears
            Task {
                await supabaseHobbyManager?.updateRankingForHobby(hobby.name)
            }
        }
        .onDisappear {
            // Clean up timer when view disappears
            rankingUpdateTimer?.invalidate()
            rankingUpdateTimer = nil
        }
        .onChange(of: hobbyManager.isTracking(hobby: hobby)) { isTracking in
            if isTracking {
                // Start periodic ranking updates while tracking
                startRankingUpdates()
            } else {
                // Stop ranking updates when not tracking
                stopRankingUpdates()
                // Update ranking one final time when tracking stops
                Task {
                    await supabaseHobbyManager?.updateRankingForHobby(hobby.name)
                }
            }
        }
        
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
    
    // MARK: - Ranking Update Methods
    
    private func startRankingUpdates() {
        // Update rankings every 30 seconds while tracking
        rankingUpdateTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            Task {
                await supabaseHobbyManager?.updateRankingForHobby(hobby.name)
            }
        }
    }
    
    private func stopRankingUpdates() {
        rankingUpdateTimer?.invalidate()
        rankingUpdateTimer = nil
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
