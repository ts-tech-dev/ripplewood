import SwiftUI

@main
struct RipplewoodApp: App {
    @State private var store = GameStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .fontDesign(.rounded)
        }
    }
}
