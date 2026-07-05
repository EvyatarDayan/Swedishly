import Foundation

struct Example: Codable, Equatable {
    let sv: String
    let en: String
}

struct TestWord: Codable, Identifiable, Equatable {
    let id: Int
    let swedish: String
    let english: String
    let sentence: String?
    let example: Example?
    
    init(id: Int, swedish: String, english: String, sentence: String? = nil, example: Example? = nil) {
        self.id = id
        self.swedish = swedish
        self.english = english
        self.sentence = sentence
        self.example = example
    }
    
    // Convenience initializer for creating words without full data
    init(swedish: String, english: String) {
        self.id = 0
        self.swedish = swedish
        self.english = english
        self.sentence = nil
        self.example = nil
    }
}

struct TestWordItemData: Codable, Identifiable, Equatable {
    let id: UUID
    let wordId: Int
    let swedish: String
    let english: String
    let userAnswer: String
    let isCorrect: Bool
    
    init(wordId: Int, swedish: String, english: String, userAnswer: String, isCorrect: Bool) {
        self.id = UUID()
        self.wordId = wordId
        self.swedish = swedish
        self.english = english
        self.userAnswer = userAnswer
        self.isCorrect = isCorrect
    }
}

struct TestHistoryItem: Codable, Identifiable, Equatable {
    let id: UUID
    let dateTaken: Date
    let words: [TestWordItemData]
    let score: Int
    let total: Int
    
    init(dateTaken: Date, words: [TestWordItemData], score: Int, total: Int) {
        self.id = UUID()
        self.dateTaken = dateTaken
        self.words = words
        self.score = score
        self.total = total
    }
}

struct WrongAnswerWord: Codable, Identifiable, Equatable {
    let id: UUID
    let swedish: String
    let english: String
    var correctCount: Int
    var wrongCount: Int
    
    init(swedish: String, english: String, correctCount: Int = 0, wrongCount: Int = 0) {
        self.id = UUID()
        self.swedish = swedish
        self.english = english
        self.correctCount = correctCount
        self.wrongCount = wrongCount
    }
}

struct PracticeProgressData: Codable {
    let wordId: Int
    let swedish: String
    let english: String
    let correctAnswer: String
    let options: [String]
    let selectedAnswer: String
    let showFeedback: Bool
    let isCorrect: Bool
    let questionCount: Int
    let isFromWrongAnswers: Bool
    let showWhy: Bool
    let exampleLanguage: String
}

// Per-question summary for a practice session, used in history details.
struct PracticeQuestionSummary: Codable, Identifiable, Equatable {
    let id: UUID
    let swedish: String
    let english: String
    let isCorrect: Bool
    
    init(swedish: String, english: String, isCorrect: Bool) {
        self.id = UUID()
        self.swedish = swedish
        self.english = english
        self.isCorrect = isCorrect
    }
}

struct PracticeHistoryItem: Codable, Identifiable, Equatable {
    let id: UUID
    let dateTaken: Date
    let questions: Int
    let correct: Int
    let wrong: Int
    let successPercentage: Int
    /// Optional per-question summaries for this session (newer items only).
    let questionsDetail: [PracticeQuestionSummary]?
    
    init(dateTaken: Date, questions: Int, correct: Int, wrong: Int, successPercentage: Int, questionsDetail: [PracticeQuestionSummary]? = nil) {
        self.id = UUID()
        self.dateTaken = dateTaken
        self.questions = questions
        self.correct = correct
        self.wrong = wrong
        self.successPercentage = successPercentage
        self.questionsDetail = questionsDetail
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, dateTaken, questions, correct, wrong, successPercentage, questionsDetail
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        dateTaken = try container.decode(Date.self, forKey: .dateTaken)
        questions = try container.decode(Int.self, forKey: .questions)
        correct = try container.decode(Int.self, forKey: .correct)
        wrong = try container.decode(Int.self, forKey: .wrong)
        successPercentage = try container.decode(Int.self, forKey: .successPercentage)
        questionsDetail = try container.decodeIfPresent([PracticeQuestionSummary].self, forKey: .questionsDetail)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(dateTaken, forKey: .dateTaken)
        try container.encode(questions, forKey: .questions)
        try container.encode(correct, forKey: .correct)
        try container.encode(wrong, forKey: .wrong)
        try container.encode(successPercentage, forKey: .successPercentage)
        try container.encodeIfPresent(questionsDetail, forKey: .questionsDetail)
    }
}

// Unified history item that can represent test, practice, grammar, adjective, or worder
enum HistoryItemType: String, Codable {
    case test
    case practice
    case grammar
    case adjective
    case worder
}

