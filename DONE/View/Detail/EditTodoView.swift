//
//  EditTodoView.swift
//  DONE
//
//  Created by Dmytro Hannotskyi on 2026-02-05.
//

import SwiftUI
import CoreData
import CoreLocation
import UserNotifications

struct EditTodoView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var todo: Todo
    
    @State private var includeTime = false
    @State private var tempDeadlineDate = Date()
    @State private var tempReminderDate = Date()
    @State private var showDeadline: Bool = false
    @State private var showReminder: Bool = false
    @State private var showLocationReminder: Bool = false
    @State private var showUrgent: Bool = false
    @State private var showDone: Bool = false
    @State private var tempAddress: String = ""
    @State private var tempLatitude: Double = 0.0
    @State private var tempLongitude: Double = 0.0
    
    // Location Logic
    @State private var showLocationPicker = false
    
    var body: some View {
        Form {
            // MARK: - Details
            Section(header: Text("Todo Details")) {
                TextField("Title", text: Binding(
                    get: { todo.title ?? "" },
                    set: { newValue in
                        todo.title = String(newValue.prefix(27))
                    }
                ))
                
                TextField("Add a description...",
                          text: Binding(
                            get: { todo.desc ?? "" },
                            set: { todo.desc = $0 }
                          ),
                          axis: .vertical
                )
                .lineLimit(3...6)
            }
            
            // MARK: - Deadline
            Section(header: Text("Timeline")) {
                Toggle("Deadline", isOn: $showDeadline.animation(.easeInOut))
                    .tint(.red)
                    .onChange(of: showDeadline) { _, isActive in
                        if isActive {
                            if todo.dueDate == nil {
                                let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: Date()) ?? Date()
                                tempDeadlineDate = endOfDay
                                todo.dueDate = endOfDay
                                includeTime = false
                            }
                        } else {
                            todo.dueDate = nil
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
                            todo.dueDate = tempDeadlineDate
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
                            todo.dueDate = endOfDay
                        } else {
                            todo.dueDate = newDate
                        }
                    }
                    .onAppear {
                        if let savedDate = todo.dueDate {
                            tempDeadlineDate = savedDate
                        }
                    }
                }
            }
            .onAppear {
                showDeadline = todo.dueDate != nil
            }
            
            // MARK: - Notification Reminder
            Section(header: Text("Notification")) {
                Toggle("Remind Me", isOn: $showReminder.animation(.easeInOut))
                    .tint(.indigo)
                    .onChange(of: showReminder) { _, isActive in
                        if isActive {
                            if todo.reminderDate == nil {
                                let defaultTime = Date().addingTimeInterval(60)
                                tempReminderDate = defaultTime
                                todo.reminderDate = defaultTime
                                requestNotificationPermission()
                            }
                        } else {
                            todo.reminderDate = nil
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
                        todo.reminderDate = newDate
                    }
                    .onAppear {
                        if let savedDate = todo.reminderDate {
                            tempReminderDate = savedDate
                        }
                    }
                    
                    Text(tempReminderDate < Date() ? "Time passed" : "Scheduled for \(tempReminderDate.formatted())")
                        .font(.caption)
                        .foregroundColor(tempReminderDate < Date() ? .red : .secondary)
                }
            }
            .onAppear {
                showReminder = todo.reminderDate != nil
            }
            
            // MARK: - Location
            Section(header: Text("Location")) {
                Toggle("Remind at Location", isOn: $showLocationReminder.animation(.easeInOut))
                    .tint(.blue)
                    .onChange(of: showLocationReminder) { _, newValue in
                        todo.hasLocation = newValue
                    }
                
                if (todo.hasLocation) {
                    Button(action: {
                        tempAddress = todo.address ?? ""
                        tempLatitude = todo.latitude
                        tempLongitude = todo.longitude
                        showLocationPicker = true
                    }) {
                        HStack {
                            let addressText = todo.address ?? ""
                            Image(systemName: addressText.isEmpty ? "mappin.circle" : "mappin.circle.fill")
                                .foregroundColor(.red)
                            
                            if addressText.isEmpty {
                                Text("Select Location")
                                    .foregroundColor(.blue)
                            } else {
                                Text(addressText)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .sheet(isPresented: $showLocationPicker) {
                        NavigationStack {
                            LocationPickerView(
                                selectedAddress: $tempAddress,
                                selectedLat: $tempLatitude,
                                selectedLong: $tempLongitude,
                                onConfirm: {
                                    todo.address = tempAddress.isEmpty ? nil : tempAddress
                                    todo.latitude = tempLatitude
                                    todo.longitude = tempLongitude
                                    
                                    print("Location Confirmed. Scheduling Notification...")
                                    scheduleNotification()
                                    showLocationPicker = false
                                }
                            )
                        }
                    }
                    
                    if !(todo.address ?? "").isEmpty {
                        Picker("Trigger", selection: Binding<Bool>(
                            get: { todo.notifyOnEntry },
                            set: { newValue in
                                todo.notifyOnEntry = newValue
                                todo.notifyOnExit = !newValue
                            }
                        )) {
                            Text("On Arrival").tag(true)
                            Text("On Departure").tag(false)
                        }
                        .pickerStyle(.segmented)
                    }
                }
            }
            
            
            // MARK: - Status
            Section(header: Text("Status")) {
                Toggle(isOn: $showUrgent) {
                    Label {
                        Text("Urgent")
                    } icon: {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(showUrgent ? .orange : .secondary)
                    }
                    
                }
                .tint(.orange)
                .onChange(of: showUrgent) { _, newValue in
                    todo.isUrgent = newValue
                }
                
                Toggle(isOn: $showDone) {
                    Label {
                        Text("Done")
                    } icon: {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(showDone ? .green : .secondary)
                    }
                }
                .onChange(of: showDone) { _, newValue in
                    todo.isDone = newValue
                    todo.doneAt = newValue ? Date() : nil
                }
            }
            
            // MARK: - Metadata
            Section(header: Text("Metadata")) {
                HStack {
                    Text("Created")
                    Spacer()
                    Text(todo.createdAt?.formatted(date: .abbreviated, time: .shortened) ?? "N/A")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Done")
                    Spacer()
                    Text(todo.doneAt?.formatted(date: .abbreviated, time: .shortened) ?? "Not Yet")
                        .foregroundStyle(todo.doneAt != nil ? .green : .secondary)
                }
            }
        }
        .navigationTitle("Edit Todo")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            showDeadline = todo.dueDate != nil
            showReminder = todo.reminderDate != nil
            showLocationReminder = todo.hasLocation
            showUrgent = todo.isUrgent
            showDone = todo.isDone
            
            if let savedDue = todo.dueDate {
                tempDeadlineDate = savedDue
                let components = Calendar.current.dateComponents([.hour, .minute], from: savedDue)
                if components.hour == 23 && components.minute == 59 {
                    includeTime = false
                } else {
                    includeTime = true
                }
            }
            
            if let savedRem = todo.reminderDate {
                tempReminderDate = savedRem
            }
        }
        .onDisappear {
            saveContext()
            if showReminder || showLocationReminder {
                scheduleNotification()
            }
        }
    }
    
    // MARK: - Logic
    private func saveContext() {
        do {
            if viewContext.hasChanges {
                try viewContext.save()
                SyncService.shared.saveToFirestore(todo)
            }
        } catch {
            print("Error saving context: \(error)")
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success { print("Notification Permission Granted") }
        }
    }
    
    private func scheduleNotification() {
            let center = UNUserNotificationCenter.current()
            
            let timeIdentifier = (todo.id?.uuidString ?? UUID().uuidString) + "-time"
            let locIdentifier = (todo.id?.uuidString ?? UUID().uuidString) + "-location"
            
            print("\n--- NOTIFICATION DEBUGGER (EDIT) ---")
            print("Target Item ID: \(todo.id?.uuidString ?? "Unknown")")
            print("Action: Deleting old pending notifications...")
            
            center.removePendingNotificationRequests(withIdentifiers: [timeIdentifier, locIdentifier])
            
            // Check authorization
            center.getNotificationSettings { settings in
                print("Permission Status: \(settings.authorizationStatus.rawValue)")
            }
            
            // MARK: - Schedule Time Notification
            // Check if reminder exists, item is NOT done, and date is in the future
            if let reminderDate = todo.reminderDate, !todo.isDone, reminderDate > Date() {
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
                print("Action: Skipped Time notification (Item done, no date, or date in past).")
            }
            
            // MARK: - Schedule Location Notification (Geofence)
            if todo.hasLocation, let address = todo.address, !address.isEmpty, !todo.isDone {
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
            } else {
                 print("Action: Skipped Location notification.")
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
        }}
