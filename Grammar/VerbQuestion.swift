//
//  VerbQuestion.swift
//  SWGrammar
//
//  Created by EVYATAR DAYAN on 2026-01-19.
//

import Foundation

struct VerbData: Codable {
    let topic: String
    let instruction: String
    let exercises: [Exercise]
}

struct Exercise: Codable, Identifiable, Equatable {
    let id: Int
    let sentence: String
    let baseAdjective: String
    let options: [String]
    let answer: String
    let rule: String
    let level: Int
    let translation: String
}
