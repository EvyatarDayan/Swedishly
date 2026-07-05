//
//  AppFavoritesView.swift
//  Swedishly
//
//  Unified Favorites view: Vocabulary (My List), Worder (favorite sentences), Verbs (favorite verbs).
//

import SwiftUI

struct AppFavoritesView: View {
    @StateObject private var vocabularyMyList = MyListManager.shared
    @StateObject private var worderMyList = WorderMyListManager.shared
    @StateObject private var verbFavorites = FavoriteManager.shared
    @Environment(\.colorScheme) var colorScheme

    @State private var selectedVocabularyWord: MyListWord?
    @State private var selectedWorderWord: WorderMyListWord?
    @State private var selectedVerb: Verb?
    @State private var selectedFilter: FavoritesFilterOption = .all

    enum FavoritesFilterOption: String, CaseIterable {
        case all = "All"
        case vocabulary = "Vocabulary"
        case worder = "Word Order"
        case verbs = "Verbs"
    }

    private var vocabularyWords: [MyListWord] { vocabularyMyList.getMyListWords() }
    private var worderSentences: [WorderMyListWord] { worderMyList.getMyListWords() }
    private var verbFavoritesList: [Verb] { verbFavorites.favorites }

    private var hasAnyFavorites: Bool {
        !vocabularyWords.isEmpty || !worderSentences.isEmpty || !verbFavoritesList.isEmpty
    }

    private var hasItemsForCurrentFilter: Bool {
        switch selectedFilter {
        case .all: return hasAnyFavorites
        case .vocabulary: return !vocabularyWords.isEmpty
        case .worder: return !worderSentences.isEmpty
        case .verbs: return !verbFavoritesList.isEmpty
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Title (same style as History when used as main tab)
            HStack {
                Spacer()
                SplitTitleView("Favorites", splitIndex: 5)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 20)

            // Filter controls (same design as History view)
            if hasAnyFavorites {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(FavoritesFilterOption.allCases, id: \.self) { option in
                            Button(action: {
                                selectedFilter = option
                            }) {
                                Text(option.rawValue)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(selectedFilter == option ? .white : .primary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(selectedFilter == option ? Color.appRed : Color(.systemGray5))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 15)
                .padding(.top, 10)
            }

            if !hasAnyFavorites {
                emptyStateView
            } else if !hasItemsForCurrentFilter {
                filterEmptyStateView
            } else {
                listView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .ignoresSafeArea(edges: .bottom)
        .sheet(item: $selectedVocabularyWord) { word in
            MyListWordDetailModal(word: word)
        }
        .sheet(item: $selectedWorderWord) { word in
            WorderMyListWordDetailModal(word: word)
        }
        .sheet(item: $selectedVerb) { verb in
            VerbDetailView(verb: verb, useAppRedMoreInfoStyle: true)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 30) {
            Spacer()
            Image(systemName: "star")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No favorites yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            Text("Add your favorite items here by tapping the star icon while browsing Vocabulary, Word Order, or Verbs.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 35)
            Spacer()
        }
    }

    private var filterEmptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "star.slash")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("No favorites in this category")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            Text("Add items from \(selectedFilter.rawValue) to see them here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    private var listView: some View {
        List {
            if showVocabularySection {
                Section {
                    ForEach(vocabularyWords) { word in
                        AppFavoriteVocabularyRow(word: word, onPlayTap: { selectedVocabularyWord = word })
                            .contentShape(Rectangle())
                            .onTapGesture { selectedVocabularyWord = word }
                            .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                } header: {
                    sectionHeader("Vocabulary", count: vocabularyWords.count)
                }
            }
            if showWorderSection {
                Section {
                    ForEach(worderSentences) { word in
                        AppFavoriteWorderRow(word: word, onPlayTap: { selectedWorderWord = word })
                            .contentShape(Rectangle())
                            .onTapGesture { selectedWorderWord = word }
                            .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                } header: {
                    sectionHeader("Worder", count: worderSentences.count)
                }
            }
            if showVerbsSection {
                Section {
                    ForEach(verbFavoritesList) { verb in
                        VerbRow(verb: verb, useAppRedStyle: true, onOpen: { selectedVerb = verb })
                            .contentShape(Rectangle())
                            .onTapGesture { selectedVerb = verb }
                            .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                } header: {
                    sectionHeader("Verbs", count: verbFavoritesList.count)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
    }

    private var showVocabularySection: Bool {
        (selectedFilter == .all || selectedFilter == .vocabulary) && !vocabularyWords.isEmpty
    }
    private var showWorderSection: Bool {
        (selectedFilter == .all || selectedFilter == .worder) && !worderSentences.isEmpty
    }
    private var showVerbsSection: Bool {
        (selectedFilter == .all || selectedFilter == .verbs) && !verbFavoritesList.isEmpty
    }

    private func sectionHeader(_ title: String, count: Int) -> some View {
        let itemWord = count == 1 ? "item" : "items"
        return Text("\(title) (\(count) \(itemWord))")
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.secondary)
            .textCase(.uppercase)
    }
}

// MARK: - Vocabulary favorite row (same design as Verbs: audio left, centered text, play right)
private struct AppFavoriteVocabularyRow: View {
    let word: MyListWord
    let onPlayTap: () -> Void
    @StateObject private var audioManager = AudioManager()
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack {
            Button(action: {
                audioManager.playAudio()
            }) {
                Image("audio-headphone")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundColor(audioManager.isAudioReady ? .appRed : .gray)
                    .opacity(audioManager.isPlaying ? 0.5 : 1.0)
            }
            .disabled(!audioManager.isAudioReady || audioManager.isPlaying)
            .buttonStyle(.plain)

            Spacer()

            VStack(alignment: .center, spacing: 4) {
                Text(word.swedish)
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.appRed)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(word.english)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: onPlayTap) {
                Image("play-button")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 37, height: 37)
                    .foregroundColor(.appRed)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
        .cornerRadius(12)
        .onAppear {
            audioManager.generateAudio(for: word.swedish)
        }
        .onDisappear {
            audioManager.cleanupAudio()
        }
    }
}

// MARK: - Worder favorite row (same design as Verbs: audio left, centered text, play right)
private struct AppFavoriteWorderRow: View {
    let word: WorderMyListWord
    let onPlayTap: () -> Void
    @StateObject private var audioManager = AudioManager()
    @Environment(\.colorScheme) var colorScheme

    private var singleSpaced: String {
        let pattern = "\\s+"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(word.swedish.startIndex..., in: word.swedish)
            let replaced = regex.stringByReplacingMatches(in: word.swedish, options: [], range: range, withTemplate: " ")
            return replaced.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return word.swedish
    }

    var body: some View {
        HStack {
            Button(action: {
                audioManager.playAudio()
            }) {
                Image("audio-headphone")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundColor(audioManager.isAudioReady ? .appRed : .gray)
                    .opacity(audioManager.isPlaying ? 0.5 : 1.0)
            }
            .disabled(!audioManager.isAudioReady || audioManager.isPlaying)
            .buttonStyle(.plain)

            Spacer()

            VStack(alignment: .center, spacing: 4) {
                Text(singleSpaced)
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.appRed)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(word.english)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: onPlayTap) {
                Image("play-button")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 37, height: 37)
                    .foregroundColor(.appRed)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
        .cornerRadius(12)
        .onAppear {
            audioManager.generateAudio(for: singleSpaced)
        }
        .onDisappear {
            audioManager.cleanupAudio()
        }
    }
}

#Preview {
    AppFavoritesView()
}
