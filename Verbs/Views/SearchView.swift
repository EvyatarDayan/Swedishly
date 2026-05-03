//
//  SearchView.swift
//  SWVerbs
//
//  Created by EVYATAR DAYAN on 2026-01-05.
//

import SwiftUI

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = VerbViewModel()
    @State private var selectedVerb: Verb?

    var body: some View {
        VStack(spacing: 0) {
            BackButtonRow(onBack: { dismiss() })
            // Search Bar
            SearchBar(text: $viewModel.searchText)
                    .padding(.horizontal)
                    .padding(.top, 24)
                    .padding(.bottom, 18)
                
                // Content
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading verbs...")
                        .foregroundColor(.secondary)
                        .padding(.top)
                    Spacer()
                } else if let error = viewModel.errorMessage {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text("Error")
                            .font(.headline)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Retry") {
                            viewModel.loadVerbs()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    Spacer()
                } else if viewModel.filteredVerbs.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("No verbs found")
                            .font(.headline)
                        Text("Try searching for a different verb")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    // Verb List
                    List(viewModel.filteredVerbs) { verb in
                        VerbRow(verb: verb, onOpen: {
                            selectedVerb = verb
                        })
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedVerb = verb
                            }
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    SplitTitleView("SWVerbs", splitIndex: 7)
                }
            }
            .sheet(item: $selectedVerb) { verb in
                VerbDetailView(verb: verb)
            }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct SearchBar: View {
    @Binding var text: String
    @Environment(\.colorScheme) var colorScheme
    var placeholder: String = "Search for a verb..."
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(colorScheme == .light ? Color.white : Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct VerbRow: View {
    @Environment(\.colorScheme) var colorScheme
    let verb: Verb
    var onOpen: (() -> Void)? = nil
    @StateObject private var speechSynthesizer = SpeechSynthesizer()
    @State private var isPlaying = false
    
    var body: some View {
        HStack {
            // Audio button on the left
            Button(action: {
                if isPlaying {
                    speechSynthesizer.stop()
                    isPlaying = false
                } else {
                    speechSynthesizer.speak(verb.infinitive, language: "sv-SE") {
                        isPlaying = false
                    }
                    isPlaying = true
                }
            }) {
                Image("audio-headphone")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .opacity(isPlaying ? 0.5 : 1.0)
                    .animation(
                        isPlaying ? Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true) : .default,
                        value: isPlaying
                    )
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            VStack(alignment: .center, spacing: 4) {
                Text(verb.infinitive)
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                if !verb.english.isEmpty && verb.english[0] != "translation" {
                    Text(verb.english.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Open button on the right
            Button(action: {
                onOpen?()
            }) {
                Image("play-button")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 37, height: 37)
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    SearchView()
}

