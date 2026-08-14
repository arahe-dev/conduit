import SwiftUI

struct PageDots: View {
    var count: Int
    var current: Int
    var accent: Color = .white
    var composeAtEnd: Bool = false

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<max(count, 0), id: \.self) { index in
                if composeAtEnd && index == count - 1 {
                    Image(systemName: "plus")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(index == current ? accent : Color.secondary.opacity(0.55))
                        .frame(width: 8, height: 8)
                } else {
                    Circle()
                        .fill(index == current ? accent.opacity(0.95) : Color.secondary.opacity(0.35))
                        .frame(width: 6, height: 6)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Space \(current + 1) of \(count)")
    }
}
