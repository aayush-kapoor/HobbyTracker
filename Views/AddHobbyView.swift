import SwiftUI

struct AddHobbyView: View {
    @ObservedObject var hobbyManager: HobbyManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var selectedColor = "#007AFF"
    
    private let colors = [
        "#007AFF", "#FF6B6B", "#4ECDC4", "#45B7D1",
        "#96CEB4", "#FECA57", "#FF9FF3", "#54A0FF",
        "#5F27CD", "#00D2D3", "#FF9F43", "#EE5A24"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Hobby Details") {
                    TextField("Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 2)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                }
            }
            .navigationTitle("New Hobby")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let hobby = Hobby(name: name, description: description, color: selectedColor)
                        hobbyManager.addHobby(hobby)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .frame(width: 400, height: 500)
        .background(Color.white)
    }
}

struct AddHobbyView_Previews: PreviewProvider {
    static var previews: some View {
        AddHobbyView(hobbyManager: HobbyManager())
    }
} 
