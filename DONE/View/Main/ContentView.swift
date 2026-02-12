//
//  ContentView.swift
//  DONE
//
//  Created by Dmytro Hannotskyi on 2026-01-29.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var dateHolder: DateHolder
    @EnvironmentObject var authVM: AuthenticationViewModel
    
    @State private var path = NavigationPath()
    @State private var showSettings = false
    @State private var showGlobalMap = false
    @State private var showAdvancedAdd = false
    
    @AppStorage("useAdvancedCreation") private var useAdvancedCreation = false
    @AppStorage("listStyle") private var listStyle: String = "Plain"
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Todo.isDone, ascending: true),
            NSSortDescriptor(keyPath: \Todo.isUrgent, ascending: false),
            NSSortDescriptor(keyPath: \Todo.createdAt, ascending: false)
        ],
        animation: .default)
    private var todos: FetchedResults<Todo>

    @State private var newTodoTitle = ""
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .bottomTrailing) {
                
                VStack(spacing: 0) {
                    
                    // MARK: - INPUT HEADER
                    if !useAdvancedCreation {
                        simpleInputView
                            .background(Color(uiColor: .systemBackground))
                            .overlay(Divider(), alignment: .bottom)
                    }
                    
                    // MARK: - THE LIST
                    List {
                        ForEach(todos) { todo in
                            NavigationLink(value: todo) {
                                HStack {
                                    // Checkbox
                                    Button {
                                        toggleDone(todo)
                                    } label: {
                                        Image(systemName: todo.isDone ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(todo.isDone ? .accentColor : .gray)
                                    }
                                    .buttonStyle(.borderless)
                                    
                                    // Urgent Icon
                                    Text(todo.isUrgent ? "❗" : "")
                                    
                                    // Title & Description
                                    VStack(alignment: .leading) {
                                        Text(todo.title ?? "Untitled")
                                            .strikethrough(todo.isDone)
                                            .foregroundColor(todo.isDone ? .gray : .primary)
                                            .fontWeight(todo.isUrgent ? .bold : .regular)
                                            .lineLimit(1)
                                        
                                        if let description = todo.desc, !description.isEmpty {
                                            Text(description)
                                                .font(.caption2)
                                                .strikethrough(todo.isDone)
                                                .foregroundColor(.gray)
                                                .lineLimit(1)
                                        }
                                    }
                                    
                                    // Deadline Date
                                    Spacer()
                                    if let date = todo.dueDate {
                                        Text(date, format: .dateTime.month().day())
                                            .font(.caption)
                                            .foregroundColor( (date < Date() && !todo.isDone) ? .red : .secondary)
                                    }
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    todo.isUrgent.toggle()
                                    saveContext()
                                    SyncService.shared.saveToFirestore(todo)
                                } label: {
                                    Label("Urgent", systemImage: "exclamationmark")
                                }
                                .tint(.orange)
                            }
                        }
                        .onDelete(perform: deleteTodo)
                    }
                    .applySelectedListStyle(listStyle)
                    .contentMargins(.vertical, listStyle == "Automatic" ? 20 : 0)
                    .safeAreaInset(edge: .bottom) {
                        if useAdvancedCreation {
                            Color.clear.frame(height: 80)
                        }
                    }
                }
                
                // MARK: - Advanced Floating Button (Overlay)
                if useAdvancedCreation {
                    Button(action: { showAdvancedAdd = true }) {
                        Image(systemName: "plus")
                            .font(.title.weight(.semibold))
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                            .compositingGroup()
                            .shadow(radius: 4, x: 0, y: 4)
                    }
                    .padding()
                }
            }
            .navigationTitle("Todos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { showGlobalMap = true }) { Image(systemName: "map") }
                        Button(action: { showSettings = true }) { Image(systemName: "gearshape") }
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Sign Out") { authVM.signOut(context: viewContext) }
                }
            }
            // MARK: - MOVED HERE (Fixes the crash)
            .navigationDestination(for: Todo.self) { selectedTodo in
                EditTodoView(todo: selectedTodo)
            }
            .navigationDestination(isPresented: $showSettings) { SettingsView() }
            .navigationDestination(isPresented: $showGlobalMap) { Text("Global Map Coming Soon") }
            .sheet(isPresented: $showAdvancedAdd) {
                AddTodoView().presentationDetents([.large])
            }
        }
    }
    
    // MARK: - Subviews
    private var simpleInputView: some View {
        HStack {
            TextField("New todo...", text: $newTodoTitle)
                .textFieldStyle(.roundedBorder)
                .onChange(of: newTodoTitle) { oldValue, newValue in
                    newTodoTitle = String(newValue.prefix(27))
                }
            
            Button("Add") {
                addTodo()
            }
            .disabled(newTodoTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
    }

    // MARK: - Helper Functions
    private func addTodo() {
        withAnimation {
            let newTodo = Todo(context: viewContext)
            newTodo.id = UUID()
            newTodo.title = newTodoTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            newTodo.createdAt = Date()
            newTodo.doneAt = nil
            newTodo.isDone = false
            newTodo.isUrgent = false
            
            dateHolder.saveContext(viewContext)
            SyncService.shared.saveToFirestore(newTodo)
            
            newTodoTitle = ""
        }
    }
    
    private func toggleDone(_ todo: Todo) {
        withAnimation {
            todo.isDone.toggle()
            todo.doneAt = todo.isDone ? Date() : nil
            saveContext()
            SyncService.shared.saveToFirestore(todo)
        }
    }

    private func deleteTodo(at offsets: IndexSet) {
        withAnimation {
            offsets.map { todos[$0] }.forEach { todo in
                SyncService.shared.deleteFromFirestore(todo)
                viewContext.delete(todo)
            }
            dateHolder.saveContext(viewContext)
        }
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}


extension View {
    @ViewBuilder
    func applySelectedListStyle(_ styleName: String) -> some View {
        if styleName == "Automatic" {
            self.listStyle(.automatic)
        } else {
            self.listStyle(.plain)
        }
    }
}
