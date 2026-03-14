import Foundation

@MainActor
@Observable
final class UserDefaultsStore {
    static let shared = UserDefaultsStore()
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let lastSearchQuery = "lastSearchQuery"
    }

    var hasSeenOnboarding: Bool {
        get { defaults.bool(forKey: Keys.hasSeenOnboarding) }
        set { defaults.set(newValue, forKey: Keys.hasSeenOnboarding) }
    }

    var lastSearchQuery: String? {
        get { defaults.string(forKey: Keys.lastSearchQuery) }
        set { defaults.set(newValue, forKey: Keys.lastSearchQuery) }
    }
}
