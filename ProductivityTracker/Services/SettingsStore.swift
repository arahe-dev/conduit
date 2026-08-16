import Foundation

@MainActor
final class SettingsStore {
    static let selectedSpaceKey = "selectedSpaceID"
    static let distractionTimeoutKey = "distractionTimeoutSeconds"
    static let preferDarkKey = "preferDarkAppearance"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var selectedSpaceID: UUID? {
        get {
            defaults.string(forKey: Self.selectedSpaceKey).flatMap(UUID.init(uuidString:))
        }
        set {
            defaults.set(newValue?.uuidString, forKey: Self.selectedSpaceKey)
        }
    }

    var distractionTimeoutSeconds: TimeInterval {
        get {
            let value = defaults.double(forKey: Self.distractionTimeoutKey)
            return value > 0 ? value : 300
        }
        set {
            defaults.set(newValue, forKey: Self.distractionTimeoutKey)
        }
    }

    var preferDarkAppearance: Bool {
        get {
            if defaults.object(forKey: Self.preferDarkKey) == nil {
                return true
            }
            return defaults.bool(forKey: Self.preferDarkKey)
        }
        set {
            defaults.set(newValue, forKey: Self.preferDarkKey)
        }
    }
}
