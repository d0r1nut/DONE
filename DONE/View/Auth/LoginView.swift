//
//  LoginView.swift
//  DONE
//
//  Created by Dmytro Hannotskyi on 2026-02-04.
//

import SwiftUI

struct LoginView: View {
    
    @Environment(\.managedObjectContext) var viewContext
    @EnvironmentObject var authVM: AuthenticationViewModel
    
    @State private var email = ""
    @State private var password = ""
        
    @FocusState private var focusedField: Field?
    enum Field {
        case email, password
    }

    var body: some View {
        VStack(spacing: 20) {
            
            Spacer()

            // MARK: - Header
            Text("Welcome Back")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Sign in to continue")
                .foregroundColor(.gray)
                .padding(.bottom, 20)
            
            // Error Message
            if !authVM.errorMessage.isEmpty {
                Text(authVM.errorMessage)
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
                .submitLabel(.go)
            }
            .onSubmit {
                if focusedField == .email {
                    focusedField = .password
                } else {
                    authVM.signIn(email: email, pass: password, context: viewContext)
                }
            }
            
            // MARK: - Login Button
            Button(action: {
                authVM.signIn(email: email, pass: password, context: viewContext)
            }) {
                Text("Log In")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
            .disabled(email.isEmpty || password.isEmpty)
            
            Spacer()
            
            // MARK: - Navigation to Sign Up
            HStack {
                Text("Don't have an account?")
                    .foregroundColor(.gray)
                NavigationLink("Sign Up", destination: SignUpView())
                    .foregroundColor(.accentColor)
            }
        }
        .padding(30)
    }
}
