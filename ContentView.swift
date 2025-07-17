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
            // Main detail view with carousel
            if hobbyManager.hobbies.isEmpty {
                VStack {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("Add a hobby to start tracking")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.windowBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.leading, 8)
                .padding(.vertical, 8)
            } else {
                HobbyCarouselView(hobbyManager: hobbyManager)
                    .onAppear {
                        // Ensure a hobby is selected when the view appears
                        if hobbyManager.selectedHobby == nil && !hobbyManager.hobbies.isEmpty {
                            hobbyManager.selectHobby(hobbyManager.hobbies[0])
                        }
                    }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 800, minHeight: 600)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Custom Carousel for macOS
struct HobbyCarouselView: View {
    @ObservedObject var hobbyManager: HobbyManager
    @State private var dragOffset: CGFloat = 0
    @State private var currentIndex: Int = 0
    
    var body: some View {
        GeometryReader { geometry in
            let cardWidth = geometry.size.width
            
            HStack(spacing: 0) {
                ForEach(Array(hobbyManager.hobbies.enumerated()), id: \.element.id) { index, hobby in
                    HobbyDetailView(hobby: hobby, hobbyManager: hobbyManager)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.leading, 8)
                        .padding(.vertical, 8)
                        .frame(width: cardWidth)
                }
            }
            .offset(x: -CGFloat(currentIndex) * cardWidth + dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        let threshold: CGFloat = cardWidth * 0.25
                        let dragDistance = value.translation.width
                        
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
                            if dragDistance > threshold {
                                // Swipe right - go to previous hobby
                                if currentIndex > 0 {
                                    currentIndex -= 1
                                    hobbyManager.selectHobbyAtIndex(currentIndex)
                                }
                            } else if dragDistance < -threshold {
                                // Swipe left - go to next hobby
                                if currentIndex < hobbyManager.hobbies.count - 1 {
                                    currentIndex += 1
                                    hobbyManager.selectHobbyAtIndex(currentIndex)
                                }
                            }
                            dragOffset = 0
                        }
                    }
            )
            .animation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0), value: currentIndex)
        }
        .clipped()
        .onReceive(hobbyManager.$selectedHobby) { selectedHobby in
            // Sync carousel position when hobby is selected from sidebar
            if let newIndex = hobbyManager.selectedHobbyIndex(), newIndex != currentIndex {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
                    currentIndex = newIndex
                }
            }
        }
        .onAppear {
            // Initialize current index
            currentIndex = hobbyManager.selectedHobbyIndex() ?? 0
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 
