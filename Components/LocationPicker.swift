import SwiftUI

// MARK: - Location Picker Component

struct LocationPicker: View {
    @Binding var selectedCountry: Country?
    @Binding var selectedCity: City?
    @StateObject private var locationManager = LocationManager.shared
    
    @State private var showingCountryPicker = false
    @State private var showingCityPicker = false
    
    var isValid: Bool {
        selectedCountry != nil && selectedCity != nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Bar Location")
                    .font(.headline)
                Text("*")
                    .foregroundColor(.red)
            }
            
            Text("Select the country and city where your bar is located")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Country Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Country")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Button(action: {
                    showingCountryPicker = true
                }) {
                    HStack {
                        if let country = selectedCountry {
                            Text(country.flag)
                                .font(.title2)
                            Text(country.name)
                                .foregroundColor(.primary)
                        } else {
                            Image(systemName: "globe")
                                .foregroundColor(.gray)
                            Text("Select Country")
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedCountry != nil ? Color.blue.opacity(0.3) : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // City Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("City")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Button(action: {
                    if selectedCountry != nil {
                        showingCityPicker = true
                    }
                }) {
                    HStack {
                        if let city = selectedCity {
                            Image(systemName: "building.2")
                                .foregroundColor(.blue)
                            Text(city.name)
                                .foregroundColor(.primary)
                        } else {
                            Image(systemName: "building.2")
                                .foregroundColor(.gray)
                            Text(selectedCountry != nil ? "Select City" : "Select Country First")
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedCountry != nil ? Color.gray.opacity(0.1) : Color.gray.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        selectedCity != nil ? Color.blue.opacity(0.3) :
                                        selectedCountry != nil ? Color.gray.opacity(0.3) : Color.gray.opacity(0.1),
                                        lineWidth: 1
                                    )
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(selectedCountry == nil)
            }
            
            // Selected Location Display
            if let country = selectedCountry, let city = selectedCity {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.green)
                    Text("\(city.name), \(country.name)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .sheet(isPresented: $showingCountryPicker) {
            CountryPickerSheet(
                selectedCountry: $selectedCountry,
                selectedCity: $selectedCity,
                locationManager: locationManager
            )
        }
        .sheet(isPresented: $showingCityPicker) {
            if let country = selectedCountry {
                CityPickerSheet(
                    country: country,
                    selectedCity: $selectedCity,
                    locationManager: locationManager
                )
            }
        }
    }
}

// MARK: - Country Picker Sheet

