//
//  ScratchpadApp.swift
//  Scratchpad
//
//  Created by Duncan Crawbuck on 2/19/25.
//

import SwiftUI
import SwiftData

@main
struct ScratchpadApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            NoteModel.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.crawbuck.Scratchpad")
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        }
        catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            NoteView(modelContext: sharedModelContainer.mainContext)
        }
        .modelContainer(sharedModelContainer)
    }
}
