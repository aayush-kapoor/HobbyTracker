import SwiftUI

struct HobbyDetailView: View {
    let hobby: Hobby
    @ObservedObject var hobbyManager: HobbyManager
    @State private var showingSessionNotes = false
    @State private var sessionNotes = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Circle()
                    .fill(Color(hex: hobby.color))
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading) {
                    Text(hobby.name)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)
                    
                    if !hobby.description.isEmpty {
                        Text(hobby.description)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // Track time button and current timer
                VStack(spacing: 8) {
                    if hobbyManager.isTracking && hobbyManager.selectedHobby?.id == hobby.id {
                        // Show current elapsed time with animation
                        Text(hobbyManager.formattedElapsedTime)
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .contentTransition(.numericText())
                            .animation(.smooth(duration: 0.6), value: hobbyManager.formattedElapsedTime)
                            .scaleEffect(hobbyManager.isTracking ? 1.05 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: hobbyManager.isTracking)
                            .padding(.vertical, 8)
                        
                        Button("Stop Tracking") {
                            hobbyManager.pauseTracking()
                            showingSessionNotes = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(.black)
                    } else {
                        Button("Start Tracking") {
                            hobbyManager.startTracking(for: hobby)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(.black)
                        .disabled(hobbyManager.isTracking)
                    }
                }
            }
            
            Divider()
            
            // Stats
            HStack(spacing: 40) {
                VStack(alignment: .leading) {
                    Text("Total Time")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.gray)
                    Text(hobby.formattedTotalTime)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.black)
                }
                
                VStack(alignment: .leading) {
                    Text("Sessions")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.gray)
                    Text("\(hobby.sessions.count)")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.black)
                }
                
                // Show current session status
                if hobbyManager.isTracking && hobbyManager.selectedHobby?.id == hobby.id {
                    VStack(alignment: .leading) {
                        Text("Current Session")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.gray)
                        Text(hobbyManager.formattedElapsedTime)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.black)
                            .contentTransition(.numericText())
                            .animation(.smooth(duration: 0.6), value: hobbyManager.formattedElapsedTime)
                    }
                }
                
                Spacer()
            }
            
            Divider()
            
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
            
            Spacer()
        }
        .padding(32)
        .background(Color.white)
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
    }
}

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
