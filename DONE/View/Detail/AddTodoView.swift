//
//  AddTodoView.swift
//  DONE
//
//  Created by Dmytro Hannotskyi on 2026-02-04.
//

import SwiftUI
import CoreData
import CoreLocation
import UserNotifications

struct AddTodoView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var dateHolder: DateHolder
    @Environment(\.dismiss) var dismiss
    @State private var includeTime = false
    @State private var tempDeadlineDate = Date()
    @State private var tempReminderDate = Date()
    @State private var showDeadline: Bool = false
    @State private var showReminder: Bool = false
    
    // MARK: - Form States
    @State private var title: String = ""
    @State private var desc: String = ""
    @State private var isUrgent: Bool = false
    
    // Due Date Logic
    @State private var dueDate: Date? = nil
    @State private var reminderDate: Date? = nil
    
    // Location Logic
    @State private var includeLocation: Bool = false
    @State private var locationAddress: String = ""
    @State private var latitude: Double = 0.0
    @State private var longitude: Double = 0.0
    @State private var notifyOnEntry: Bool = true // true = Arrive, false = Leave
    @State private var showLocationPicker = false
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Basic Info
                Section(header: Text("Todo Details")) {
                    TextField("Title", text: $title)
                        .onChange(of: title) { oldValue, newValue in
                            title = String(newValue.prefix(27))
                        }
                    
                    TextField("Description (Optional)", text: $desc, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // MARK: - Priority
                Section {
                    Toggle(isOn: $isUrgent) {
                        Label {
                            Text("Urgent")
                        } icon: {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(isUrgent ? .orange : .secondary)
                        }
                    }
                    .tint(.orange)
                }
                
                // MARK: - Deadline
                Section(header: Text("Timeline")) {
                    Toggle("Deadline", isOn: $showDeadline.animation())
                        .tint(.red)
                        .onChange(of: showDeadline) { _, isActive in
                            if isActive {
                                let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: Date()) ?? Date()
                                tempDeadlineDate = endOfDay
                                dueDate = endOfDay
                                includeTime = false
                            } else {
                                dueDate = nil
                            }
                        }
                    
                    // MARK: - Time
                    if showDeadline {
                        Toggle("Include Time", isOn: Binding(
                            get: { includeTime },
                            set: { wantsTime in
                                includeTime = wantsTime
                                if wantsTime {
                                    tempDeadlineDate = Date()
                                } else {
                                    tempDeadlineDate = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: tempDeadlineDate) ?? tempDeadlineDate
                                }
                                dueDate = tempDeadlineDate
                            }
                        ))
                        .tint(.red)
                        
                        // MARK: - DatePicker
                        DatePicker(
                            "Date",
                            selection: $tempDeadlineDate,
                            displayedComponents: includeTime ? [.date, .hourAndMinute] : [.date]
                        )
                        .datePickerStyle(.compact)
                        .id(includeTime)
                        .frame(height: 37)
                        .onChange(of: tempDeadlineDate) { _, newDate in
                            if !includeTime {
                                let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: newDate) ?? newDate
                                dueDate = endOfDay
                            } else {
                                dueDate = newDate
                            }
                        }
                        .onAppear {
                            if let savedDate = dueDate {
                                tempDeadlineDate = savedDate
                            }
                        }
                    }
                }
                .onAppear {
                    showDeadline = dueDate != nil
                }
                
                // MARK: - Notification Reminder
                Section(header: Text("Notification")) {
                    Toggle("Remind Me", isOn: $showReminder.animation())
                        .tint(.indigo)
                        .onChange(of: showReminder) { _, isActive in
                            if isActive {
                                let defaultTime = Date().addingTimeInterval(60)
                                tempReminderDate = defaultTime
                                reminderDate = defaultTime
                                requestNotificationPermission()
                            } else {
                                reminderDate = nil
                            }
                        }
                    
                    // MARK: - DatePicker
                    if showReminder {
                        DatePicker(
                            "At",
                            selection: $tempReminderDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.compact)
                        .frame(height: 37)
                        .onChange(of: tempReminderDate) { _, newDate in
                            reminderDate = newDate
                        }
                        .onAppear {
                            if let savedDate = reminderDate {
                                tempReminderDate = savedDate
                            }
                        }
                        
                        Text(tempReminderDate < Date() ? "Time passed" : "Scheduled for \(tempReminderDate.formatted())")
                            .font(.caption)
                            .foregroundColor(tempReminderDate < Date() ? .red : .secondary)
                    }
                }
                .onAppear {
                    showReminder = reminderDate != nil
                }
                
                // MARK: - Location
                Section(header: Text("Location")) {
                    Toggle("Remind at Location", isOn: $includeLocation.animation())
                        .tint(.blue)

                    if includeLocation {
                        Button(action: { showLocationPicker = true }) {
                            HStack {
                                Image(systemName: locationAddress.isEmpty ? "mappin.circle" : "mappin.circle.fill")
                                    .foregroundColor(.red)
                                
                                if locationAddress.isEmpty {
                                    Text("Select Location")
                                        .foregroundColor(.blue)
                                } else {
                                    Text(locationAddress)
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                }
                            }
                        }
                        
                        if !locationAddress.isEmpty {
                            Picker("Trigger", selection: $notifyOnEntry) {
                                Text("On Arrival").tag(true)
                                Text("On Departure").tag(false)
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                }
            }
            .navigationTitle("New Todo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTodo()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .navigationDestination(isPresented: $showLocationPicker) {
                LocationPickerView(
                    selectedAddress: $locationAddress,
                    selectedLat: $latitude,
                    selectedLong: $longitude,
                    onConfirm: { showLocationPicker = false }
                )
            }
        }
    }
    
    // MARK: - Save Logic
    private func saveTodo() {
        let newTodo = Todo(context: viewContext)
        newTodo.id = UUID()
        newTodo.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        newTodo.desc = desc
        newTodo.isUrgent = isUrgent
        newTodo.isDone = false
        newTodo.createdAt = Date()
        
        newTodo.dueDate = dueDate
        newTodo.hasTime = includeTime
        newTodo.reminderDate = reminderDate
        
        newTodo.hasLocation = includeLocation
        if includeLocation {
            newTodo.address = locationAddress
            newTodo.latitude = latitude
            newTodo.longitude = longitude
            newTodo.notifyOnEntry = notifyOnEntry
            newTodo.notifyOnExit = !notifyOnEntry
            newTodo.radius = 100.0
        }
    
        dateHolder.saveContext(viewContext)
        SyncService.shared.saveToFirestore(newTodo)
        
        scheduleNotification(for: newTodo)
        
        dismiss()
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success { print("Notification Permission Granted") }
        }
    }
    
    private func scheduleNotification(for todo: Todo) {
            let center = UNUserNotificationCenter.current()
            
            let timeIdentifier = (todo.id?.uuidString ?? UUID().uuidString) + "-time"
            let locIdentifier = (todo.id?.uuidString ?? UUID().uuidString) + "-location"
            
            print("\n--- NOTIFICATION DEBUGGER (ADD) ---")
            print("Target Item ID: \(todo.id?.uuidString ?? "Unknown")")
            print("Action: Deleting old pending notifications...")
            
            center.removePendingNotificationRequests(withIdentifiers: [timeIdentifier, locIdentifier])
            
            // Check authorization
            center.getNotificationSettings { settings in
                print("Permission Status: \(settings.authorizationStatus.rawValue)")
            }
            
            // MARK: - Schedule Time Notification
            if let reminderDate = todo.reminderDate, reminderDate > Date() {
                print("Action: Scheduling TIME notification for \(reminderDate.formatted())")
                
                let content = UNMutableNotificationContent()
                content.title = todo.title ?? "Todo Reminder"
                content.body = todo.desc ?? "You have a task due!"
                content.sound = .default
                
                let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(identifier: timeIdentifier, content: content, trigger: trigger)
                
                center.add(request) { error in
                    if let error = error {
                        print("   Error scheduling time: \(error)")
                    } else {
                        print("   Success: Time notification scheduled.")
                    }
                }
            } else {
                print("Action: Skipped Time notification (Date is nil or in past).")
            }
            
            // MARK: - Schedule Location Notification (Geofence)
            if todo.hasLocation, let address = todo.address, !address.isEmpty {
                print("Action: Scheduling LOCATION notification for \(address)")
                
                let centerCoordinate = CLLocationCoordinate2D(latitude: todo.latitude, longitude: todo.longitude)
                let region = CLCircularRegion(center: centerCoordinate, radius: 100.0, identifier: locIdentifier)
                
                region.notifyOnEntry = todo.notifyOnEntry
                region.notifyOnExit = todo.notifyOnExit
                
                let content = UNMutableNotificationContent()
                content.title = "Arrived at Location"
                content.body = "Don't forget: \(todo.title ?? "Task")"
                content.sound = .default
                
                let trigger = UNLocationNotificationTrigger(region: region, repeats: true)
                let request = UNNotificationRequest(identifier: locIdentifier, content: content, trigger: trigger)
                
                center.add(request) { error in
                    if let error = error {
                        print("   Error scheduling geofence: \(error)")
                    } else {
                        print("   Success: Location notification scheduled.")
                    }
                }
            }
            
            // List pending
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                center.getPendingNotificationRequests { requests in
                    print("\n--- CURRENT PENDING LIST ---")
                    print("Total Pending: \(requests.count)")
                    for request in requests {
                        print("   ID: \(request.identifier)")
                    }
                    print("----------------------------\n")
                }
            }
        }
}
