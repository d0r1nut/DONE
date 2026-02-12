//
//  PasswordField.swift
//  DONE
//
//  Created by Dmytro Hannotskyi on 2026-02-04.
//

import SwiftUI

struct PasswordField<FocusType: Hashable>: View {
    var title: String
    @Binding var text: String

    var focusBinding: FocusState<FocusType?>.Binding
    var focusValue: FocusType
    
    @State private var isVisible = false

    var body: some View {
        HStack {
            if isVisible {
                TextField(title, text: $text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                    .focused(focusBinding, equals: focusValue)
            } else {
                SecureField(title, text: $text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.password)
                    .focused(focusBinding, equals: focusValue)
            }
        }
        .overlay(
            Button(action: { isVisible.toggle() }) {
                Image(systemName: isVisible ? "eye.slash" : "eye")
                    .foregroundColor(.gray)
            }
            .padding(.trailing, 8),
            alignment: .trailing
        )
    }
}
