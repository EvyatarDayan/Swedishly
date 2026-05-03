//
//  SWVerbsApp.swift
//  SWVerbs
//
//  Created by EVYATAR DAYAN on 2026-01-05.
//

import SwiftUI

/// Not used as entry point when Verbs is part of Swedishly; SwedishlyApp has @main.
struct SWVerbsApp: App {
    @AppStorage("darkModeEnabled") private var darkModeEnabled: Bool = false
    
    var body: some Scene {
        WindowGroup {
            VerbsContentView()
                .preferredColorScheme(darkModeEnabled ? .dark : nil)
        }
    }
}
