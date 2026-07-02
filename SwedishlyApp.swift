//
//  SwedishlyApp.swift
//  Swedishly
//
//  Created by EVYATAR DAYAN on 2026-03-07.
//

import SwiftUI

@main
struct SwedishlyApp: App {
    @AppStorage(WelcomeStorage.skipWelcomeKey) private var skipWelcomeScreen = false
    @State private var showWelcome = true

    private var shouldShowWelcome: Bool {
        !skipWelcomeScreen && showWelcome
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if !shouldShowWelcome {
                    ContentView()
                }

                if shouldShowWelcome {
                    LogoView {
                        showWelcome = false
                    }
                    .ignoresSafeArea()
                    .zIndex(1)
                }
            }
        }
    }
}
