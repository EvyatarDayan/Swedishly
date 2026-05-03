//
//  VerbsContentView.swift
//  SWVerbs (renamed from ContentView to avoid conflict with main app)
//

import SwiftUI

struct VerbsContentView: View {
    @State private var showLogo = true

    var body: some View {
        ZStack {
            if showLogo {
                VerbsLogoView {
                    withAnimation { showLogo = false }
                }
            } else {
                MainTabView()
            }
        }
    }
}

#Preview {
    VerbsContentView()
}
