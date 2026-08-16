import Foundation

enum SpaceIconKind: String, Codable, CaseIterable, Sendable {
    case symbol
    case emoji
    case monogram
}

struct SpaceIcon: Equatable, Hashable, Sendable {
    var kind: SpaceIconKind
    var value: String

    static let work = SpaceIcon(kind: .symbol, value: "briefcase.fill")
    static let chores = SpaceIcon(kind: .symbol, value: "house.fill")
    static let personal = SpaceIcon(kind: .symbol, value: "heart.fill")
    static let fallback = SpaceIcon(kind: .symbol, value: "square.grid.2x2.fill")

    static let symbols: [String] = [
        "briefcase.fill",
        "house.fill",
        "heart.fill",
        "book.fill",
        "laptopcomputer",
        "phone.fill",
        "envelope.fill",
        "hammer.fill",
        "leaf.fill",
        "dumbbell.fill",
        "figure.walk",
        "paintbrush.fill",
        "music.note",
        "cart.fill",
        "airplane",
        "car.fill",
        "fork.knife",
        "cup.and.saucer.fill",
        "moon.fill",
        "sun.max.fill",
        "star.fill",
        "bolt.fill",
        "flag.fill",
        "folder.fill",
        "person.fill",
        "bubble.left.and.bubble.right.fill"
    ]

    static let emojis: [String] = [
        "⚡️", "🎯", "📚", "🏠", "💼", "💪", "🎨", "🧪",
        "✉️", "🧠", "☕️", "🎵", "🌱", "🚀", "📝", "🎧"
    ]

    var monogramText: String {
        let filtered = value.uppercased().filter(\.isLetter)
        if filtered.isEmpty { return "AA" }
        return String(filtered.prefix(3))
    }

    static func monogram(from name: String) -> SpaceIcon {
        let words = name.split(separator: " ").prefix(3)
        let letters: String
        if words.count >= 2 {
            letters = words.compactMap { $0.first }.map(String.init).joined()
        } else {
            letters = String(name.filter(\.isLetter).prefix(2)).uppercased()
        }
        let value = letters.isEmpty ? "NW" : letters.uppercased()
        return SpaceIcon(kind: .monogram, value: value)
    }
}
