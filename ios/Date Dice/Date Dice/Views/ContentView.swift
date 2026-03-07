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

            DiscoverView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Discover")
                }

            HistoryView()
                .tabItem {
                    Image(systemName: "clock")
                    Text("History")
                }
                .badge(vm.upcomingCount > 0 ? vm.upcomingCount : 0)

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
