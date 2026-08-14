import SwiftUI

struct SpaceIconPicker: View {
    @Binding var icon: SpaceIcon
    var name: String
    var tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                SpaceIconView(icon: icon, tint: tint, pointSize: 56)
                Spacer()
            }

            Picker("Icon", selection: kindBinding) {
                Text("Symbols").tag(SpaceIconKind.symbol)
                Text("Emoji").tag(SpaceIconKind.emoji)
                Text("Letters").tag(SpaceIconKind.monogram)
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("icon-kind-picker")

            switch icon.kind {
            case .symbol:
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 10)], spacing: 10) {
                    ForEach(SpaceIcon.symbols, id: \.self) { symbol in
                        iconCell(selected: icon.value == symbol) {
                            icon = SpaceIcon(kind: .symbol, value: symbol)
                        } content: {
                            Image(systemName: symbol)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                        .accessibilityIdentifier("icon-symbol-\(symbol)")
                    }
                }
            case .emoji:
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 10)], spacing: 10) {
                    ForEach(SpaceIcon.emojis, id: \.self) { emoji in
                        iconCell(selected: icon.value == emoji) {
                            icon = SpaceIcon(kind: .emoji, value: emoji)
                        } content: {
                            Text(emoji).font(.title3)
                        }
                        .accessibilityIdentifier("icon-emoji-\(emoji)")
                    }
                }
            case .monogram:
                TextField("2–3 letters", text: monogramBinding)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("icon-monogram-field")
                Button("Use initials") {
                    icon = .monogram(from: name)
                }
                .accessibilityIdentifier("icon-monogram-initials")
            }
        }
    }

    private var kindBinding: Binding<SpaceIconKind> {
        Binding(
            get: { icon.kind },
            set: { kind in
                switch kind {
                case .symbol:
                    icon = SpaceIcon(kind: .symbol, value: SpaceIcon.symbols.contains(icon.value) ? icon.value : SpaceIcon.fallback.value)
                case .emoji:
                    icon = SpaceIcon(kind: .emoji, value: SpaceIcon.emojis.contains(icon.value) ? icon.value : SpaceIcon.emojis[0])
                case .monogram:
                    icon = icon.kind == .monogram ? icon : .monogram(from: name)
                }
            }
        )
    }

    private var monogramBinding: Binding<String> {
        Binding(
            get: { icon.monogramText },
            set: { newValue in
                let filtered = newValue.uppercased().filter(\.isLetter)
                icon = SpaceIcon(kind: .monogram, value: String(filtered.prefix(3)))
            }
        )
    }

    private func iconCell<Content: View>(selected: Bool, action: @escaping () -> Void, @ViewBuilder content: () -> Content) -> some View {
        Button(action: action) {
            content()
                .frame(width: 44, height: 44)
                .background(Circle().fill(selected ? tint.opacity(0.55) : Color.white.opacity(0.08)))
                .overlay {
                    Circle().strokeBorder(selected ? Color.white.opacity(0.85) : Color.white.opacity(0.12), lineWidth: selected ? 2 : 1)
                }
        }
        .buttonStyle(.plain)
    }
}
