//
//  SyncService.swift
//  DONE
//
//  Created by Dmytro Hannotskyi on 2026-02-04.
//

import SwiftUI
import CoreData
import FirebaseFirestore
import FirebaseAuth

class SyncService {
    static let shared = SyncService()
    private let db = Firestore.firestore()
    
    // MARK: - Load Data (Login)
    func loadUserData(context: NSManagedObjectContext, completion: @escaping () -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        wipeCoreData(context: context)
        
        db.collection("users").document(uid).collection("todos").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else {
                print("No documents found or error: \(error?.localizedDescription ?? "")")
                completion()
                return
            }
            
            context.perform {
                for doc in documents {
                    let data = doc.data()
                    let todo = Todo(context: context)
                    todo.id = UUID(uuidString: doc.documentID) ?? UUID()
                    todo.title = data["title"] as? String ?? ""
                    todo.isDone = data["isDone"] as? Bool ?? false
                    todo.isUrgent = data["isUrgent"] as? Bool ?? false
                    
                    if let timestamp = data["createdAt"] as? Timestamp {
                        todo.createdAt = timestamp.dateValue()
                    }
                    // Add other fields (lat, long) here if needed
                }
                
                try? context.save()
                
                DispatchQueue.main.async {
                    print("Synced \(documents.count) items from Cloud")
                    completion()
                }
            }
        }
    }
    
    // MARK: - Save Item (Add/Edit)
    func saveToFirestore(_ todo: Todo) {
        guard let uid = Auth.auth().currentUser?.uid,
              let id = todo.id?.uuidString else { return }
        
        let data: [String: Any] = [
            // Basic Info
            "title": todo.title ?? "",
            "desc": todo.desc ?? "",
            "isDone": todo.isDone,
            "isUrgent": todo.isUrgent,
            "createdAt": todo.createdAt ?? Date(),
            "doneAt": todo.doneAt ?? NSNull(),
            
            // Dates
            "dueDate": todo.dueDate ?? NSNull(),
            "reminderDate": todo.reminderDate ?? NSNull(),
            "hasTime": todo.hasTime,
            
            // Location
            "hasLocation": todo.hasLocation,
            "address": todo.address ?? "",
            "radius": todo.radius,
            "latitude": todo.hasLocation ? todo.latitude : NSNull(),
            "longitude": todo.hasLocation ? todo.longitude : NSNull(),
            
            
            "notifyOnEntry": todo.notifyOnEntry,
            "notifyOnExit": todo.notifyOnExit
        ]
        
        db.collection("users").document(uid).collection("todos").document(id).setData(data) { error in
            if let error = error {
                print("Error uploading: \(error.localizedDescription)")
            } else {
                print("Uploaded: \(todo.title ?? "Item")")
            }
        }
    }
    
    // MARK: - Delete Item
    func deleteFromFirestore(_ todo: Todo) {
        guard let uid = Auth.auth().currentUser?.uid,
              let id = todo.id?.uuidString else { return }
        
        db.collection("users").document(uid).collection("todos").document(id).delete()
    }
    
    // MARK: - Wipe Data (Logout)
    func wipeCoreData(context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Todo.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
            print("Core Data WIPED")
        } catch {
            print("Failed to wipe data: \(error)")
        }
    }
    
    // MARK: - Bulk Upload
    func uploadAllLocalData(context: NSManagedObjectContext) {
        guard Auth.auth().currentUser?.uid != nil else {
            print("Cannot upload: No user logged in")
            return
        }
        
        let fetchRequest: NSFetchRequest<Todo> = Todo.fetchRequest()
        
        do {
            let allTodos = try context.fetch(fetchRequest)
            print("Starting upload of \(allTodos.count) items...")
            
            for todo in allTodos {
                saveToFirestore(todo)
            }
            
            print("Bulk upload command sent!")
        } catch {
            print("Failed to fetch local data: \(error.localizedDescription)")
        }
    }
}
