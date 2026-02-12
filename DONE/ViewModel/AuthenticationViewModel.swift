//
//  AuthenticationViewModel.swift
//  DONE
//
//  Created by Dmytro Hannotskyi on 2026-02-04.
//

import SwiftUI
import Combine
import FirebaseAuth
import CoreData

class AuthenticationViewModel: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var errorMessage = ""
    
    private var handle: AuthStateDidChangeListenerHandle?

    init() {
        self.handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.userSession = user
        }
    }
    
    deinit {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Sign In
    func signIn(email: String, pass: String, context: NSManagedObjectContext) {
        self.errorMessage = ""
        Auth.auth().signIn(withEmail: email, password: pass) { [weak self] result, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
            } else {
                SyncService.shared.loadUserData(context: context) {
                    print("Data loaded, ready to go.")
                }
            }
        }
    }

    // MARK: - Sign Up
    func signUp(email: String, pass: String, context: NSManagedObjectContext) {
        self.errorMessage = ""
        Auth.auth().createUser(withEmail: email, password: pass) { [weak self] result, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                return
            }
            
            DispatchQueue.main.async {
                SyncService.shared.wipeCoreData(context: context)
                self?.userSession = result?.user
            }
        }
    }
    
    // MARK: - Sign Out
    func signOut(context: NSManagedObjectContext) {
        self.errorMessage = ""
        do {
            SyncService.shared.wipeCoreData(context: context)
            try Auth.auth().signOut()
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
