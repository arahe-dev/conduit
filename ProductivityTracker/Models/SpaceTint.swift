import Foundation
import SwiftUI

enum SpaceTint: String, Codable, CaseIterable, Sendable, Identifiable {
    case orange
    case blue
    case teal
    case purple
    case green
    case red
    case yellow
    case indigo
    case pink
    case gray

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var color: Color {
        switch self {
        case .orange: .orange
        case .blue: .blue
        case .teal: .teal
        case .purple: .purple
        case .green: .green
        case .red: .red
        case .yellow: .yellow
        case .indigo: .indigo
        case .pink: .pink
        case .gray: .gray
        }
    }

    static func parse(_ raw: String) throws -> SpaceTint {
        let key = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let value = SpaceTint(rawValue: key) {
            return value
        }
        throw SpaceImportError.invalidColor(raw)
    }
}
