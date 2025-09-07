import SwiftUI

// MARK: - Location Picker Component with Liquid Glass

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
            // Header with liquid glass
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Bar Location")
                        .font(.headline)
                    Text("*")
                        .foregroundColor(.red)
                }
                
                Text("Select the country and city where your bar is located")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .liquidGlass(level: .ultra, cornerRadius: .medium, shadow: .subtle)
            
            // Country Selection with liquid glass
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
                }
                .buttonStyle(LiquidGlassButtonStyle(glassLevel: .thin, cornerRadius: .medium))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(selectedCountry != nil ? Color.blue.opacity(0.3) : Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
            .liquidGlass(level: .regular, cornerRadius: .medium, shadow: .medium)
            
            // City Selection with liquid glass
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
                }
                .buttonStyle(LiquidGlassButtonStyle(glassLevel: .thin, cornerRadius: .medium))
                .disabled(selectedCountry == nil)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            selectedCity != nil ? Color.blue.opacity(0.3) :
                            selectedCountry != nil ? Color.gray.opacity(0.3) : Color.gray.opacity(0.1),
                            lineWidth: 1
                        )
                )
            }
            .liquidGlass(level: .regular, cornerRadius: .medium, shadow: .medium)
            
            // Selected Location Display with liquid glass
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
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.green.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.green.opacity(0.3), lineWidth: 1)
                        )
                )
                .liquidGlass(level: .thin, cornerRadius: .medium, shadow: .subtle)
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

// MARK: - Country Picker Sheet with Liquid Glass

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
                // Header with liquid glass
                VStack(spacing: 16) {
                    Text("Select Country")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Choose where your bar is located")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .liquidGlass(level: .ultra, cornerRadius: .medium, shadow: .subtle)
                
                // Search bar with liquid glass
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search countries", text: $searchText)
                        .textFieldStyle(LiquidGlassTextFieldStyle())
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .liquidGlass(level: .regular, cornerRadius: .medium, shadow: .medium)
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
                    .listRowBackground(Color.clear)
                }
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden)
            }
            .background(.regularMaterial)
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

// MARK: - City Picker Sheet with Liquid Glass

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
                // Header with country info and liquid glass
                VStack(spacing: 16) {
                    HStack {
                        Text(country.flag)
                            .font(.title)
                        VStack(alignment: .leading) {
                            Text("Select City")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("in \(country.name)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }
                .padding()
                .liquidGlass(level: .ultra, cornerRadius: .medium, shadow: .subtle)
                
                // Search bar with liquid glass
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search cities", text: $searchText)
                        .textFieldStyle(LiquidGlassTextFieldStyle())
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .liquidGlass(level: .regular, cornerRadius: .medium, shadow: .medium)
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
                    .listRowBackground(Color.clear)
                }
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden)
            }
            .background(.regularMaterial)
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

// MARK: - Row Components with Liquid Glass

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
        .liquidGlass(level: .thin, cornerRadius: .medium, shadow: .subtle)
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
        .liquidGlass(level: .thin, cornerRadius: .medium, shadow: .subtle)
    }
}

// MARK: - Browse by Location Component with Liquid Glass

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
                // Location selector with liquid glass
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Text("Browse bars by location")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Filter bars by country and city")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
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
                        }
                        .buttonStyle(LiquidGlassButtonStyle(glassLevel: .thin, cornerRadius: .small))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.blue.opacity(0.3), lineWidth: 1)
                        )
                        
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
                        }
                        .buttonStyle(LiquidGlassButtonStyle(glassLevel: .thin, cornerRadius: .small))
                        .disabled(selectedCountry == nil)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.orange.opacity(0.3), lineWidth: 1)
                        )
                    }
                    
                    // Clear filters button
                    if selectedCountry != nil || selectedCity != nil {
                        Button("Clear Filters") {
                            selectedCountry = nil
                            selectedCity = nil
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                .liquidGlass(level: .regular, cornerRadius: .large, shadow: .medium)
                .padding()
                
                Divider()
                    .background(.primary.opacity(0.1))
                
                // Results
                if filteredBars.isEmpty {
                    emptyResultsView
                } else {
                    List(filteredBars) { bar in
                        LocationBarRow(bar: bar, barViewModel: barViewModel)
                            .listRowBackground(Color.clear)
                    }
                    .listStyle(PlainListStyle())
                    .scrollContentBackground(.hidden)
                }
            }
            .background(.regularMaterial)
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
    
    private var emptyResultsView: some View {
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
        .liquidGlass(level: .regular, cornerRadius: .extraLarge, shadow: .medium)
        .padding()
    }
}

// MARK: - Location Bar Row with Enhanced 7-day Schedule Info and Liquid Glass

struct LocationBarRow: View {
    let bar: Bar
    @ObservedObject var barViewModel: BarViewModel
    
    var body: some View {
        Button(action: {
            barViewModel.selectedBar = bar
            barViewModel.showingDetail = true
        }) {
            HStack(spacing: 12) {
                // Status indicator with liquid glass
                LiquidGlassStatusIndicator(status: bar.status, size: 50)
                
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
                    
                    // Enhanced status info with 7-day schedule
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
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
                        } else {
                            HStack(spacing: 2) {
                                Image(systemName: "calendar")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                                Text("Schedule")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
                        }
                        
                        // Today's schedule info
                        if let todaysSchedule = bar.todaysSchedule {
                            HStack(spacing: 2) {
                                Image(systemName: todaysSchedule.isOpen ? "clock" : "moon")
                                    .font(.caption2)
                                    .foregroundColor(todaysSchedule.isOpen ? .blue : .gray)
                                Text(todaysSchedule.isOpen ? "Open today" : "Closed today")
                                    .font(.caption2)
                                    .foregroundColor(todaysSchedule.isOpen ? .blue : .gray)
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(
                                todaysSchedule.isOpen ? .blue.opacity(0.1) : .gray.opacity(0.1),
                                in: RoundedRectangle(cornerRadius: 4)
                            )
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
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }
                
                Spacer()
                
                // Last updated info and schedule preview
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Updated")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(timeAgo(bar.lastUpdated))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .fontWeight(.medium)
                    
                    // Show today's hours if open
                    if let todaysSchedule = bar.todaysSchedule, todaysSchedule.isOpen {
                        Text(todaysSchedule.displayText)
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 4)
            .contentShape(Rectangle()) // Makes entire row tappable
        }
        .buttonStyle(PlainButtonStyle())
        .liquidGlass(level: .thin, cornerRadius: .medium, shadow: .subtle)
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

#Preview {
    LocationPicker(
        selectedCountry: .constant(nil),
        selectedCity: .constant(nil)
    )
}
