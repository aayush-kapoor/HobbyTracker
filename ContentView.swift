import SwiftUI

struct ContentView: View {
    @StateObject private var hobbyManager = HobbyManager()
    @State private var showingAddHobby = false
    
    var body: some View {
        NavigationSplitView {
            // Sidebar with hobbies list
            List(hobbyManager.hobbies) { hobby in
                HobbyRowView(hobby: hobby)
                    .onTapGesture {
                        hobbyManager.selectHobby(hobby)
                    }
                    .listRowBackground(Color.white)
            }
            .navigationTitle("Hobbies")
            .background(Color.white)
            .scrollContentBackground(.hidden)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddHobby.toggle() }) {
                        Image(systemName: "plus")
                            .foregroundColor(.black)
                    }
                }
            }
            .sheet(isPresented: $showingAddHobby) {
                AddHobbyView(hobbyManager: hobbyManager)
            }
        } detail: {
            // Main detail view
            if let selectedHobby = hobbyManager.selectedHobby {
                HobbyDetailView(hobby: selectedHobby, hobbyManager: hobbyManager)
            } else {
                VStack {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("Select a hobby to start tracking")
                        .font(.custom("Roboto Flex", size: 20).weight(.bold))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .background(Color.white)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 