struct UnifiedHistoryItem: Identifiable, Equatable {
    let id: UUID
    let type: HistoryItemType
    let dateTaken: Date
    let score: Int
    let total: Int
    
    // Test-specific (Vocabulary)
    let testItem: TestHistoryItem?
    
    // Practice-specific (Vocabulary)
    let practiceItem: PracticeHistoryItem?
    
    // Grammar test result (Grammar Pronouns, Verbs, etc.)
    let grammarResult: TestResult?
    
    // Adjective practice (Adjective Antonyms, Agreement, Comparison)
    let adjectivesPracticeItem: AdjectivesPracticeHistoryItem?
    
    // Worder practice or test (Worder Practice, Worder Test)
    let worderItem: WordOrderHistoryItem?
    
    /// Display title for the history row: "Test", "Practice", "Grammar Pronouns", "Worder Test", etc.
    var displayTitle: String {
        switch type {
        case .test: return "Vocabulary Test"
        case .practice: return "Vocabulary Practice"
        case .grammar:
            guard let r = grammarResult else { return "Grammar" }
            switch r.testType {
            case "Pronouns": return "Grammar Pronouns"
            case "Verbs": return "Grammar Verbs"
            case "Noun Gender": return "Grammar Gender"
            case "Reflexiva pronomen": return "Grammar Reflexiva"
            default: return "Grammar " + r.testType
            }
        case .adjective:
            switch adjectivesPracticeItem?.practiceType {
            case .antonym: return "Adjective Antonyms"
            case .adjective: return "Adjective Agreement"
            case .compare: return "Adjective Comparison"
            case .none: return "Adjective"
            }
        case .worder:
            return worderItem?.effectiveType == .test ? "Word Order Test" : "Word Order Practice"
        }
    }

    /// SF Symbol aligned with home `TopicCard` topic icons (Vocabulary / Grammar / Adjectives / Word Order).
    var topicIconSystemName: String {
        switch type {
        case .test, .practice:
            return "character.book.closed.fill"
        case .grammar:
            return "text.book.closed.fill"
        case .adjective:
            return "a.square.fill"
        case .worder:
            return "arrow.left.arrow.right.square.fill"
        }
    }

    init(testItem: TestHistoryItem) {
        self.id = testItem.id
        self.type = .test
        self.dateTaken = testItem.dateTaken
        self.score = testItem.score
        self.total = testItem.total
        self.testItem = testItem
        self.practiceItem = nil
        self.grammarResult = nil
        self.adjectivesPracticeItem = nil
        self.worderItem = nil
    }
    
    init(practiceItem: PracticeHistoryItem) {
        self.id = practiceItem.id
        self.type = .practice
        self.dateTaken = practiceItem.dateTaken
        self.score = practiceItem.correct
        self.total = practiceItem.questions
        self.testItem = nil
        self.practiceItem = practiceItem
        self.grammarResult = nil
        self.adjectivesPracticeItem = nil
        self.worderItem = nil
    }
    
    init(grammarResult: TestResult) {
        self.id = grammarResult.id
        self.type = .grammar
        self.dateTaken = grammarResult.date
        self.score = grammarResult.score
        self.total = grammarResult.totalQuestions
        self.testItem = nil
        self.practiceItem = nil
        self.grammarResult = grammarResult
        self.adjectivesPracticeItem = nil
        self.worderItem = nil
    }
    
    init(adjectivesPracticeItem: AdjectivesPracticeHistoryItem) {
        self.id = UUID()
        self.type = .adjective
        self.dateTaken = adjectivesPracticeItem.dateTaken
        self.score = adjectivesPracticeItem.correct
        self.total = adjectivesPracticeItem.questions
        self.testItem = nil
        self.practiceItem = nil
        self.grammarResult = nil
        self.adjectivesPracticeItem = adjectivesPracticeItem
        self.worderItem = nil
    }
    
    init(worderItem: WordOrderHistoryItem) {
        self.id = worderItem.id
        self.type = .worder
        self.dateTaken = worderItem.dateTaken
        self.score = worderItem.correct
        self.total = worderItem.questions
        self.testItem = nil
        self.practiceItem = nil
        self.grammarResult = nil
        self.adjectivesPracticeItem = nil
        self.worderItem = worderItem
    }
    
    static func == (lhs: UnifiedHistoryItem, rhs: UnifiedHistoryItem) -> Bool {
        return lhs.id == rhs.id &&
               lhs.type == rhs.type &&
               lhs.dateTaken == rhs.dateTaken &&
               lhs.score == rhs.score &&
               lhs.total == rhs.total
    }
}
