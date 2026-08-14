import SwiftUI

struct SaveTimeButton: View {
    var enabled: Bool
    var isActivePage: Bool
    var onSave: () -> Void
    var onOpenHistory: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)
        Button(action: onSave) {
            Image(systemName: "square.and.arrow.down")
                .font(.body.weight(.semibold))
                .foregroundStyle(enabled ? Color.white : Color.white.opacity(0.35))
                .frame(width: 36, height: 36)
                .background(shape.fill(Color.white.opacity(enabled ? 0.16 : 0.07)))
                .overlay {
                    shape.strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
                }
                .glassEffect(.regular.tint(.white.opacity(0.10)).interactive(), in: shape)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel("Save time")
        .accessibilityHint("Saves the current elapsed time without resetting. Long press to view saved times.")
        .accessibilityIdentifier(isActivePage ? AccessibilityIDs.saveTimeButton : "save-time-button-idle")
        .onLongPressGesture(minimumDuration: 0.45, perform: onOpenHistory)
        .frame(minWidth: 44, minHeight: 44)
    }
}
