import SwiftUI
import GoogleSignInSwift

struct LoginView: View {
    @ObservedObject var authManager: AuthManager
    
    var body: some View {
        ZStack {
            // Dark background
            Color(red: 0.15, green: 0.15, blue: 0.15)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 32) {
                    // App Icon and Title Section
                    VStack(spacing: 24) {
                        // App Icon (using a clock icon as placeholder)
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.25, green: 0.25, blue: 0.25))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "clock.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                        
                        // Welcome Text
                        VStack(spacing: 12) {
                            Text("Welcome to HobbyTracker")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Track your hobbies and time spent on them")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
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
                                // Google Logo (using G icon)
                                Text("G")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.primary)
                                    .frame(width: 24, height: 24)
                                    .background(Circle().fill(Color.white))
                                
                                Text("Sign in with Google")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color(red: 0.35, green: 0.35, blue: 0.35))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.borderless)
                        .disabled(authManager.isLoading)
                        
                        if authManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                    }
                }
                .frame(maxWidth: 400)
                .padding(.horizontal, 40)
                .padding(.vertical, 60)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                )
                
                Spacer()
            }
            .padding(.horizontal, 60)
        }
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