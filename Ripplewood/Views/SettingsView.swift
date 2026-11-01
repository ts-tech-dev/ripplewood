import SwiftUI

struct SettingsView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Sound & feel") {
                    Toggle("Sound effects", isOn: Binding(get: { store.settings.sound }, set: { store.setSound($0) }))
                    Toggle("Ambient music", isOn: Binding(get: { store.settings.music }, set: { store.setMusic($0) }))
                    Toggle("Haptics", isOn: Binding(get: { store.settings.haptics }, set: { store.setHaptics($0) }))
                }

                Section("Ripplewood") {
                    LabeledContent("Fish caught", value: "\(store.data.totalCaught)")
                    LabeledContent("Species discovered", value: "\(store.discoveredCount) / \(FishCatalog.all.count)")
                    LabeledContent("Coins earned", value: "\(store.data.lifetimeCoins)")
                }

                Section {
                    Button("Reset progress", role: .destructive) { confirmReset = true }
                } footer: {
                    Text("Clears coins, fish, the Fish Log and all pond restoration.")
                }

                #if DEBUG
                Section("Debug") {
                    Picker("Time of day", selection: Binding(get: { store.timeOverride }, set: { store.setTimeOverride($0) })) {
                        Text("Device clock").tag(TimeOfDay?.none)
                        ForEach(TimeOfDay.allCases) { time in
                            Text(time.label).tag(Optional(time))
                        }
                    }
                    Picker("Weather", selection: Binding(get: { store.weatherOverride }, set: { store.setWeatherOverride($0) })) {
                        Text("Forecast").tag(Weather?.none)
                        ForEach(Weather.allCases) { weather in
                            Text(weather.label).tag(Optional(weather))
                        }
                    }
                    Button("Add 1,000 coins") { store.debugAddCoins(1000) }
                    Button("Simulate 8 hours away") {
                        dismiss()
                        store.debugSimulateAway(hours: 8)
                    }
                    Button("Unlock all upgrades") { store.debugUnlockAll() }
                }
                #endif
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Reset all progress?", isPresented: $confirmReset) {
                Button("Reset", role: .destructive) {
                    store.resetProgress()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your coins, fish, Fish Log and pond restoration will be cleared. This can't be undone.")
            }
        }
    }
}
