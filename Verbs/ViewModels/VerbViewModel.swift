//
//  VerbViewModel.swift
//  SWVerbs
//
//  Created by EVYATAR DAYAN on 2026-01-05.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class VerbViewModel: ObservableObject {
    @Published var verbs: [Verb] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    var filteredVerbs: [Verb] {
        if searchText.isEmpty {
            return verbs
        }
        return verbs.filter { verb in
            verb.infinitive.localizedCaseInsensitiveContains(searchText) ||
            verb.base.localizedCaseInsensitiveContains(searchText) ||
            verb.english.joined().localizedCaseInsensitiveContains(searchText)
        }
    }
    
    init() {
        loadVerbs()
    }
    
    func loadVerbs() {
        isLoading = true
        errorMessage = nil

        // Try Verbs/Data/ first (when embedded in Swedishly app), then bundle root
        var url = Bundle.main.url(forResource: "swedish_verbs_200", withExtension: "json", subdirectory: "Verbs/Data")
        if url == nil {
            url = Bundle.main.url(forResource: "swedish_verbs_200", withExtension: "json")
        }
        guard let url = url else {
            errorMessage = "Could not find verbs data file"
            isLoading = false
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let verbData = try decoder.decode(VerbsVerbData.self, from: data)
            self.verbs = verbData.verbs
            isLoading = false
        } catch {
            errorMessage = "Failed to load verbs: \(error.localizedDescription)"
            isLoading = false
        }
    }
}

