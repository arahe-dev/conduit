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
        case .orange: Color(red: 1.00, green: 0.55, blue: 0.10)
        case .blue: Color(red: 0.22, green: 0.56, blue: 1.00)
        case .teal: Color(red: 0.18, green: 0.82, blue: 0.78)
        case .purple: Color(red: 0.72, green: 0.42, blue: 1.00)
        case .green: Color(red: 0.34, green: 0.86, blue: 0.44)
        case .red: Color(red: 1.00, green: 0.35, blue: 0.32)
        case .yellow: Color(red: 1.00, green: 0.80, blue: 0.16)
        case .indigo: Color(red: 0.42, green: 0.45, blue: 0.98)
        case .pink: Color(red: 1.00, green: 0.40, blue: 0.64)
        case .gray: Color(red: 0.72, green: 0.74, blue: 0.78)
        }
    }

    var wash: Color {
        color.opacity(0.42)
    }

    static func parse(_ raw: String) -> SpaceTint? {
        let key = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return SpaceTint(rawValue: key)
    }
}
