//
//  FavoriteManager.swift
//  SWVerbs
//
//  Created by EVYATAR DAYAN on 2026-01-05.
//

import Foundation
import Combine

class FavoriteManager: ObservableObject {
    static let shared = FavoriteManager()
    
    @Published var favorites: [Verb] = []
    
    private let favoritesKey = "favoriteVerbs"
    
    private init() {
        loadFavorites()
    }
    
    func addFavorite(_ verb: Verb) {
        if !favorites.contains(where: { $0.id == verb.id }) {
            favorites.append(verb)
            saveFavorites()
        }
    }
    
    func removeFavorite(_ verb: Verb) {
        favorites.removeAll { $0.id == verb.id }
        saveFavorites()
    }
    
    func isFavorite(_ verb: Verb) -> Bool {
        return favorites.contains { $0.id == verb.id }
    }
    
    func toggleFavorite(_ verb: Verb) {
        if isFavorite(verb) {
            removeFavorite(verb)
        } else {
            addFavorite(verb)
        }
    }
    
    func clearAllFavorites() {
        favorites = []
        saveFavorites()
    }
    
    private func saveFavorites() {
        do {
            let encoded = try JSONEncoder().encode(favorites)
            UserDefaults.standard.set(encoded, forKey: favoritesKey)
        } catch {
            print("Failed to save favorites: \(error)")
        }
    }
    
    private func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: favoritesKey) {
            do {
                let decoded = try JSONDecoder().decode([Verb].self, from: data)
                favorites = decoded
            } catch {
                print("Failed to load favorites: \(error)")
                favorites = []
            }
        } else {
            favorites = []
        }
    }
}


