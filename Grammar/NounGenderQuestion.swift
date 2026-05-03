//
//  NounGenderQuestion.swift
//  SWGrammar
//
//  Created by EVYATAR DAYAN on 2026-01-19.
//

import Foundation

struct NounGenderData: Codable {
    let topic: String
    let instruction: String
    let nouns: [NounGenderExercise]
}

struct NounGenderExercise: Codable, Identifiable, Equatable {
    let id: Int
    let swedish: String
    let english: String
    let gender: String // "en" or "ett"
    let example: Example?
    
    struct Example: Codable, Equatable {
        let sv: String
        let en: String
    }
    
    // For test purposes, we'll create a sentence with blank and options
    var sentence: String {
        return "\(swedish) är ____ ord."
    }
    
    var rule: String? {
        return nil // No rule for noun gender
    }
    
    var options: [String] {
        return ["en", "ett"]
    }
    
    var answer: String {
        return gender
    }
    
    var translation: String? {
        return english
    }
}
