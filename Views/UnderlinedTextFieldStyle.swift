import SwiftUI

struct UnderlinedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .textFieldStyle(.plain)
            .padding(.vertical, 8)
            .background(Color.clear)
            .overlay(
                VStack {
                    Spacer()
                    Color(NSColor.systemGray)
                        .frame(height: 2)
                }
            )
    }
} 
