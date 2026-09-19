import Foundation

enum ScrollInputMode: String, Codable, CaseIterable, Equatable {
    case automatic = "auto"
    case trackpad
    case precisionMouse = "wheel"

    var title: String {
        switch self {
        case .automatic: "Automatic"
        case .trackpad: "Trackpad"
        case .precisionMouse: "Precision Mouse"
        }
    }

    var detail: String {
        switch self {
        case .automatic:
            "Detect gestures automatically; phased input uses the virtual touchpad."
        case .trackpad:
            "Always use native two-finger scrolling with guest-owned momentum."
        case .precisionMouse:
            "Always use high-resolution wheel events, including host momentum."
        }
    }
}

struct ScrollPreferences: Equatable {
    var mode: ScrollInputMode

    static let defaults = Self(mode: .automatic)
}

struct ScrollPreferenceStore {
    static let key = "scrollPreferences"
    static let schemaVersion = 1

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> ScrollPreferences {
        guard let data = defaults.data(forKey: Self.key),
              let payload = try? JSONDecoder().decode(Payload.self, from: data),
              payload.schemaVersion == Self.schemaVersion else {
            return .defaults
        }
        return ScrollPreferences(mode: payload.mode)
    }

    func save(_ preferences: ScrollPreferences) {
        let payload = Payload(
            schemaVersion: Self.schemaVersion,
            mode: preferences.mode
        )
        guard let data = try? JSONEncoder().encode(payload) else { return }
        defaults.set(data, forKey: Self.key)
    }

    private struct Payload: Codable {
        let schemaVersion: Int
        let mode: ScrollInputMode
    }
}

struct ScrollLaunchConfiguration: Equatable {
    static let modeEnvironmentKey = "OMARCHY_SCROLL_MODE"

    let environment: [String: String]

    static func make(
        baseEnvironment: [String: String],
        preferences: ScrollPreferences
    ) -> Self {
        var environment = baseEnvironment
        environment.removeValue(forKey: modeEnvironmentKey)
        environment[modeEnvironmentKey] = preferences.mode.rawValue
        return Self(environment: environment)
    }
}
