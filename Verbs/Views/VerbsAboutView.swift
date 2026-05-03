//
//  VerbsAboutView.swift
//  SWVerbs (renamed from AboutView to avoid conflict with Vocabulary)
//

import SwiftUI

struct VerbsAboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About SWVerbs")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("SWVerbs is a comprehensive Swedish verb learning app designed to help you master Swedish verbs with ease. Practice verb conjugations, test your knowledge, and track your progress. Learn verb forms in present, past, and perfect tenses with accurate translations and example sentences. Never miss a learning opportunity again.")
                            .font(.body)
                            .multilineTextAlignment(.leading)
                    }
                    Divider()
                        .padding(.vertical, 8)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About ABASHELARI")
                            .font(.title2)
                            .fontWeight(.bold)
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
                    SplitTitleView("About", splitIndex: 2)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

#Preview {
    VerbsAboutView()
}
