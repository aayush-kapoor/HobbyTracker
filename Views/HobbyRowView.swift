import SwiftUI

struct HobbyRowView: View {
    let hobby: Hobby
    let isSelected: Bool
    @State private var isHovered: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Hobby icon instead of color circle
            Image(systemName: getHobbyIcon())
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(width: 20, height: 20)
            
            // Hobby name only (no total time)
            Text(hobby.name)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
        )
        .onHover { hovering in
            isHovered = hovering
        }
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
            isSelected: false
        )
        .padding()
    }
} 
