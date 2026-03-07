import Foundation

enum AppConstants {
    static let categories = ["Food & Drink", "Activities", "Surprise Me"]
    static let timesOfDay = ["Morning", "Afternoon", "Evening", "Late Night"]
    static let weathers = ["Sunny", "Hot", "Cloudy", "Rainy", "Snowy", "Cold", "Windy", "Any Weather"]
    static let vibes = ["Romantic", "Adventurous", "Chill", "Fancy", "Quirky", "Cozy", "Lively", "Intimate", "Cultural", "Artsy"]
    static let budgets = ["Free", "Under $50", "$50–150", "$150–300", "Splurge ($300+)"]
    static let durations = ["Quick (1-2 hrs)", "Half Day", "Full Day", "All Night"]

    static let cuisines = [
        "Italian","Japanese","Mexican","Chinese","Thai","Korean","Indian","French",
        "Vietnamese","Mediterranean","Middle Eastern","Ethiopian","Peruvian","Colombian",
        "Brazilian","Caribbean/Jamaican","Filipino","Moroccan","Turkish","Polish",
        "Russian/Georgian","Taiwanese","Trinidadian",
        "Greek","Spanish","American","Southern","Soul Food","Cajun/Creole","BBQ","Seafood",
        "Pizza","Sushi","Ramen","Tacos","Dim Sum","Hawaiian/Poke","Jewish Deli",
        "Steakhouse","Farm-to-Table","Vegan","Brunch","Bakery & Pastry",
        "Cocktail Bar","Wine Bar","Beer Garden","Coffee","Dessert","Food Hall","Deli & Sandwich",
    ]

    static let activityTypes = [
        "Outdoors & Nature","Museum & Art","Live Music & Concerts","Comedy",
        "Theater & Performance","Immersive Experience","Sports & Games","Wellness & Spa",
        "Shopping & Markets","Vintage Shopping","Classes & Workshops","Pottery & Art Studio",
        "Tours & Walks","Food Tour","Pub Crawl","Day Trip",
        "Nightlife & Dancing","Rooftop Bar/Lounge","Speakeasy/Hidden Bar","Karaoke",
        "Arcade & Gaming","Escape Room","Film & Cinema","Photography Walk",
        "Bookstore & Café","Record Store","Boat & Water","Seasonal & Holiday",
    ]

    static let neighborhoods: [(borough: String, hoods: [String])] = [
        ("Brooklyn", ["Carroll Gardens","Cobble Hill","Brooklyn Heights","DUMBO","Park Slope","Prospect Heights","Williamsburg","Greenpoint","Bushwick","Fort Greene","Clinton Hill","Gowanus","Red Hook","Bay Ridge","Bed-Stuy","Boerum Hill","Crown Heights","Sunset Park","Flatbush"]),
        ("Manhattan", ["West Village","East Village","Lower East Side","SoHo","NoHo","Nolita","Chinatown","Little Italy","Tribeca","Chelsea","Hell's Kitchen","Midtown","Flatiron","NoMad","Gramercy","Murray Hill","Upper East Side","Upper West Side","Harlem","Washington Heights","Financial District","East Harlem","Roosevelt Island","Governors Island"]),
        ("Queens", ["Astoria","Long Island City","Flushing","Jackson Heights","Woodside","Sunnyside","Forest Hills","Ridgewood","Corona"]),
        ("Bronx", ["Arthur Avenue","Mott Haven","City Island","Pelham Bay","Riverdale"]),
        ("Across the River", ["Hoboken","Jersey City"]),
    ]

    static let presets: [(label: String, emoji: String, filters: FilterState)] = [
        ("Date Night Classic", "💛", FilterState(category: "Surprise Me", timeOfDay: "Evening", vibe: ["Romantic"], budget: "$50–150")),
        ("Rainy Day Indoor", "🌧", FilterState(category: "Activities", weather: "Rainy", vibe: ["Cozy", "Chill"])),
        ("Cheap Thrills", "🤑", FilterState(category: "Surprise Me", vibe: ["Adventurous"], budget: "Under $50")),
        ("Fancy Night Out", "🥂", FilterState(category: "Food & Drink", timeOfDay: "Evening", vibe: ["Fancy", "Intimate"], budget: "$150–300")),
    ]

