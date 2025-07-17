import SwiftUI
import GoogleSignIn

@main
struct HobbyTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
        .windowStyle(DefaultWindowStyle())
        .windowResizability(.contentSize)
    }
} 
