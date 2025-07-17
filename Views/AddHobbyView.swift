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
//            Text("Add New Hobby")
//                .font(.system(size: 24, weight: .bold))
//                .foregroundColor(.primary)
//            
            // Input field
            VStack(alignment: .leading, spacing: 8) {
                TextField("Enter hobby name", text: $name)
                    .font(.system(size: 20, weight: .regular))
                    .textFieldStyle(UnderlinedTextFieldStyle())
                    .focused($isTextFieldFocused)
            }
            
            Spacer()
            
            // Buttons
            HStack(spacing: 20) {
                Button("Cancel") {
                    dismiss()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(Color.primary.opacity(0.1))
                .cornerRadius(12)
                .buttonStyle(.plain)
                
                Button("Save") {
                    let randomColor = colors.randomElement() ?? "#007AFF"
                    let hobby = Hobby(name: name.trimmingCharacters(in: .whitespacesAndNewlines), 
                                    description: "", 
                                    color: randomColor)
                    hobbyManager.addHobby(hobby)
                    dismiss()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(
                    name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty 
                    ? Color.gray 
                    : Color(hex: "#FFD5E6")
                )
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(
                    name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty 
                    ? Color.gray.opacity(0.2)
                    : Color(hex: "#3F162A")
                )
                .cornerRadius(12)
                .buttonStyle(.plain)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 20)
        }
        .frame(width: 450, height: 300)
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
