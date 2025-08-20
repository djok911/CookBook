//
//  CookBookApp.swift
//  CookBook
//
//  Created by Ivan Huttunen on 20.08.2025.
//

import SwiftUI

@main
struct CookBookApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            RecipeListView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
