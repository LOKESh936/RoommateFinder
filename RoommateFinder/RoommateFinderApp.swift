//
//  RoommateFinderApp.swift
//  RoommateFinder
//
//  Created by Lokeshwar Reddy Malli reddy on 2/10/25.
//

import SwiftUI

@main
struct RoommateFinderApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
