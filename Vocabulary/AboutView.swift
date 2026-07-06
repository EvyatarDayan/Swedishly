//
//  AboutView.swift
//  SWVocabulary
//
//  Created by EVYATAR DAYAN on 2026-01-26.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // App Version
                    VStack(alignment: .center, spacing: 8) {
                        Text(appVersion)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // About Swedishly Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About Swedishly")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.appRed)
                        
                        Text("Swedishly is a comprehensive Swedish learning app that brings together vocabulary, grammar, verbs, adjectives, and word order into a single, unified experience. Practice with multiple-choice questions, translation exercises, and structured tests across all topics, and track your progress over time. Learn Swedish words with accurate English translations and example sentences, build strong grammar foundations, and master sentence structure step by step.")
                            .font(.body)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // About ABASHELARI Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About ABASHELARI")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.appRed)
                        
                        Text("At ABASHELARI, we believe in creating software that makes everyday life simpler, smarter, and more enjoyable. Our mission is to develop innovative digital solutions that blend creativity with technology, offering users tools that are intuitive, reliable, and engaging.")
                            .font(.body)
                            .multilineTextAlignment(.leading)
                        
                        Text("Whether it's educational apps, lifestyle tools, or entertainment experiences, ABASHELARI is dedicated to delivering high-quality products that inspire learning, spark curiosity, and bring value to people around the world.")
                            .font(.body)
                            .multilineTextAlignment(.leading)
                        
                        Text("Driven by passion and guided by innovation, ABASHELARI is committed to continuous improvement and to building software that connects people with what matters most.")
                            .font(.body)
                            .multilineTextAlignment(.leading)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("About")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.appRed)
                }
                SettingsModalToolbarItem(placement: .navigationBarTrailing) {
                    SettingsModalPlainButton(title: "Done", action: { dismiss() })
                }
            }
        }
    }
}

#Preview {
    AboutView()
}
