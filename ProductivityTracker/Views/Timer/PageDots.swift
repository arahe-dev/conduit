import SwiftUI

struct PageDots: View {
    var count: Int
    var current: Int
    var accent: Color = .white

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<max(count, 0), id: \.self) { index in
                Circle()
                    .fill(index == current ? accent.opacity(0.95) : Color.secondary.opacity(0.35))
                    .frame(width: 6, height: 6)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Space \(current + 1) of \(count)")
    }
}
