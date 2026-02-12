//
//  LocationPickerView.swift
//  DONE
//
//  Created by Dmytro Hannotskyi on 2026-02-06.
//

import SwiftUI
import MapKit
import CoreLocation

struct LocationPickerView: View {
    @Environment(\.dismiss) var dismiss
    
    @Binding var selectedAddress: String
    @Binding var selectedLat: Double
    @Binding var selectedLong: Double
    
    var onConfirm: () -> Void
    
    @State private var locationManager = CLLocationManager()
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    
    @State private var position: MapCameraPosition = .automatic
    
    @State private var visibleRegion: MKCoordinateRegion?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - The Map
                Map(position: $position, interactionModes: .all)
                    .mapControls {
                        MapUserLocationButton()
                        MapCompass()
                        MapScaleView()
                    }
                    .onMapCameraChange(frequency: .continuous) { context in
                        visibleRegion = context.region
                        
                        if !isSearching {
                            selectedLat = context.region.center.latitude
                            selectedLong = context.region.center.longitude
                        }
                    }
                
                // MARK: - Center Pin
                Image(systemName: "mappin")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 40)
                    .foregroundColor(.red)
                    .padding(.bottom, 40)
                    .shadow(radius: 5)
                
                // MARK: - Search Bar
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search (e.g. Republika)...", text: $searchText)
                            .submitLabel(.search)
                            .onSubmit {
                                performSearch()
                            }
                            .onChange(of: searchText) { _, newValue in
                                if newValue.isEmpty {
                                    searchResults = []
                                }
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                searchResults = []
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(10)
                    .background(.thickMaterial)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .padding(.vertical, 5)
                    .padding(.horizontal)
                    .padding(.trailing, 45)

                    
                    if !searchResults.isEmpty {
                        List(searchResults, id: \.self) { item in
                            Button {
                                selectLocation(item)
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(item.name ?? "Unknown Place")
                                        .font(.headline)
                                    Text(item.placemark.title ?? "")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .listStyle(.plain)
                        .frame(maxHeight: 250)
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .shadow(radius: 5)
                    }
                    
                    Spacer()
                    
                    // MARK: - Confirm Button
                    Button(action: { reverseGeocode() }) {
                        Text("Confirm Location")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                            .padding()
                            .shadow(radius: 3)
                    }
                }
            }
            .navigationTitle("Pick Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                locationManager.requestAlwaysAuthorization()
                
                if abs(selectedLat) > 0.001 && abs(selectedLong) > 0.001 {
                    print("Opening Saved Location: \(selectedLat), \(selectedLong)")
                    position = .region(MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: selectedLat, longitude: selectedLong),
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    ))
                } else {
                    print("No saved location, jumping to User GPS")
                    position = .userLocation(fallback: .region(
                        MKCoordinateRegion(
                            center: CLLocationCoordinate2D(latitude: 45.5017, longitude: -73.5673),
                            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                        )
                    ))
                }
            }
        }
    }
    
    // MARK: - Search Logic
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.resultTypes = .pointOfInterest
        
        if let region = visibleRegion {
            request.region = region
        }
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let items = response?.mapItems else { return }
            
            withAnimation {
                self.searchResults = items
            }
        }
    }
    
    // MARK: - Confirm Logic
    private func selectLocation(_ item: MKMapItem) {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        searchResults = []
        searchText = item.name ?? ""
        
        let coordinate = item.placemark.coordinate
        withAnimation {
            position = .region(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }
        
        selectedLat = coordinate.latitude
        selectedLong = coordinate.longitude
    }
    private func reverseGeocode() {
        let location = CLLocation(latitude: selectedLat, longitude: selectedLong)
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            if let place = placemarks?.first {
                let name = place.name ?? ""
                let locality = place.locality ?? ""
                
                if name.contains(locality) {
                    self.selectedAddress = name
                } else {
                    self.selectedAddress = "\(name), \(locality)"
                }
            } else {
                self.selectedAddress = "Selected Location"
            }
            
            onConfirm()
            dismiss()
        }
    }
}
