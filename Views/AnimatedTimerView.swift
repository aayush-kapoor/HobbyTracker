import SwiftUI

// MARK: - Enhanced Animated Timer (Optional Advanced Version)
struct AnimatedTimerView: View {
    let timeString: String
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(timeString.enumerated()), id: \.offset) { index, character in
                if character == ":" {
                    Text(":")
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .opacity(isActive ? 1.0 : 0.6)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isActive)
                } else {
                    Text(String(character))
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .contentTransition(.numericText())
                        .animation(.smooth(duration: 0.5), value: character)
                        .scaleEffect(isActive ? 1.0 : 0.95)
                        .animation(.easeInOut(duration: 0.3), value: isActive)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .scaleEffect(isActive ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: isActive)
    }
}

// MARK: - Pulsing Progress Ring (Optional)
struct PulsingProgressRing: View {
    let progress: Double
    let isActive: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.1), lineWidth: 3)
                .frame(width: 60, height: 60)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.black,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: progress)
            
            Circle()
                .fill(Color.black)
                .frame(width: 8, height: 8)
                .scaleEffect(isActive ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isActive)
        }
    }
}

struct AnimatedTimerView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            AnimatedTimerView(timeString: "1:23", isActive: true)
            AnimatedTimerView(timeString: "0:05", isActive: false)
            PulsingProgressRing(progress: 0.3, isActive: true)
        }
        .padding()
        .background(Color.white)
    }
} 
