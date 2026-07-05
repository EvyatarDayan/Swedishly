//
//  WorderMyListView.swift
//  Swedishly
//

import SwiftUI

struct WorderMyListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var myListManager = WorderMyListManager.shared
    @State private var selectedWord: WorderMyListWord? = nil
    @State private var searchText: String = ""
    @State private var showItems: Bool = false
    @State private var filterSelection: Int = 0 // 0 = All, 1 = Favorites
    @Environment(\.colorScheme) var colorScheme
    
    private var filteredWords: [WorderMyListWord] {
        let base: [WorderMyListWord] = filterSelection == 0
            ? myListManager.getAllSentencesCached()
            : myListManager.getMyListWords()

        guard !searchText.isEmpty else { return base }

        return base.filter { word in
            word.swedish.lowercased().contains(searchText.lowercased()) ||
            word.english.lowercased().contains(searchText.lowercased())
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            BackButtonRow(onBack: { dismiss() })
            ZStack {
                HStack {
                    Spacer()
                    Text("My list")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.appRed)
                    Spacer()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 20)
            
            if myListManager.getAllSentencesCount() > 0 {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }
            
            HStack(spacing: 12) {
                Picker("", selection: $filterSelection) {
                    Text("All").tag(0)
                    Text("Favorites").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(maxWidth: 260)

                Spacer()
                Text("\(filteredWords.count) Sentences")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .padding(.top, 12)
            
            if filterSelection == 1 && myListManager.getMyListWords().isEmpty {
                emptyStateView
            } else if filteredWords.isEmpty {
                VStack(spacing: 20) {
                    Spacer()
                    Text("No results found")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text("Try a different search term")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, 55)
            } else {
                listView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .clipped()
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $selectedWord) { word in
            WorderMyListWordDetailModal(word: word)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image("My list")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .foregroundColor(.secondary)
            
            Text("No words in your list")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Add words to your list from the test or practice view")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 55)
    }
    
    private var listView: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(Array(filteredWords.enumerated()), id: \.element.id) { index, word in
                    WorderMyListWordRow(word: word, onInfoTap: { selectedWord = word })
                        .scaleEffect(showItems ? 1 : 0.5)
                        .opacity(showItems ? 1 : 0)
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.75)
                                .delay(showItems ? Double(index) * 0.08 : Double(filteredWords.count - 1 - index) * 0.08),
                            value: showItems
                        )
                }
            }
            .padding(.vertical, 20)
            .padding(.bottom, 55)
        }
        .background(Color(.systemGroupedBackground))
        .onAppear { showItems = true }
        .onChange(of: searchText) { _ in
            showItems = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { showItems = true }
        }
    }
}

struct WorderMyListWordRow: View {
    let word: WorderMyListWord
    let onInfoTap: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: onInfoTap) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(word.swedish.singleSpaced)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text(word.english.singleSpaced)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 20)
    }
}

struct WorderMyListWordDetailModal: View {
    let word: WorderMyListWord
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var myListManager = WorderMyListManager.shared
    
    private var example: WordOrderExample? {
        let all = WordOrderDataManager.shared.getAllExamples()
        return all.first { example in
            example.answer.singleSpaced.lowercased() == word.swedish.singleSpaced.lowercased() &&
            example.answerTranslation.singleSpaced.lowercased() == word.english.singleSpaced.lowercased()
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: -10) {
                ZStack {
                    HStack {
                        Spacer()
                        Text("More info")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.appRed)
                            .padding(.bottom, 30)
                        Spacer()
                    }
                }
                .padding(.top, 50)
                .padding(.trailing, 10)

                GeometryReader { geometry in
                    ScrollView {
                        VStack(spacing: 50) {
                            Rectangle()
                                .fill(Color(.separator))
                                .frame(height: 5)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 0)
                                .padding(.top, 20)

                            VStack(spacing: 16) {
                                let swedishTokens = word.swedish.singleSpaced.split(separator: " ").map { String($0) }
                                FlowLayout(spacing: 6) {
                                    ForEach(Array(swedishTokens.enumerated()), id: \.0) { idx, token in
                                        VStack(spacing: 4) {
                                            Text("\(idx + 1)")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.black)
                                                .frame(width: 20, height: 20)
                                                .background(Circle().fill(Color.clear))
                                                .overlay(Circle().stroke(Color.black, lineWidth: 1))
                                                .multilineTextAlignment(.center)
                                            Text(token)
                                                .font(.system(size: 28, weight: .bold))
                                                .foregroundColor(.appRed)
                                                .multilineTextAlignment(.center)
                                        }
                                        .padding(.horizontal, 2)
                                        .padding(.vertical, 2)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                Text(word.english.singleSpaced)
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)

                            Rectangle()
                                .fill(Color(.separator))
                                .frame(height: 5)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 0)

                            if let tip = example?.tip, !tip.isEmpty {
                                VStack(spacing: 8) {
                                    Text("Why?")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    Text(tip)
                                        .font(.system(size: 18, weight: .regular))
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 20)
                            }

                            Button(action: { dismiss() }) {
                                Text("Done")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.blue)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, 100)
                            .padding(.vertical, 16)

                            Spacer()
                                .frame(height: geometry.size.height * 0.1)
                        }
                        .frame(minHeight: geometry.size.height)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        if let ex = example {
                            if myListManager.isInMyList(swedish: ex.answer, english: ex.answerTranslation) {
                                myListManager.removeFromMyList(swedish: ex.answer, english: ex.answerTranslation)
                            } else {
                                myListManager.addToMyList(swedish: ex.answer, english: ex.answerTranslation)
                            }
                        }
                    }) {
                        MyListFavoriteIcon(
                            isInList: example != nil && myListManager.isInMyList(
                                swedish: example!.answer,
                                english: example!.answerTranslation
                            )
                        )
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Text("Close")
                            .font(.body)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
}

private extension String {
    var singleSpaced: String {
        let pattern = "\\s+"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(self.startIndex..., in: self)
            let replaced = regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: " ")
            return replaced.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

#Preview {
    WorderMyListView()
}