struct CountryPickerSheet: View {
    @Binding var selectedCountry: Country?
    @Binding var selectedCity: City?
    @ObservedObject var locationManager: LocationManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    
    private var filteredCountries: [Country] {
        locationManager.searchCountries(query: searchText)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search countries", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding()
                
                // Country list
                List(filteredCountries) { country in
                    CountryRow(
                        country: country,
                        isSelected: selectedCountry?.id == country.id
                    ) {
                        selectedCountry = country
                        selectedCity = nil // Reset city when country changes
                        dismiss()
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Select Country")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - City Picker Sheet

struct CityPickerSheet: View {
    let country: Country
    @Binding var selectedCity: City?
    @ObservedObject var locationManager: LocationManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    
    private var filteredCities: [City] {
        let cities = country.cities
        if searchText.isEmpty {
            return cities
        }
        return cities.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with country info
                HStack {
                    Text(country.flag)
                        .font(.title)
                    VStack(alignment: .leading) {
                        Text("Select City")
                            .font(.headline)
                        Text("in \(country.name)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search cities", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding()
                
                // City list
                List(filteredCities) { city in
                    CityRow(
                        city: city,
                        isSelected: selectedCity?.id == city.id
                    ) {
                        selectedCity = city
                        dismiss()
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Row Components

struct CountryRow: View {
    let country: Country
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(country.flag)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(country.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(country.cities.count) \(country.cities.count == 1 ? "city" : "cities")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CityRow: View {
    let city: City
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "building.2")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Text(city.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Browse by Location Component (Simplified)

struct BrowseByLocationView: View {
    @ObservedObject var barViewModel: BarViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager = LocationManager.shared
    
    @State private var selectedCountry: Country?
    @State private var selectedCity: City?
    @State private var showingCountryPicker = false
    @State private var showingCityPicker = false
    
    private var filteredBars: [Bar] {
        let allBars = barViewModel.getAllBars()
        
        if let country = selectedCountry, let city = selectedCity {
            return allBars.filter { bar in
                bar.location?.country == country.name && bar.location?.city == city.name
            }
        } else if let country = selectedCountry {
            return allBars.filter { bar in
                bar.location?.country == country.name
            }
        } else {
            return allBars
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Location selector
                VStack(spacing: 16) {
                    Text("Browse bars by location")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        // Country button
                        Button(action: { showingCountryPicker = true }) {
                            HStack {
                                if let country = selectedCountry {
                                    Text(country.flag)
                                    Text(country.name)
                                        .foregroundColor(.primary)
                                } else {
                                    Image(systemName: "globe")
                                        .foregroundColor(.gray)
                                    Text("Any Country")
                                        .foregroundColor(.gray)
                                }
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // City button
                        Button(action: {
                            if selectedCountry != nil {
                                showingCityPicker = true
                            }
                        }) {
                            HStack {
                                if let city = selectedCity {
                                    Image(systemName: "building.2")
                                        .foregroundColor(.blue)
                                    Text(city.name)
                                        .foregroundColor(.primary)
                                } else {
                                    Image(systemName: "building.2")
                                        .foregroundColor(.gray)
                                    Text("Any City")
                                        .foregroundColor(.gray)
                                }
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(selectedCountry == nil)
                    }
                    
                    // Clear filters button
                    if selectedCountry != nil || selectedCity != nil {
                        Button("Clear Filters") {
                            selectedCountry = nil
                            selectedCity = nil
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                
                Divider()
                
                // Results
                if filteredBars.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "building.2")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No bars found")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if selectedCountry != nil || selectedCity != nil {
                            Text("Try adjusting your location filters")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("No bars have been registered yet")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 50)
                } else {
                    List(filteredBars) { bar in
                        LocationBarRow(bar: bar, barViewModel: barViewModel)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Browse by Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingCountryPicker) {
            CountryPickerSheet(
                selectedCountry: $selectedCountry,
                selectedCity: $selectedCity,
                locationManager: locationManager
            )
        }
        .sheet(isPresented: $showingCityPicker) {
            if let country = selectedCountry {
                CityPickerSheet(
                    country: country,
                    selectedCity: $selectedCity,
                    locationManager: locationManager
                )
            }
        }
    }
}

// MARK: - Location Bar Row (Simplified)

struct LocationBarRow: View {
    let bar: Bar
    @ObservedObject var barViewModel: BarViewModel
    
    var body: some View {
        Button(action: {
            barViewModel.selectedBar = bar
            barViewModel.showingDetail = true
        }) {
            HStack(spacing: 12) {
                // Status indicator
                VStack {
                    Image(systemName: bar.status.icon)
                        .font(.title2)
                        .foregroundColor(bar.status.color)
                    
                    Text(bar.status.displayName)
                        .font(.caption2)
                        .foregroundColor(bar.status.color)
                }
                .frame(width: 70)
                
                // Bar details
                VStack(alignment: .leading, spacing: 4) {
                    Text(bar.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let location = bar.location {
                        HStack {
                            Image(systemName: "mappin")
                                .foregroundColor(.secondary)
                                .font(.caption)
                            Text(location.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Status info
                    HStack(spacing: 8) {
                        // Show if manual override
                        if !bar.isFollowingSchedule {
                            HStack(spacing: 2) {
                                Image(systemName: "hand.raised.fill")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                                Text("Manual")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                        } else {
                            HStack(spacing: 2) {
                                Image(systemName: "calendar")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                                Text("Schedule")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            }
                        }
                        
                        // Auto-transition indicator
                        if bar.isAutoTransitionActive {
                            HStack(spacing: 2) {
                                Image(systemName: "timer")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                                Text("Auto")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Last updated info
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Updated")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(timeAgo(bar.lastUpdated))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .fontWeight(.medium)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 4)
            .contentShape(Rectangle()) // Makes entire row tappable
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d"
        }
    }
}
