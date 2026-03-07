import SwiftUI

struct HistoryView: View {
    @Environment(AppViewModel.self) private var vm

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if vm.history.isEmpty {
                    // MARK: - Empty State
                    VStack(spacing: 12) {
                        Text("\u{1F3B2}")
                            .font(.system(size: 48))

                        Text("No rolls yet")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Theme.text)

                        Text("Roll the dice to start building your history")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 40)
                } else {
                    // MARK: - History List
                    List {
                        ForEach(vm.history) { item in
                            HStack(spacing: 12) {
                                Text(item.emoji)
                                    .font(.system(size: 28))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(Theme.gold)

                                    Text(item.area)
                                        .font(.system(size: 13))
                                        .foregroundStyle(Theme.textSecondary)
                                }

                                Spacer()

                                Text(item.rolledAt, style: .relative)
                                    .font(.system(size: 11))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            .listRowBackground(Theme.cardBackground)
                            .listRowSeparatorTint(Theme.cardBorder)
                        }
                        .onDelete(perform: vm.removeHistory)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview {
    HistoryView()
        .environment(AppViewModel())
}
