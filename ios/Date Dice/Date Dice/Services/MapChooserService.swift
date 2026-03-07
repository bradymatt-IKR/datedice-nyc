import UIKit

struct MapApp: Identifiable {
    let id = UUID()
    let name: String
    let icon: String   // SF Symbol name
    let urlScheme: String
}

struct MapChooserService {

    private static let allApps: [MapApp] = [
        MapApp(name: "Apple Maps", icon: "map.fill", urlScheme: "maps"),
        MapApp(name: "Google Maps", icon: "globe", urlScheme: "comgooglemaps"),
        MapApp(name: "Waze", icon: "car.fill", urlScheme: "waze"),
        MapApp(name: "Citymapper", icon: "tram.fill", urlScheme: "citymapper"),
    ]

    /// Returns only the map apps currently installed on the device.
    /// Apple Maps is always included.
    static func availableApps() -> [MapApp] {
        allApps.filter { app in
            // Apple Maps is built-in
            if app.urlScheme == "maps" { return true }
            guard let url = URL(string: "\(app.urlScheme)://") else { return false }
            return UIApplication.shared.canOpenURL(url)
        }
    }

    /// Opens the given map app with a search for the provided address.
    static func open(_ app: MapApp, address: String) {
        let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? address

        let urlString: String
        switch app.urlScheme {
        case "comgooglemaps":
            urlString = "comgooglemaps://?q=\(encoded)"
        case "waze":
            urlString = "waze://?q=\(encoded)"
        case "citymapper":
            urlString = "citymapper://directions?endaddress=\(encoded)"
        default:
            // Apple Maps
            urlString = "maps://?q=\(encoded)"
        }

        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}
