//
//  ManualModels.swift
//  Swedishly
//

import Foundation
import Combine

// MARK: - Sentence (user-added Swedish sentence with translation)
struct Sentence: Identifiable, Codable, Equatable {
    let id: UUID
    let swedish: String
    let english: String
    var dateCreated: Date?
    
    init(id: UUID = UUID(), swedish: String, english: String, dateCreated: Date? = nil) {
        self.id = id
        self.swedish = swedish
        self.english = english
        self.dateCreated = dateCreated
    }
}

// MARK: - SessionManager (in-session hints state)
class SessionManager: ObservableObject {
    static let shared = SessionManager()
    @Published var hasShownManualDictationHint = false
    private init() {}
}
