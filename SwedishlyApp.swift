//
//  SwedishlyApp.swift
//  Swedishly
//
//  Created by EVYATAR DAYAN on 2026-03-07.
//

import SwiftUI

@main
struct SwedishlyApp: App {
    /// Shown on cold launch; dismissed after `LogoView` finishes (see delay for background fade).
    @State private var showLogoSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                if showLogoSplash {
                    LogoView {
                        // `LogoView` calls this, then fades the white background over ~1s — keep splash until that finishes.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.05) {
                            showLogoSplash = false
                        }
                    }
                    .ignoresSafeArea()
                    .zIndex(1)
                }
            }
        }
    }
}
