//
//  GrammarLogoView.swift
//  SWGrammar (renamed from LogoView.swift to avoid duplicate build output)
//
//  Created by EVYATAR DAYAN on 2026-01-19.
//

import SwiftUI
import AVFoundation

struct GrammarLogoView: View {
    @State private var showLogo = false
    @State private var startExit = false
    @State private var opacity = 1.0
    @State private var backgroundOpacity = 1.0
    @State private var audioPlayer: AVAudioPlayer?
    let onAnimationComplete: () -> Void

    private var isIPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }

    private func playLogoSound() {
        // Try multiple paths to find the audio file
        var audioURL: URL?

        // Try with Music directory
        if let path = Bundle.main.path(forResource: "logo3", ofType: "mp3", inDirectory: "Music") {
            audioURL = URL(fileURLWithPath: path)
        }
        // Try without directory
        else if let url = Bundle.main.url(forResource: "logo3", withExtension: "mp3", subdirectory: "Music") {
            audioURL = url
        }
        // Try in main bundle
        else if let url = Bundle.main.url(forResource: "logo3", withExtension: "mp3") {
            audioURL = url
        }

        guard let url = audioURL else {
            print("Could not find logo3.mp3 in bundle")
            return
        }

        do {
            // Set up audio session
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)

            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            print("Playing logo sound from: \(url)")
        } catch {
            print("Could not play sound file: \(error)")
        }
    }

    var body: some View {
        ZStack {
            // Background - now with its own opacity
            Color.white
                .ignoresSafeArea()
                .opacity(backgroundOpacity)

            // Logo text
            if showLogo {
                Image("AbaShelAriLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: isIPhone ? 350 : 700)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.1))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .foregroundColor(.white)
                    .transition(
                        .identity
                            .animation(.linear(duration: 2.5).delay(2.5))
                            .combined(with: .opacity)
                    )
                    .opacity(opacity)
            }
        }
        .onAppear {
            // Delay the start of the logo animation
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                withAnimation {
                    showLogo = true
                    // Play logo sound when the logo appears
                    playLogoSound()
                }
            }

            // Duration of logo display
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                // First fade out the logo
                withAnimation(.easeOut(duration: 1)) {
                    opacity = 0
                }

                // Start fading out the background and trigger main view
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    // Trigger main view to appear
                    onAnimationComplete()

                    // Fade out background slowly
                    withAnimation(.easeOut(duration: 1)) {
                        backgroundOpacity = 0
                    }
                }
            }
        }
    }
}

#Preview {
    GrammarLogoView {
        print("Animation complete")
    }
}
