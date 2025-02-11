import SwiftUI
import Firebase
import FirebaseAuth

@main
struct RoommateFinderApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}


