import Foundation
import Testing
@testable import OmarchyVMHelper

@Suite("Scroll preferences")
struct ScrollPreferenceStoreTests {
    @Test("Automatic routing is the default")
    func defaultsToAutomatic() {
        let fixture = DefaultsFixture()

        #expect(fixture.store.load() == .defaults)
        #expect(fixture.store.load().mode == .automatic)
    }

    @Test("The selected virtual input device persists")
    func savesChoice() {
        let fixture = DefaultsFixture()
        fixture.store.save(ScrollPreferences(mode: .precisionMouse))

        let reopened = ScrollPreferenceStore(defaults: fixture.defaults)
        #expect(reopened.load() == ScrollPreferences(mode: .precisionMouse))
    }

    @Test("Invalid or future preferences fail safely")
    func invalidPreferencesUseDefault() throws {
        let fixture = DefaultsFixture()
        fixture.defaults.set(Data("junk".utf8), forKey: ScrollPreferenceStore.key)
        #expect(fixture.store.load() == .defaults)

        let future = try JSONSerialization.data(withJSONObject: [
            "schemaVersion": ScrollPreferenceStore.schemaVersion + 1,
            "mode": ScrollInputMode.trackpad.rawValue,
        ])
        fixture.defaults.set(future, forKey: ScrollPreferenceStore.key)
        #expect(fixture.store.load() == .defaults)
    }

    private final class DefaultsFixture {
        let suiteName = "ScrollPreferenceStoreTests.\(UUID().uuidString)"
        let defaults: UserDefaults
        let store: ScrollPreferenceStore

        init() {
            defaults = UserDefaults(suiteName: suiteName)!
            defaults.removePersistentDomain(forName: suiteName)
            store = ScrollPreferenceStore(defaults: defaults)
        }

        deinit {
            defaults.removePersistentDomain(forName: suiteName)
        }
    }
}

@Suite("Scroll launch configuration")
struct ScrollLaunchConfigurationTests {
    @Test("Publishes each mode and replaces inherited values")
    func publishesChoice() {
        for mode in ScrollInputMode.allCases {
            let launch = ScrollLaunchConfiguration.make(
                baseEnvironment: [
                    "KEEP_ME": "yes",
                    ScrollLaunchConfiguration.modeEnvironmentKey: "invalid",
                ],
                preferences: ScrollPreferences(mode: mode)
            )

            #expect(launch.environment["KEEP_ME"] == "yes")
            #expect(
                launch.environment[ScrollLaunchConfiguration.modeEnvironmentKey]
                    == mode.rawValue
            )
        }
    }
}
