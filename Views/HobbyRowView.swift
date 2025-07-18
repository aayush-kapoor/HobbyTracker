import SwiftUI

struct HobbyRowView: View {
    let hobby: Hobby
    let isSelected: Bool
    @ObservedObject var hobbyManager: HobbyManager
    @State private var isHovered: Bool = false
    @GestureState private var isPressing = false  // EXACT same as HoldButton
    @State private var deleteProgress: CGFloat = 0.0  // EXACT same as HoldButton
    @State private var showDeleteIcon: Bool = false
    @State private var progressTimer: Timer?
    @Environment(\.colorScheme) var colorScheme  // Add color scheme detection
    
    private let longPressDuration: Double = 2.0 // Duration for long press to complete
    
    var body: some View {
        HStack(spacing: 12) {
            // Hobby icon instead of color circle
            Image(systemName: getHobbyIcon())
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(selectedTextColor)
                .frame(width: 20, height: 20)
            
            // Hobby name only (no total time)
            Text(hobby.name)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(selectedTextColor)
                .lineLimit(1)
            
            Spacer()
            
            // Trash icon (shows when selected or hovering)
            if showDeleteIcon {
                Image(systemName: "trash.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(trashIconColor)
                    .frame(width: 16, height: 16)
                    .gesture(longPressGesture)  // EXACT same as HoldButton
                    .onChange(of: isPressing) { handlePressChange() }  // EXACT same as HoldButton
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
        )
        .overlay(progressOverlay)  // EXACT same pattern as HoldButton
        .onHover { hovering in
            isHovered = hovering
            withAnimation(.easeInOut(duration: 0.2)) {
                showDeleteIcon = hovering || isSelected
            }
        }
        .onChange(of: isSelected) { selected in
            withAnimation(.easeInOut(duration: 0.2)) {
                showDeleteIcon = selected || isHovered
            }
        }
    }
    
    // EXACT same overlay pattern as HoldButton
    private var progressOverlay: some View {
        RoundedRectangle(cornerRadius: 8)
            .trim(from: 0, to: deleteProgress)
            .stroke(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 161/255, green: 0/255, blue: 63/255),
                        Color(red: 230/255, green: 61/255, blue: 66/255),
                        Color(red: 255/255, green: 127/255, blue: 79/255)
                    ]),
                    startPoint: .trailing,
                    endPoint: .leading
                ),
                lineWidth: deleteProgress == 1.2 ? 0 : 2
            )
            .shadow(color: Color.red.opacity(0.5), radius: 10, x: 0, y: 0)
            .animation(.easeInOut, value: deleteProgress)
    }
    
    // EXACT same gesture as HoldButton
    private var longPressGesture: some Gesture {
        LongPressGesture(minimumDuration: 5.0)  // Set longer than animation duration like HoldButton
            .updating($isPressing) { currentState, gestureState, _ in
                gestureState = currentState
            }
    }
    
    // EXACT same function as HoldButton
    private func handlePressChange() {
        if isPressing {
            moveProgress()
        } else if deleteProgress < 1.2 {
            resetProgress()
        }
    }
    
    // EXACT same function as HoldButton
    private func moveProgress() {
        invalidateTimer()
        deleteProgress = 0.0
        print("🟥 Starting delete animation - moveProgress called")
        
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
            if isPressing && deleteProgress < 1.2 {
                DispatchQueue.main.async {
                    withAnimation(.easeInOut) {
                        deleteProgress += 0.01  // EXACT same increment as HoldButton
                    }
                    print("📊 Delete progress: \(deleteProgress)")
                }
            } else {
                deleteProgress = min(deleteProgress, 1.2)  // EXACT same as HoldButton
                progressTimer?.invalidate()
                print("⚠️ Timer stopped - isPressing: \(isPressing), progress: \(deleteProgress)")
                if deleteProgress >= 1.2 {
                    print("🎯 Progress reached 1.2 - calling performDeletion")
                    performDeletion()  // Our version of performCompletionAnimation
                }
            }
        }
    }
    
    // EXACT same function as HoldButton
    private func resetProgress() {
        invalidateTimer()
        print("❌ Reset progress called")
        DispatchQueue.main.async {
            withAnimation(.easeInOut) {
                deleteProgress = 0.0
            }
        }
    }
    
    // Our version of performCompletionAnimation
    private func performDeletion() {
        print("🗑️ Delete animation completed - deleting hobby: \(hobby.name)")
        hobbyManager.deleteHobby(hobby)
        // Reset state
        deleteProgress = 0.0
        print("✅ Hobby deletion completed")
    }
    
    // EXACT same function as HoldButton
    private func invalidateTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Color.primary.opacity(0.1)
        } else if isHovered {
            return Color.primary.opacity(0.1)
        } else {
            return Color.clear
        }
    }
    
    // Adaptive text color for selected state
    private var selectedTextColor: Color {
        if isSelected {
            return colorScheme == .dark ? .white : Color.primary
        } else {
            return .primary
        }
    }
    
    // Adaptive trash icon color
    private var trashIconColor: Color {
        if isPressing {
            return colorScheme == .dark ? .white : Color.primary
        } else if isSelected {
            return colorScheme == .dark ? .white : Color.primary
        } else {
            return .secondary
        }
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

// Extension to create Color from hex string

struct HobbyRowView_Previews: PreviewProvider {
    static var previews: some View {
        HobbyRowView(
            hobby: Hobby(name: "Guitar", description: "Learning acoustic guitar", color: "#FF6B6B"),
            isSelected: false,
            hobbyManager: HobbyManager()
        )
        .padding()
    }
} 
