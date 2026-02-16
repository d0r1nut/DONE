# DONE - Context-Aware Task Manager

DONE is a smart task management application built with SwiftUI and CoreData. It goes beyond simple lists by integrating context-aware notifications. Users can attach physical locations to tasks, allowing the app to trigger reminders specifically when the user enters or leaves a relevant area.

## Core Features

* **Smart Task Management:** Create, edit, and prioritize tasks using isUrgent status and dueTo dates.
* **Global Map Dashboard:** An interactive MapKit view that visualizes all active tasks as pins on a world map. Users can tap a pin to see task details.
* **Location-Based Context:** Tasks can be assigned specific physical addresses.
* **Geofencing (Background):** The app monitors these locations to trigger notifications upon arrival or departure.
* **Cloud Sync:** Firebase integration for data backup and cross-device synchronization.
* **Smart Sorting:** Tasks are automatically sorted by completion status, urgency, and creation date.

## Technical Architecture

* **Language:** Swift / SwiftUI
* **Persistence:** CoreData (Todo Entity) managed via a DateHolder environment object.
* **Architecture:** MVVM-like pattern where DateHolder acts as the central logic controller for context saving, while Views handle local state.

## Team

* Dmytro Hannotskyi
