import SwiftUI

struct SessionNotesView: View {
    @Binding var notes: String
    let onSave: () -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("How did your session go?")
                    .font(.headline)
                
                TextField("Add notes about your session (optional)", text: $notes, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(5...10)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Session Complete")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 400, height: 300)
        .background(Color.white)
    }
}

struct SessionNotesView_Previews: PreviewProvider {
    static var previews: some View {
        SessionNotesView(
            notes: .constant(""),
            onSave: {},
            onCancel: {}
        )
    }
} 
