//
//  SignUpView.swift
//  DONE
//
//  Created by Dmytro Hannotskyi on 2026-02-04.
//

import SwiftUI

struct SignUpView: View {
    @Environment(\.managedObjectContext) var viewContext
    @EnvironmentObject var authVM: AuthenticationViewModel
        
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var localError = ""

    @FocusState private var focusedField: Field?
    enum Field {
        case email, password, confirm
    }
    
    var isFormNotEmpty: Bool {
        return !email.isEmpty && !password.isEmpty && !confirmPassword.isEmpty
    }
    var body: some View {
        VStack(spacing: 20) {

            Spacer()

            // MARK: - Header
            Text("Create Account")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // MARK: - Error Handling
            // Shows either Firebase error OR Local validation error
            if !authVM.errorMessage.isEmpty || !localError.isEmpty {
                Text(localError.isEmpty ? authVM.errorMessage : localError)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            

            // MARK: - Input Fields
            VStack(spacing: 15) {
                TextField("Email Address", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                
                PasswordField(
                    title: "Password",
                    text: $password,
                    focusBinding: $focusedField,
                    focusValue: .password
                )
                .submitLabel(.next)
                
                PasswordField(
                    title: "Confirm Password",
                    text: $confirmPassword,
                    focusBinding: $focusedField,
                    focusValue: .confirm
                )
                .submitLabel(.go)
            }
            .onSubmit {
                switch focusedField {
                case .email:
                    focusedField = .password
                case .password:
                    focusedField = .confirm
                case .confirm:
                    registerUser()
                default:
                    break
                }
            }
                        
            // MARK: - Sign Up Button
            Button(action: {
                registerUser()
            }) {
                Text("Sign Up")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormNotEmpty ? Color(.green) : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
            .disabled(!isFormNotEmpty)
            
            Spacer()
        }
        .padding(30)
    }
    
    // MARK: - Validation Logic
    private func registerUser() {

        localError = ""

        guard password == confirmPassword else {
            localError = "Passwords do not match."
            return
        }
        
        guard password.count >= 6 else {
            localError = "Password must be at least 6 characters."
            return
        }
        
        authVM.signUp(email: email, pass: password, context: viewContext)
    }
}
