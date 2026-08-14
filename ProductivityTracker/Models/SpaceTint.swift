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
        case .orange: Color(red: 1.00, green: 0.62, blue: 0.18)
        case .blue: Color(red: 0.36, green: 0.62, blue: 1.00)
        case .teal: Color(red: 0.32, green: 0.86, blue: 0.78)
        case .purple: Color(red: 0.76, green: 0.52, blue: 1.00)
        case .green: Color(red: 0.42, green: 0.86, blue: 0.50)
        case .red: Color(red: 1.00, green: 0.42, blue: 0.40)
        case .yellow: Color(red: 1.00, green: 0.84, blue: 0.28)
        case .indigo: Color(red: 0.54, green: 0.56, blue: 1.00)
        case .pink: Color(red: 1.00, green: 0.50, blue: 0.70)
        case .gray: Color(red: 0.78, green: 0.80, blue: 0.84)
        }
    }

    var wash: Color {
        color.opacity(0.16)
    }

    static func parse(_ raw: String) -> SpaceTint? {
        let key = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return SpaceTint(rawValue: key)
    }
}
