//
//  VerbsLogoView.swift
//  SWVerbs (renamed from LogoView to avoid conflict)
//

import SwiftUI
import AVFoundation

struct VerbsLogoView: View {
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
        if let path = Bundle.main.path(forResource: "logo3", ofType: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                audioPlayer?.play()
            } catch {
                print("Could not play sound file: \(error)")
            }
        }
    }

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
                .opacity(backgroundOpacity)

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
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                withAnimation {
                    showLogo = true
                    playLogoSound()
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeOut(duration: 1)) { opacity = 0 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    onAnimationComplete()
                    withAnimation(.easeOut(duration: 1)) { backgroundOpacity = 0 }
                }
            }
        }
    }
}

#Preview {
    VerbsLogoView { print("Animation complete") }
}
