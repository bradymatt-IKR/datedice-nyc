import SwiftUI

struct ContentView: View {
    @Environment(AppViewModel.self) private var vm

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "dice")
                    Text("Roll")
                }

            HistoryView()
                .tabItem {
                    Image(systemName: "clock")
                    Text("History")
                }

            FavoritesView()
                .tabItem {
                    Image(systemName: "heart")
                    Text("Favorites")
                }
        }
        .tint(Theme.gold)
    }
}

#Preview {
    ContentView()
        .environment(AppViewModel())
}
