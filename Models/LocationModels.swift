import Foundation

// MARK: - Location Models

struct Country: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let flag: String
    let cities: [City]
    
    init(id: String, name: String, flag: String, cities: [String]) {
        self.id = id
        self.name = name
        self.flag = flag
        self.cities = cities.map { City(name: $0, countryId: id) }
    }
}

struct City: Identifiable, Codable, Hashable {
    // FIXED: Make id mutable to allow proper decoding
    var id: String
    let name: String
    let countryId: String
    
    // FIXED: Add proper init to handle id generation
    init(name: String, countryId: String) {
        self.id = UUID().uuidString
        self.name = name
        self.countryId = countryId
    }
    
    // FIXED: Custom init for decoding with existing id
    init(id: String, name: String, countryId: String) {
        self.id = id
        self.name = name
        self.countryId = countryId
    }
}

struct BarLocation: Codable, Hashable {
    let country: String
    let countryCode: String
    let city: String
    let displayName: String
    
    init(country: String, countryCode: String, city: String) {
        self.country = country
        self.countryCode = countryCode
        self.city = city
        self.displayName = "\(city), \(country)"
    }
}

// MARK: - Global Location Data

class LocationManager: ObservableObject {
    static let shared = LocationManager()
    
    let countries: [Country] = [
        // Asia-Pacific
        Country(id: "JP", name: "Japan", flag: "🇯🇵", cities: [
            "Tokyo", "Osaka", "Kyoto", "Yokohama", "Nagoya", "Sapporo", "Fukuoka", "Kobe", "Sendai", "Hiroshima"
        ]),
        Country(id: "KR", name: "South Korea", flag: "🇰🇷", cities: [
            "Seoul", "Busan", "Incheon", "Daegu", "Daejeon", "Gwangju", "Ulsan", "Suwon"
        ]),
        Country(id: "CN", name: "China", flag: "🇨🇳", cities: [
            "Beijing", "Shanghai", "Guangzhou", "Shenzhen", "Chengdu", "Hangzhou", "Xi'an", "Nanjing", "Wuhan", "Tianjin"
        ]),
        Country(id: "SG", name: "Singapore", flag: "🇸🇬", cities: [
            "Singapore"
        ]),
        Country(id: "TH", name: "Thailand", flag: "🇹🇭", cities: [
            "Bangkok", "Chiang Mai", "Phuket", "Pattaya", "Krabi", "Hua Hin"
        ]),
        Country(id: "AU", name: "Australia", flag: "🇦🇺", cities: [
            "Sydney", "Melbourne", "Brisbane", "Perth", "Adelaide", "Gold Coast", "Canberra", "Darwin"
        ]),
        
        // North America
        Country(id: "US", name: "United States", flag: "🇺🇸", cities: [
            "New York", "Los Angeles", "Chicago", "Houston", "Phoenix", "Philadelphia", "San Antonio", "San Diego", "Dallas", "San Jose", "Austin", "Jacksonville", "Fort Worth", "Columbus", "Charlotte", "San Francisco", "Indianapolis", "Seattle", "Denver", "Washington DC", "Boston", "Nashville", "Detroit", "Oklahoma City", "Las Vegas", "Portland", "Memphis", "Louisville", "Baltimore", "Milwaukee", "Albuquerque", "Tucson", "Fresno", "Sacramento", "Mesa", "Kansas City", "Atlanta", "Long Beach", "Colorado Springs", "Raleigh", "Miami", "Virginia Beach", "Omaha", "Oakland", "Minneapolis", "Tulsa", "Arlington", "Tampa", "New Orleans"
        ]),
        Country(id: "CA", name: "Canada", flag: "🇨🇦", cities: [
            "Toronto", "Montreal", "Vancouver", "Calgary", "Edmonton", "Ottawa", "Winnipeg", "Quebec City", "Halifax"
        ]),
        Country(id: "MX", name: "Mexico", flag: "🇲🇽", cities: [
            "Mexico City", "Guadalajara", "Monterrey", "Cancun", "Tijuana", "Puerto Vallarta", "Playa del Carmen"
        ]),
        
        // Europe
        Country(id: "GB", name: "United Kingdom", flag: "🇬🇧", cities: [
            "London", "Manchester", "Birmingham", "Liverpool", "Leeds", "Sheffield", "Bristol", "Edinburgh", "Glasgow", "Newcastle"
        ]),
        Country(id: "DE", name: "Germany", flag: "🇩🇪", cities: [
            "Berlin", "Munich", "Hamburg", "Cologne", "Frankfurt", "Stuttgart", "Düsseldorf", "Dortmund", "Essen", "Leipzig"
        ]),
        Country(id: "FR", name: "France", flag: "🇫🇷", cities: [
            "Paris", "Marseille", "Lyon", "Toulouse", "Nice", "Nantes", "Strasbourg", "Montpellier", "Bordeaux", "Lille"
        ]),
        Country(id: "IT", name: "Italy", flag: "🇮🇹", cities: [
            "Rome", "Milan", "Naples", "Turin", "Palermo", "Genoa", "Bologna", "Florence", "Venice", "Verona"
        ]),
        Country(id: "ES", name: "Spain", flag: "🇪🇸", cities: [
            "Madrid", "Barcelona", "Valencia", "Seville", "Zaragoza", "Málaga", "Murcia", "Palma", "Las Palmas", "Bilbao"
        ]),
        Country(id: "NL", name: "Netherlands", flag: "🇳🇱", cities: [
            "Amsterdam", "Rotterdam", "The Hague", "Utrecht", "Eindhoven", "Tilburg", "Groningen", "Almere"
        ]),
        Country(id: "BE", name: "Belgium", flag: "🇧🇪", cities: [
            "Brussels", "Antwerp", "Ghent", "Charleroi", "Liège", "Bruges"
        ]),
        Country(id: "CH", name: "Switzerland", flag: "🇨🇭", cities: [
            "Zurich", "Geneva", "Basel", "Bern", "Lausanne", "Winterthur"
        ]),
        Country(id: "AT", name: "Austria", flag: "🇦🇹", cities: [
            "Vienna", "Graz", "Linz", "Salzburg", "Innsbruck"
        ]),
        Country(id: "SE", name: "Sweden", flag: "🇸🇪", cities: [
            "Stockholm", "Gothenburg", "Malmö", "Uppsala", "Västerås"
        ]),
        Country(id: "NO", name: "Norway", flag: "🇳🇴", cities: [
            "Oslo", "Bergen", "Trondheim", "Stavanger", "Drammen"
        ]),
        Country(id: "DK", name: "Denmark", flag: "🇩🇰", cities: [
            "Copenhagen", "Aarhus", "Odense", "Aalborg", "Esbjerg"
        ]),
        Country(id: "FI", name: "Finland", flag: "🇫🇮", cities: [
            "Helsinki", "Espoo", "Tampere", "Vantaa", "Oulu", "Turku"
        ]),
        Country(id: "PL", name: "Poland", flag: "🇵🇱", cities: [
            "Warsaw", "Kraków", "Łódź", "Wrocław", "Poznań", "Gdańsk"
        ]),
        Country(id: "CZ", name: "Czech Republic", flag: "🇨🇿", cities: [
            "Prague", "Brno", "Ostrava", "Plzen", "Liberec"
        ]),
        
        // South America
        Country(id: "BR", name: "Brazil", flag: "🇧🇷", cities: [
            "São Paulo", "Rio de Janeiro", "Brasília", "Salvador", "Fortaleza", "Belo Horizonte", "Manaus", "Curitiba", "Recife", "Porto Alegre"
        ]),
        Country(id: "AR", name: "Argentina", flag: "🇦🇷", cities: [
            "Buenos Aires", "Córdoba", "Rosario", "Mendoza", "La Plata", "San Miguel de Tucumán"
        ]),
        Country(id: "CL", name: "Chile", flag: "🇨🇱", cities: [
            "Santiago", "Valparaíso", "Concepción", "La Serena", "Antofagasta"
        ]),
        Country(id: "CO", name: "Colombia", flag: "🇨🇴", cities: [
            "Bogotá", "Medellín", "Cali", "Barranquilla", "Cartagena", "Cúcuta"
        ]),
        
        // Middle East
        Country(id: "AE", name: "UAE", flag: "🇦🇪", cities: [
            "Dubai", "Abu Dhabi", "Sharjah", "Al Ain", "Ajman"
        ]),
        Country(id: "SA", name: "Saudi Arabia", flag: "🇸🇦", cities: [
            "Riyadh", "Jeddah", "Mecca", "Medina", "Dammam"
        ]),
        Country(id: "IL", name: "Israel", flag: "🇮🇱", cities: [
            "Tel Aviv", "Jerusalem", "Haifa", "Rishon LeZion", "Ashdod"
        ]),
        
        // Africa
        Country(id: "ZA", name: "South Africa", flag: "🇿🇦", cities: [
            "Cape Town", "Johannesburg", "Durban", "Pretoria", "Port Elizabeth"
        ]),
        Country(id: "EG", name: "Egypt", flag: "🇪🇬", cities: [
            "Cairo", "Alexandria", "Giza", "Luxor", "Aswan"
        ]),
        
        // Others
        Country(id: "TR", name: "Turkey", flag: "🇹🇷", cities: [
            "Istanbul", "Ankara", "Izmir", "Bursa", "Antalya", "Adana"
        ]),
        Country(id: "RU", name: "Russia", flag: "🇷🇺", cities: [
            "Moscow", "Saint Petersburg", "Novosibirsk", "Yekaterinburg", "Kazan", "Nizhny Novgorod"
        ]),
        Country(id: "IN", name: "India", flag: "🇮🇳", cities: [
            "Mumbai", "Delhi", "Bangalore", "Hyderabad", "Chennai", "Kolkata", "Pune", "Ahmedabad", "Jaipur", "Surat"
        ])
    ]
    
    func getCountry(by id: String) -> Country? {
        return countries.first { $0.id == id }
    }
    
    func getCities(for countryId: String) -> [City] {
        return getCountry(by: countryId)?.cities ?? []
    }
    
    func searchCountries(query: String) -> [Country] {
        if query.isEmpty {
            return countries
        }
        return countries.filter {
            $0.name.localizedCaseInsensitiveContains(query)
        }
    }
    
    func searchCities(query: String, in countryId: String? = nil) -> [City] {
        let allCities = countryId != nil ? getCities(for: countryId!) : countries.flatMap { $0.cities }
        
        if query.isEmpty {
            return allCities
        }
        
        return allCities.filter {
            $0.name.localizedCaseInsensitiveContains(query)
        }
    }
}
