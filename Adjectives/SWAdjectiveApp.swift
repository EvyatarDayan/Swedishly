//
//  SwedisherApp.swift
//  Swedisher
//
//  Created by EVYATAR DAYAN on 2026-01-28.
//

import SwiftUI

struct SWAdjectiveApp: App {
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    
    var body: some Scene {
        WindowGroup {
            AdjectivesContentView()
                .preferredColorScheme(darkModeEnabled ? .dark : .light)
        }
    }
}
