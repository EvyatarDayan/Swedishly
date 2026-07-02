//
//  LogoView.swift
//  Swedishly
//
//  Created by EVYATAR DAYAN on 2026-01-28.
//

import SwiftUI

enum WelcomeStorage {
    static let skipWelcomeKey = "skipWelcomeScreen"
}

struct LogoView: View {
    var onStart: () -> Void
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @AppStorage(WelcomeStorage.skipWelcomeKey) private var skipWelcomeScreen = false
    @State private var dontShowAgain = false

    var body: some View {
        ZStack {
            (darkModeEnabled ? Color.black : Color(.systemGroupedBackground))
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 20) {
                    logoView

                    SplitTitleView("Swedishly", splitIndex: 5, fontSize: 34)

                    Text("Practice vocabulary, grammar, verbs, adjectives, and word order -  everything you need to learn Swedish, all in one app.")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 4)

                    Button(action: startApp) {
                        Text("Get Started")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    }
                    .padding(.top, 70)
                }
                .padding(.horizontal, 32)

                Spacer()

                Button {
                    dontShowAgain.toggle()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: dontShowAgain ? "checkmark.square.fill" : "square")
                            .font(.title3)
                            .foregroundStyle(dontShowAgain ? Color.blue : Color.gray)

                        Text("Don't show this again")
                            .font(.subheadline)
                            .foregroundStyle(.gray)

                        Spacer(minLength: 0)
                    }
                    .padding(.bottom, 20)
                    .padding(.leading, 20)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
        .preferredColorScheme(darkModeEnabled ? .dark : .light)
    }

    private func startApp() {
        if dontShowAgain {
            skipWelcomeScreen = true
        }
        onStart()
    }

    private var logoView: some View {
        Image("Talking")
            .resizable()
            .scaledToFit()
            .frame(width: 160, height: 160)
    }
}

#Preview {
    LogoView(onStart: {})
}
