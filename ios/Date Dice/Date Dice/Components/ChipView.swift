import SwiftUI

struct ChipView: View {
    let label: String
    let active: Bool
    var small = false
    var action: () -> Void = {}

    var body: some View {
        Button(action: {
            Haptics.chipTap()
            action()
        }) {
            Text(label)
                .font(.system(size: small ? 12 : 14, weight: active ? .semibold : .regular))
                .foregroundStyle(active ? Theme.background : Theme.text)
                .padding(.horizontal, small ? 10 : 14)
                .padding(.vertical, small ? 6 : 8)
                .background(active ? Theme.gold : Theme.cardBackground)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(active ? Theme.gold : Theme.cardBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
