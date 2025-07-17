import SwiftUI
import GoogleSignInSwift
import FluidGradient

struct LoginView: View {
    @ObservedObject var authManager: AuthManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // FluidGradient background with light shades
            FluidGradient(blobs: [.red.opacity(0.3), .green.opacity(0.3), .blue.opacity(0.3)],
                         speed: 0.25,
                         blur: 0.75)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 32) {
                    // Welcome Text Section
                    VStack(spacing: 12) {
                        Text("Welcome to HobbyTracker!")
                            .font(.system(size: 25, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Track your hobbies and time spent on them")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    
                    // Sign in section
                    VStack(spacing: 20) {
                        // Google Sign In Button
                        Button(action: {
                            print("🔘 LoginView: Google Sign-In button pressed")
                            print("🔘 LoginView: Current auth state - isAuthenticated: \(authManager.isAuthenticated), isLoading: \(authManager.isLoading)")
                            authManager.signInWithGoogle()
                        }) {
                            HStack(spacing: 12) {
                                // Google Logo - Replace this with your custom icon
                                // Option 1: Custom image from Assets (recommended)
                                Image("google-icon") // Place your Google icon in Assets.xcassets with this name
                                    .resizable()
                                    .frame(width: 28, height: 28) // Larger icon
                                
                                // Option 2: If you want to keep the text version temporarily
                                // Text("G")
                                //     .font(.system(size: 20, weight: .bold))
                                //     .foregroundColor(.primary)
                                //     .frame(width: 28, height: 28)
                                //     .background(Circle().fill(Color.white))
                                
                                Text("Sign in with Google")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: 220) // Reduced button width
                            .frame(height: 44) // Reduced button height
                            .background(colorScheme == .dark ? Color.gray.opacity(0.15) : Color.gray.opacity(0.25)) // Dark grey for dark mode, white for light mode
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(.borderless)
                        .disabled(authManager.isLoading)
                        
                        if authManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                                .scaleEffect(0.8)
                        }
                    }
                }
                .frame(maxWidth: 400)
                .padding(.horizontal, 40)
                .padding(.vertical, 60)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(colorScheme == .dark ? Color.black.opacity(0.7) : Color.white.opacity(0.75)) // Semi-transparent for both modes
                        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                )
                
                Spacer()
            }
            .padding(.horizontal, 60)
        }
        // .preferredColorScheme(.light) // Force light mode for login page only
        .onAppear {
            print("🔘 LoginView: Appeared with auth state - isAuthenticated: \(authManager.isAuthenticated), isLoading: \(authManager.isLoading)")
        }
        .onReceive(authManager.$isAuthenticated) { isAuthenticated in
            print("🔘 LoginView: Received authentication state change: \(isAuthenticated)")
        }
        .onReceive(authManager.$isLoading) { isLoading in
            print("🔘 LoginView: Received loading state change: \(isLoading)")
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(authManager: AuthManager())
    }
} 
