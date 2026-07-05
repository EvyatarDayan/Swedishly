import SwiftUI

struct MyListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var myListManager = MyListManager.shared
    @StateObject private var audioManager = AudioManager()
    @State private var selectedWord: MyListWord? = nil
    @State private var searchText: String = ""
    @State private var listFilter: ListFilter = .all
    @Environment(\.colorScheme) var colorScheme
    
    enum ListFilter: String, CaseIterable {
        case all = "All"
        case favorites = "Favorites"
    }
    
    private var filteredWords: [MyListWord] {
        let source: [MyListWord]
        switch listFilter {
        case .all:
            source = myListManager.getAllWordsCached()
        case .favorites:
            source = myListManager.getMyListWords()
        }

        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            return source
        }
        let q = searchText.lowercased()
        return source.filter { word in
            word.swedish.lowercased().contains(q) || word.english.lowercased().contains(q)
        }
    }
    
    private var wordsCountText: String {
        // If searching, show result count
        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            let c = filteredWords.count
            return "\(c) result\(c == 1 ? "" : "s")"
        }
        switch listFilter {
        case .all:
            return "\(myListManager.getAllWordsCount()) words"
        case .favorites:
            let c = myListManager.getMyListCount()
            return "\(c) favorite\(c == 1 ? "" : "s")"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Back button row (no nav bar)
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                        Text("Back")
                            .font(.body)
                    }
                    .foregroundColor(.appRed)
                }
                .padding(.top, 8)
                .padding(.leading, 4)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            // Title (same sizing/padding as Favorites, with two-color design)
            HStack {
                Spacer()
                SplitTitleView("My list", splitIndex: 2)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 20)
            
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search words...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
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
            .padding(.bottom, 6)

            // Favorites only toggle (larger vertical frame for spacing)
            // Filter segmented control (All / Favorites)
            HStack {
                Picker("", selection: $listFilter) {
                    Text("All").tag(ListFilter.all)
                    Text("Favorites").tag(ListFilter.favorites)
                }
                .pickerStyle(.segmented)
                Spacer()
            }
            .frame(height: 56)
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 8)
            
            // Count indicator
            HStack {
                Text(wordsCountText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
            
            // Content
            if listFilter == .favorites && myListManager.getMyListWords().isEmpty {
                // No favorites yet
                emptyStateView
            } else if filteredWords.isEmpty {
                // No results found for search/filter
                VStack(spacing: 20) {
                    Spacer()
                    Text("No words found")
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
        .background(Color(.systemGroupedBackground))
        .clipped()
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $selectedWord) { word in
            MyListWordDetailModal(word: word)
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
        .padding(.bottom, 70)
    }
    
    private var listView: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(filteredWords) { word in
                    MyListWordRow(word: word, onInfoTap: {
                        selectedWord = word
                    })
                }
            }
            .padding(.vertical, 20)
            .padding(.bottom, 55) // Add padding for menu
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct MyListWordRow: View {
    let word: MyListWord
    let onInfoTap: () -> Void
    @StateObject private var audioManager = AudioManager()
    @StateObject private var myListManager = MyListManager.shared
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: {
            onInfoTap()
        }) {
            HStack(spacing: 12) {
                // Audio button
                Button(action: {
                    audioManager.playAudio()
                }) {
                    Image("audio-headphone")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(audioManager.isAudioReady ? .blue : .gray)
                        .opacity(audioManager.isPlaying ? 0.5 : 1.0)
                }
                .disabled(!audioManager.isAudioReady || audioManager.isPlaying)
                .buttonStyle(PlainButtonStyle())
                
                // Swedish word
                Text(word.swedish)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Divider
                Text("=")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                // English translation
                Text(word.english)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                
                // Info icon (visual indicator)
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
            }
            .frame(height: 30)
            .padding(16)
            .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 20)
        .onAppear {
            audioManager.generateAudio(for: word.swedish)
        }
        .onDisappear {
            audioManager.cleanupAudio()
        }
    }
}

struct MyListWordDetailModal: View {
    let word: MyListWord
    @Environment(\.dismiss) private var dismiss
    @StateObject private var testDataManager = TestDataManager.shared
    @StateObject private var audioManager = AudioManager()
    @StateObject private var myListManager = MyListManager.shared
    @Environment(\.colorScheme) var colorScheme
    
    private var fullWord: TestWord? {
        testDataManager.getWordsByContent(swedish: word.swedish, english: word.english)
    }
    
    private var swedishSentence: String? {
        var sentence: String?
        if let example = fullWord?.example {
            sentence = example.sv
        } else if let s = fullWord?.sentence {
            sentence = s
        }
        
        // Remove "Ex: " prefix if present
        if let s = sentence, s.hasPrefix("Ex: ") {
            return String(s.dropFirst(4))
        }
        return sentence
    }
    
    private var englishSentence: String? {
        guard let sentence = fullWord?.example?.en else {
            return nil
        }
        
        // Remove "Ex: " prefix if present
        if sentence.hasPrefix("Ex: ") {
            return String(sentence.dropFirst(4))
        }
        return sentence
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 30) {
                        Spacer()
                        Text("More info")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.appRed)
                        Spacer()
                        
                        // Horizontal divider
                        Rectangle()
                            .fill(Color(.separator))
                            .frame(height: 5)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                        
                        // Swedish word with audio
                        VStack(spacing: 16) {
                            HStack(spacing: 6) {
                                Spacer()
                                Text(word.swedish)
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)
                                
                                Button(action: {
                                    audioManager.playAudio()
                                }) {
                                    Image("audio-headphone")
                                        .resizable()
                                        .renderingMode(.template)
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(audioManager.isAudioReady ? .appRed : .gray)
                                        .opacity(audioManager.isPlaying ? 0.5 : 1.0)
                                }
                                .disabled(audioManager.isPlaying || !audioManager.isAudioReady)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            
                            // English translation
                            Text(word.english)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        
                        // Horizontal divider
                        Rectangle()
                            .fill(Color(.separator))
                            .frame(height: 5)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                        
                        // Swedish sentence
                        if let swedishSentence = swedishSentence {
                            VStack(spacing: 8) {
                                Text("Swedish:")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Text(swedishSentence)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 20)
                        }
                        
                        // English sentence
                        if let englishSentence = englishSentence {
                            VStack(spacing: 8) {
                                Text("English:")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Text(englishSentence)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 20)
                        }
                        
                        // Done button (same as Verbs more info: dimensions and style)
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Done")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.appRed)
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
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        if myListManager.isInMyList(swedish: word.swedish, english: word.english) {
                            myListManager.removeFromMyList(swedish: word.swedish, english: word.english)
                        } else {
                            myListManager.addToMyList(swedish: word.swedish, english: word.english)
                        }
                    }) {
                        Image("starPlus")
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .foregroundColor(myListManager.isInMyList(swedish: word.swedish, english: word.english) ? .green : .gray)
                    }
                }
            }
        }
        .onAppear {
            audioManager.generateAudio(for: word.swedish)
        }
        .onDisappear {
            audioManager.cleanupAudio()
        }
    }
}

#Preview {
    MyListView()
}
