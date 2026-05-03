//
//  PronounQuestion.swift
//  SWGrammar
//
//  Created by EVYATAR DAYAN on 2026-01-19.
//

import Foundation

struct PronounData: Codable {
    let topic: String
    let instruction: String
    let exercises: [PronounExercise]
}

struct PronounExercise: Codable, Identifiable, Equatable {
    let id: Int
    let sentence: String
    let basePronoun: String?
    let options: [String]
    let answer: String
    let rule: String?
    let level: Int?
    let translation: String?
}
