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
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct HobbyRowView_Previews: PreviewProvider {
    static var previews: some View {
        HobbyRowView(
            hobby: Hobby(name: "Guitar", description: "Learning acoustic guitar", color: "#FF6B6B"),
            isSelected: false
        )
        .padding()
    }
} 
