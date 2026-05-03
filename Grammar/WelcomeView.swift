//
//  WelcomeView.swift
//  SWGrammar
//
//  Created by EVYATAR DAYAN on 2026-01-19.
//

import SwiftUI

struct WelcomeView: View {
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @State private var dontShowAgain = false
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            // Background with blur effect
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    closeWelcome()
                }
            
            // Welcome card
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Text("Welcome to SWGrammar!")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.primary)
                    
//                    Text("Master Swedish Grammar")
//                        .font(.system(size: 18, weight: .medium))
//                        .foregroundColor(.secondary)
                }
                .padding(.top, 30)
                .padding(.bottom, 20)
                
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Introduction
                        Text("Practice and improve your Swedish grammar skills with interactive quizzes covering essential topics.")
                            .font(.body)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.horizontal)
                        
                        // Features
                        VStack(alignment: .leading, spacing: 20) {
                            FeatureRow(
                                icon: "verbs",
                                title: "Verbs",
                                description: "Master Swedish verb conjugations with 10 random questions per round. Practice different verb forms and tenses."
                            )
                            
                            FeatureRow(
                                icon: "gender",
                                title: "Noun Gender",
                                description: "Learn Swedish noun genders (en/ett) with realistic 80/20 distribution. Build your vocabulary while practicing."
                            )
                            
                            FeatureRow(
                                icon: "pronouns",
                                title: "Pronouns",
                                description: "Practice personal pronouns in Swedish. Understand when and how to use different pronoun forms correctly."
                            )
                        }
                        .padding(.horizontal)
                        
                        // Benefits
                        VStack(alignment: .leading, spacing: 12) {
                            Text("What you'll get:")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            BenefitRow(text: "Instant feedback on every answer")
                            BenefitRow(text: "Audio pronunciation for better learning")
                            BenefitRow(text: "Track your progress with test history")
                            BenefitRow(text: "Review past tests and retake them")
                            BenefitRow(text: "Practice at your own pace")
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    .padding(.vertical, 20)
                }
                
                Divider()
                    .padding(.vertical, 12)
                
                // Footer with checkbox and button
                VStack(spacing: 16) {
                    // Don't show again checkbox
                    Button(action: {
                        dontShowAgain.toggle()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: dontShowAgain ? "checkmark.square.fill" : "square")
                                .font(.system(size: 18))
                                .foregroundColor(dontShowAgain ? .blue : .secondary)
                            Text("Don't show this again")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    // Close button
                    Button(action: {
                        closeWelcome()
                    }) {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 20)
                .padding(.horizontal, 20)
            }
            .frame(maxWidth: 500)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 20)
        }
    }
    
    private func closeWelcome() {
        if dontShowAgain {
            hasSeenWelcome = true
        }
        isPresented = false
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            Image(icon)
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .foregroundColor(.blue)
            
            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct BenefitRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(.green)
                .padding(.top, 2)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    WelcomeView(isPresented: .constant(true))
}
