//
//  SettingsView.swift
//  DONE
//
//  Created by Dmytro Hannotskyi on 2026-02-04.
//

import SwiftUI

struct SettingsView: View {

    @AppStorage("useAdvancedCreation") private var useAdvancedCreation = false
    @Environment(\.managedObjectContext) var viewContext
    @AppStorage("listStyle") private var listStyle: String = "Automatic"

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("General")) {
                    Toggle("Use Advanced Creation", isOn: $useAdvancedCreation)
                    Text(useAdvancedCreation ? "Use the '+' button to add todos with locations and dates." : "Use the simple text field for quick todos.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Section(header: Text("List Appearance")) {
                    Picker("", selection: $listStyle) {
                        Text("Automatic").tag("Automatic")
                        Text("Plain").tag("Plain")
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                
                Section(header: Text("Developer Tools")) {
                    
                    Button {
                        SyncService.shared.uploadAllLocalData(context: viewContext)
                    } label: {
                        HStack {
                            Image(systemName: "icloud.and.arrow.up")
                            Text("Force Upload to Cloud")
                        }
                        .foregroundColor(.accentColor)
                    }
                    
                    Text("Press this once after logging in to copy your existing test data to Firebase.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Section(header: Text("About")) {
                    Text("Version 1.0.0")
                    Text("Made by Dmytro")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
