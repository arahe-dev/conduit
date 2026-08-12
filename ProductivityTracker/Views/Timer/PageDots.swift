import SwiftUI

struct PageDots: View {
    var count: Int
    var current: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<max(count, 0), id: \.self) { index in
                Circle()
                    .fill(index == current ? Color.primary.opacity(0.85) : Color.secondary.opacity(0.35))
                    .frame(width: index == current ? 6.5 : 5.5, height: index == current ? 6.5 : 5.5)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Space \(current + 1) of \(count)")
    }
}
