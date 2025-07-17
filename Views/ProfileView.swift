import SwiftUI

struct ProfileView: View {
    @ObservedObject var authManager: AuthManager
    @State private var showingAccountMenu = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Picture
            AsyncImage(url: URL(string: authManager.userProfile?.avatarURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                // Fallback to initials
                ZStack {
                    Circle()
                        .fill(Color.blue)
                    
                    Text(initials)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())
            
            // User Info
            VStack(alignment: .leading, spacing: 2) {
                Text(authManager.userProfile?.name ?? "User")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(authManager.userProfile?.email ?? "")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Menu Button
            Button(action: {
                showingAccountMenu.toggle()
            }) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.borderless)
            .popover(isPresented: $showingAccountMenu, arrowEdge: .top) {
                VStack(alignment: .leading, spacing: 0) {
                    Button(action: {
                        showingAccountMenu = false
                        authManager.signOut()
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 14))
                            Text("Sign Out")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderless)
                }
                .frame(minWidth: 120)
                .background(Color(NSColor.windowBackgroundColor))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(0.05))
        .cornerRadius(8)
    }
    
    private var initials: String {
        let name = authManager.userProfile?.name ?? "U"
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        } else {
            return String(name.prefix(2)).uppercased()
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(authManager: AuthManager())
            .frame(width: 250)
    }
} 