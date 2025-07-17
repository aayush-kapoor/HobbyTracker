import Foundation
import SwiftUI
import Supabase
import GoogleSignIn
import GoogleSignInSwift

@MainActor
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var userProfile: UserProfile?
    @Published var isLoading = false
    
    private let supabase: SupabaseClient
    
    init() {
        print("🔑 AuthManager: Initializing...")
        // Use configuration file
        self.supabase = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.supabaseURL)!,
            supabaseKey: SupabaseConfig.supabaseAnonKey
        )
        print("🔑 AuthManager: Supabase client created with URL: \(SupabaseConfig.supabaseURL)")
        
        setupGoogleSignIn()
        checkAuthState()
    }
    
    private func setupGoogleSignIn() {
        print("🔑 AuthManager: Setting up Google Sign-In...")
        // Use configuration file
        let clientId = SupabaseConfig.googleClientID
        
        if clientId == "YOUR_GOOGLE_CLIENT_ID" {
            print("❌ AuthManager: Google Client ID not configured!")
            return
        }
        
        print("🔑 AuthManager: Using Google Client ID: \(clientId)")
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
        print("✅ AuthManager: Google Sign-In configuration complete")
    }
    
    func checkAuthState() {
        print("🔑 AuthManager: Checking authentication state...")
        Task {
            do {
                let session = try await supabase.auth.session
                print("✅ AuthManager: Found existing session for user: \(session.user.email ?? "unknown")")
                await MainActor.run {
                    self.currentUser = session.user
                    self.isAuthenticated = true
                    print("🔑 AuthManager: Set isAuthenticated = true")
                }
                // Fetch user profile after setting the current user
                await fetchUserProfile(user: session.user)
            } catch {
                print("❌ AuthManager: No existing session found: \(error)")
                await MainActor.run {
                    self.isAuthenticated = false
                    self.currentUser = nil
                    self.userProfile = nil
                    print("🔑 AuthManager: Set isAuthenticated = false")
                }
            }
        }
    }
    
    func signInWithGoogle() {
        print("🔑 AuthManager: Starting Google Sign-In...")
        Task { @MainActor in
            isLoading = true
            print("🔑 AuthManager: Set isLoading = true")
        }
        
        Task {
            do {
                print("🔑 AuthManager: Getting presenting window...")
                // For macOS, we need to use the presenting window
                guard let window = NSApplication.shared.windows.first else {
                    print("❌ AuthManager: No window found for presentation")
                    throw AuthError.noWindow
                }
                print("✅ AuthManager: Found presenting window")
                
                print("🔑 AuthManager: Calling GIDSignIn.signIn...")
                let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: window)
                print("✅ AuthManager: Google Sign-In successful for user: \(result.user.profile?.email ?? "unknown")")
                
                print("🔑 AuthManager: Extracting ID token...")
                guard let idToken = result.user.idToken?.tokenString else {
                    print("❌ AuthManager: No ID token received from Google")
                    throw AuthError.noIdToken
                }
                print("✅ AuthManager: ID token received (length: \(idToken.count))")
                
                print("🔑 AuthManager: Signing in to Supabase (nonce validation disabled)...")
                let session = try await supabase.auth.signInWithIdToken(
                    credentials: OpenIDConnectCredentials(
                        provider: .google,
                        idToken: idToken
                    )
                )
                print("✅ AuthManager: Supabase sign-in successful for user: \(session.user.email ?? "unknown")")
                
                await MainActor.run {
                    self.currentUser = session.user
                    self.isAuthenticated = true
                    self.isLoading = false
                    print("🔑 AuthManager: Updated state - isAuthenticated = true, isLoading = false")
                }
                
                await fetchUserProfile(user: session.user)
                print("✅ AuthManager: Complete sign-in flow finished successfully")
                
            } catch {
                print("❌ AuthManager: Sign in error: \(error)")
                if let urlError = error as? URLError {
                    print("❌ AuthManager: URLError code: \(urlError.code), description: \(urlError.localizedDescription)")
                }
                await MainActor.run {
                    self.isLoading = false
                    print("🔑 AuthManager: Set isLoading = false due to error")
                }
            }
        }
    }
    
    func signOut() {
        print("🔑 AuthManager: Starting sign out...")
        Task {
            do {
                try await supabase.auth.signOut()
                GIDSignIn.sharedInstance.signOut()
                
                await MainActor.run {
                    self.isAuthenticated = false
                    self.currentUser = nil
                    self.userProfile = nil
                    print("🔑 AuthManager: Sign out complete - isAuthenticated = false")
                }
            } catch {
                print("❌ AuthManager: Sign out error: \(error)")
            }
        }
    }
    
    private func fetchUserProfile(user: User) async {
        print("🔑 AuthManager: Fetching user profile...")
        await MainActor.run {
            // Safely extract metadata
            let fullName = (user.userMetadata["full_name"] as? String) ?? user.email ?? ""
            let avatarURL = user.userMetadata["avatar_url"] as? String
            
            self.userProfile = UserProfile(
                id: user.id.uuidString,
                email: user.email ?? "",
                name: fullName,
                avatarURL: avatarURL
            )
            print("✅ AuthManager: User profile created for: \(fullName) (\(user.email ?? "no email"))")
        }
    }
}

struct UserProfile {
    let id: String
    let email: String
    let name: String
    let avatarURL: String?
}

enum AuthError: Error {
    case noIdToken
    case noWindow
    case noConfiguration
    case noAccessToken
} 