import SwiftUI

struct ContentView: View {
    @StateObject private var hobbyManager = HobbyManager()
    @State private var showingAddHobby = false
    
    var body: some View {
        NavigationSplitView {
            // Sidebar with hobbies list
            List(hobbyManager.hobbies) { hobby in
                HobbyRowView(hobby: hobby, isSelected: hobbyManager.selectedHobby?.id == hobby.id ? true : false)
                    .onTapGesture {
                        hobbyManager.selectHobby(hobby)
                    }
                    .listRowBackground(Color(NSColor.windowBackgroundColor))
                    .listRowSeparator(.hidden)
            }
            .navigationTitle("Hobbies")
            .background(Color(NSColor.windowBackgroundColor))
            .scrollContentBackground(.hidden)
            .safeAreaInset(edge: .bottom) {
                Button(action: { showingAddHobby.toggle() }) {
                    HStack {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .medium))
                        Text("Add Hobby")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.primary.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(.borderless)
                .padding(.horizontal, 12)
                .padding(.bottom, 25)
            }
            .sheet(isPresented: $showingAddHobby) {
                AddHobbyView(hobbyManager: hobbyManager)
            }
        } detail: {
            // Main detail view
            if let selectedHobby = hobbyManager.selectedHobby {
                HobbyDetailView(hobby: selectedHobby, hobbyManager: hobbyManager)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.leading, 8)
                    .padding(.vertical, 8)
            } else {
                VStack {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("Select a hobby to start tracking")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.windowBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.leading, 8)
                .padding(.vertical, 8)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 800, minHeight: 600)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 
