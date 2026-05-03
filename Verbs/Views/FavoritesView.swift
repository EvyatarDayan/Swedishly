//
//  FavoritesView.swift
//  SWVerbs
//
//  Created by EVYATAR DAYAN on 2026-01-05.
//

import SwiftUI

struct FavoritesView: View {
    @StateObject private var favoriteManager = FavoriteManager.shared
    @State private var searchText: String = ""
    @State private var selectedVerb: Verb?
    
    var filteredFavorites: [Verb] {
        if searchText.isEmpty {
            return favoriteManager.favorites
        }
        return favoriteManager.favorites.filter { verb in
            verb.infinitive.localizedCaseInsensitiveContains(searchText) ||
            verb.base.localizedCaseInsensitiveContains(searchText) ||
            verb.english.joined().localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                
                // Content
                if favoriteManager.favorites.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "heart")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No favorites yet")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Tap the heart icon on any verb to add it to your favorites")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    Spacer()
                } else if filteredFavorites.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No results found")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Try searching with different words")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    Spacer()
                } else {
                    // Verb List
                    List(filteredFavorites) { verb in
                        VerbRow(verb: verb, onOpen: {
                            selectedVerb = verb
                        })
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
                    SplitTitleView("Favorites", splitIndex: 4)
                }
            }
            .sheet(item: $selectedVerb) { verb in
                VerbDetailView(verb: verb)
            }
        }
        .navigationViewStyle(.stack)
    }
}

#Preview {
    FavoritesView()
}