    static let loadingMessages = [
        "Checking the vibe across the boroughs...",
        "Asking the locals for their hot takes...",
        "Scouring secret NYC spots...",
        "Checking what's poppin' tonight...",
        "Canvassing the five boroughs...",
        "Digging through hidden gems...",
        "Peeking behind the velvet ropes...",
        "Scanning rooftops and basements...",
        "Checking the subway for inspiration...",
        "Flipping through NYC's little black book...",
        "Cross-referencing with NYC insiders...",
        "Hunting for the perfect match...",
        "Asking a bodega cat for advice...",
        "Sneaking into a speakeasy for intel...",
        "Texting that friend who knows everyone...",
        "Eavesdropping on the L train...",
        "Bribing the ma\u{00EE}tre d' for the good stuff...",
        "Consulting the pizza rat oracle...",
        "Reading the city like a love letter...",
        "Dodging tourists, finding treasures...",
        "Tapping into the late-night grapevine...",
        "Checking what the cool kids are up to...",
        "Decoding the neon signs...",
        "Sliding into NYC's DMs...",
        "Hopping turnstiles for the perfect spot...",
        "Asking the pigeons \u{2014} they know everything...",
        "Following the scent of something amazing...",
        "Charting a course through the concrete jungle...",
        "Checking reservations, pulling strings...",
        "Shaking up something special...",
        "Finding that place you'll talk about forever...",
        "Jaywalking through possibilities...",
        "Hailing a cab to somewhere amazing...",
        "Window-shopping for the perfect date...",
        "Running the numbers on romance...",
        "Checking the fire escape for hidden rooftops...",
        "Whispering to the bartender...",
        "Mapping out the magic...",
        "Asking the hot dog vendor for the real deal...",
        "Picking the perfect playlist for tonight...",
        "Ducking into a hidden courtyard...",
        "Scrolling through the city's best-kept secrets...",
        "Counting the lights on the bridge...",
        "Sampling the scene across five boroughs...",
        "Checking the vibes in the back room...",
        "Swiping right on the whole city...",
        "Tuning into the rhythm of the streets...",
        "Negotiating with the bouncer...",
        "Peeking at tomorrow's reservations today...",
        "Scanning the skyline for inspiration...",
        "Putting in a good word with the chef...",
        "Catching the last train to somewhere great...",
        "Reading between the brownstone lines...",
        "Curating your perfect NYC moment...",
        "Unlocking the city's cheat codes...",
        "Double-checking the vibe report...",
        "Asking the street artist for directions...",
        "Flipping through a stack of matchbooks...",
        "Warming up the best table in the house...",
        "Plotting the ultimate date route...",
        "Getting the inside scoop from a cab driver...",
    ]

    static let loadingEmoji: [String: [String]] = [
        "food": ["🍕","🍝","🥡","🍣","🥂","🍷","🧁","🍜"],
        "activity": ["🎭","🎨","🎸","🏙","🌉","🗽","🎪","🚶‍♂️"],
        "default": ["🎲","✨","🗽","🌃","🏙","🎯","💛","🌟"],
    ]

    static let boroughBounds: [(name: String, latMin: Double, latMax: Double, lngMin: Double, lngMax: Double)] = [
        ("Manhattan", 40.700, 40.882, -74.020, -73.907),
        ("Brooklyn", 40.570, 40.739, -74.042, -73.855),
        ("Queens", 40.541, 40.812, -73.962, -73.700),
        ("Bronx", 40.785, 40.917, -73.933, -73.765),
        ("Across the River", 40.660, 40.760, -74.100, -74.020),
    ]

    static func detectBorough(lat: Double, lng: Double) -> String? {
        for b in boroughBounds {
            if lat >= b.latMin && lat <= b.latMax && lng >= b.lngMin && lng <= b.lngMax {
                return b.name
            }
        }
        return nil
    }
}
