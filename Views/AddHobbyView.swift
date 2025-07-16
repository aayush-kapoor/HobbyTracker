import SwiftUI

struct AddHobbyView: View {
    @ObservedObject var hobbyManager: HobbyManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @FocusState private var isTextFieldFocused: Bool
    
    private let colors = [
        "#007AFF", "#FF6B6B", "#4ECDC4", "#45B7D1",
        "#96CEB4", "#FECA57", "#FF9FF3", "#54A0FF"
    ]
    
    var body: some View {
        VStack(spacing: 30) {
            // Title
            Text("Add New Hobby")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            // Input field
            VStack(alignment: .leading, spacing: 8) {
                
                TextField("Enter hobby name", text: $name)
                    .font(.system(size: 20, weight: .bold))
                    .textFieldStyle(.plain)
                    .padding(16)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
                    .focused($isTextFieldFocused)
            }
            
            Spacer()
            
            // Buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                
                Button("Save") {
                    let randomColor = colors.randomElement() ?? "#007AFF"
                    let hobby = Hobby(name: name.trimmingCharacters(in: .whitespacesAndNewlines), 
                                    description: "", 
                                    color: randomColor)
                    hobbyManager.addHobby(hobby)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(40)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            isTextFieldFocused = true
        }
    }
}

struct AddHobbyView_Previews: PreviewProvider {
    static var previews: some View {
        AddHobbyView(hobbyManager: HobbyManager())
    }
} 
