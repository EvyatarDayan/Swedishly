//
//  Verb.swift
//  SWVerbs
//
//  Created by EVYATAR DAYAN on 2026-01-05.
//

import Foundation

/// Verbs section: JSON root for swedish_verbs_200.json (avoids conflict with Grammar.VerbData).
struct VerbsVerbData: Codable {
    let metadata: Metadata
    let verbs: [Verb]
}

struct Metadata: Codable {
    let language: String
    let translation: String
    let verbCount: Int
    let offline: Bool
    let license: String
}

struct Verb: Codable, Identifiable, Equatable {
    var id: String { infinitive }
    let infinitive: String
    let base: String
    let english: [String]
    let regular: Bool
    let examples: VerbExamples
    
    static func == (lhs: Verb, rhs: Verb) -> Bool {
        lhs.id == rhs.id
    }
}

struct VerbExamples: Codable, Equatable {
    let present: VerbsExample
    let past: VerbsExample
    let perfect: VerbsExample
}

/// Verbs section: sentence example (sv/en); avoids conflict with Vocabulary/Grammar.Example.
struct VerbsExample: Codable, Equatable {
    let sv: String
    let en: String
}

