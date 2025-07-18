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
        // Use configuration file
        self.supabase = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.supabaseURL)!,
            supabaseKey: SupabaseConfig.supabaseAnonKey
        )
        
        setupGoogleSignIn()
        checkAuthState()
    }
    
    private func setupGoogleSignIn() {
        // Use configuration file
        let clientId = SupabaseConfig.googleClientID
        
        if clientId == "YOUR_GOOGLE_CLIENT_ID" {
            print("❌ AuthManager: Google Client ID not configured!")
            return
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
    }
    
    func checkAuthState() {
        Task {
            do {
                let session = try await supabase.auth.session
                await MainActor.run {
                    self.currentUser = session.user
                    self.userProfile = self.createUserProfile(from: session.user)
                    self.isAuthenticated = true
                }
            } catch {
                await MainActor.run {
                    self.currentUser = nil
                    self.userProfile = nil
                    self.isAuthenticated = false
                }
            }
        }
    }
    
    func signInWithGoogle() {
        Task { @MainActor in
            isLoading = true
        }
        
        Task {
            do {
                // For macOS, we need to use the presenting window
                guard let window = NSApplication.shared.windows.first else {
                    throw AuthError.noWindow
                }
                
                let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: window)
                
                guard let idToken = result.user.idToken?.tokenString else {
                    print("❌ AuthManager: No ID token received from Google")
                    throw AuthError.noIdToken
                }
                
                let session = try await supabase.auth.signInWithIdToken(
                    credentials: OpenIDConnectCredentials(
                        provider: .google,
                        idToken: idToken
                    )
                )
                
                await MainActor.run {
                    self.currentUser = session.user
                    self.isAuthenticated = true
                    self.isLoading = false
                }
                
                await fetchUserProfile(user: session.user)
                
            } catch {
                print("❌ AuthManager: Sign in error: \(error)")
                if let urlError = error as? URLError {
                    print("❌ AuthManager: URLError code: \(urlError.code), description: \(urlError.localizedDescription)")
                }
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    func signOut() {
        Task {
            do {
                try await supabase.auth.signOut()
                GIDSignIn.sharedInstance.signOut()
                
                await MainActor.run {
                    self.isAuthenticated = false
                    self.currentUser = nil
                    self.userProfile = nil
                }
            } catch {
                print("❌ AuthManager: Sign out error: \(error)")
            }
        }
    }
    
    private func fetchUserProfile(user: User) async {
        await MainActor.run {
            self.userProfile = self.createUserProfile(from: user)
        }
    }
    
    private func createUserProfile(from user: User) -> UserProfile {
        // Extract full name from metadata, fallback to email
        let fullName: String
        if let fullNameJSON = user.userMetadata["full_name"] {
            fullName = fullNameJSON.stringValue ?? user.email ?? ""
        } else {
            fullName = user.email ?? ""
        }
        
        // Extract avatar URL from metadata
        let avatarURL: String?
        if let pictureJSON = user.userMetadata["picture"] {
            avatarURL = pictureJSON.stringValue
        } else {
            avatarURL = nil
        }
        
        return UserProfile(
            id: user.id.uuidString,
            email: user.email ?? "",
            name: fullName,
            avatarURL: avatarURL
        )
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
