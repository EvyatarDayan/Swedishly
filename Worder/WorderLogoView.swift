//
//  WorderLogoView.swift
//  Swedishly
//

import SwiftUI
import Pow
import AVFoundation

struct WorderLogoView: View {
    @State private var showLogo = false
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
                    .opacity(opacity)
                    .transition(
                        .identity
                            .animation(.linear(duration: 2.5).delay(2.5))
                            .combined(with: .movingParts.glare)
                    )
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
                withAnimation(.easeOut(duration: 1)) {
                    opacity = 0
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    onAnimationComplete()
                    withAnimation(.easeOut(duration: 1)) {
                        backgroundOpacity = 0
                    }
                }
            }
        }
    }
}

#if DEBUG
struct WorderLogoView_Previews: PreviewProvider {
    static var previews: some View {
        WorderLogoView {
            print("Animation complete")
        }
    }
}
#endif
