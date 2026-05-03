//
//  ManualView.swift
//  Swedishly
//

import SwiftUI

enum ManualFilterOption: String, CaseIterable {
    case all = "All"
    case recent = "Recent"
}

struct ManualView: View {
    @Binding var showWelcomePopup: Bool
    @StateObject private var manualManager = ManualManager.shared
    @State private var showingAddModal = false
    @State private var selectedSentence: Sentence?
    @State private var searchText = ""
    @State private var selectedFilter: ManualFilterOption = .all
    @FocusState private var isSearchFocused: Bool
    @Environment(\.colorScheme) var colorScheme
    @State private var showBlurHint = false
    @StateObject private var sessionManager = SessionManager.shared
    @AppStorage("hasShownManualBlurHint") private var hasShownManualBlurHint = false
    @AppStorage("manualWelcomeDontShowAgain") private var dontShowManualWelcomeAgain = false
    
    var filteredSentences: [Sentence] {
        var sentences = manualManager.manualSentences
        switch selectedFilter {
        case .all:
            break
        case .recent:
            let total = manualManager.manualSentences.count
            let start = max(0, total - 30)
            sentences = Array(manualManager.manualSentences[start..<total]).reversed()
        }
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            sentences = sentences.filter {
                $0.swedish.lowercased().contains(q) || $0.english.lowercased().contains(q)
            }
        }
        return sentences
    }
    
    private var mainVStack: some View {
        VStack(spacing: 0) {
            titleSection
            searchSection
            filterSection
            addButtonSection
            contentSection
        }
    }
    
    private var titleSection: some View {
        Text("My list")
            .font(.system(size: 28, weight: .bold, design: .rounded))
            .foregroundColor(.blue)
            .padding(.top, 8)
            .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? 20 : 22)
    }
    
    @ViewBuilder
    private var searchSection: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .padding(.leading, 12)
                TextField("Search...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.vertical, 10)
                    .focused($isSearchFocused)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .padding(.trailing, 12)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.separator), lineWidth: 1)
            )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }
    
    private var filterSection: some View {
        HStack {
            Picker("Filter", selection: $selectedFilter) {
                ForEach(ManualFilterOption.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(maxWidth: .infinity)
            Text("\(filteredSentences.count) Items")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 2)
        .padding(.top, 12)
    }
    
    private var addButtonSection: some View {
        HStack {
            Spacer()
            Button(action: { showingAddModal = true }) {
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 30)
        .offset(y: -150)
    }
    
    @ViewBuilder
    private var contentSection: some View {
        if filteredSentences.isEmpty && !searchText.isEmpty {
            noResultsView
        } else if manualManager.manualSentences.isEmpty {
            emptyStateView
        } else {
            sentencesListView
        }
    }
    
    private var noResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("No results found")
                .font(.title2)
                .foregroundColor(.secondary)
            Text("Try searching with different words")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Button(action: { showingAddModal = true }) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
            }
            Text("No items")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            Text("Tap the + button to add your first sentence")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var sentencesListView: some View {
        GeometryReader { geometry in
            List {
                ForEach(Array(filteredSentences.enumerated()), id: \.element.id) { index, sentence in
                    ManualSentenceCard(
                        sentence: sentence,
                        isFirstItem: index == 0,
                        showBlurHint: index == 0 && showBlurHint,
                        onHintDismiss: {
                            showBlurHint = false
                            hasShownManualBlurHint = true
                        }
                    ) {
                        selectedSentence = sentence
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .frame(maxWidth: UIDevice.current.userInterfaceIdiom == .pad ? geometry.size.width * 0.7 : .infinity)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            manualManager.removeManualSentence(sentence)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
            .background(Color(.systemGroupedBackground))
        }
    }
    
    var body: some View {
        mainVStack
            .background(Color(.systemGroupedBackground))
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isSearchFocused = false
                }
            }
        }
        .onAppear {
            if !dontShowManualWelcomeAgain {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showWelcomePopup = true
                }
            }
            if !hasShownManualBlurHint && !manualManager.manualSentences.isEmpty && searchText.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if !hasShownManualBlurHint {
                        showBlurHint = true
                    }
                }
            } else {
                showBlurHint = false
            }
        }
        .onChange(of: searchText) {
            if !searchText.isEmpty {
                showBlurHint = false
            } else if !hasShownManualBlurHint && !manualManager.manualSentences.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if !hasShownManualBlurHint {
                        showBlurHint = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddModal) {
            AddManualSentenceModal()
        }
        .sheet(item: $selectedSentence) { sentence in
            ManualSentenceModalView(
                sentence: sentence,
                manualSentences: manualManager.manualSentences,
                onDismiss: { selectedSentence = nil }
            )
        }
        .overlay(
            Group {
                if (showingAddModal || selectedSentence != nil) && UIDevice.current.userInterfaceIdiom == .pad {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                }
            }
        )
    }
}

// MARK: - ManualWelcomePopupView (used from ContentView for full-screen overlay)
struct ManualWelcomePopupView: View {
    @Binding var dontShowAgain: Bool
    let onDismiss: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Here you can add new sentences by typing or recording, and practice them anytime.")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(colorScheme == .dark ? Color(.systemGray) : Color(.systemGray))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            Text("Tap + to start.")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.blue)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            Button(action: onDismiss) {
                Text("OK")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 80)
            .padding(.top, 8)
            
            Button(action: { dontShowAgain.toggle() }) {
                HStack(spacing: 10) {
                    Image(systemName: dontShowAgain ? "checkmark.square.fill" : "square")
                        .font(.system(size: 22))
                        .foregroundColor(dontShowAgain ? .blue : .secondary)
                    Text("Don't show again")
                        .font(.subheadline)
                        .foregroundColor(colorScheme == .dark ? Color(.systemGray) : Color(.systemGray))
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
        .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 4)
    }
}

// MARK: - ManualSentenceCard
struct ManualSentenceCard: View {
    @Environment(\.colorScheme) var colorScheme
    let sentence: Sentence
    let isFirstItem: Bool
    let showBlurHint: Bool
    let onHintDismiss: () -> Void
    let onTap: () -> Void
    @StateObject private var audioManager = AudioManager()
    @State private var isEnglishRevealed = false
    @State private var hintAnimationScale: CGFloat = 0.8
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(sentence.swedish)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text(sentence.english)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .blur(radius: isEnglishRevealed ? 0 : 8)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isEnglishRevealed = true
                            }
                            if showBlurHint { onHintDismiss() }
                        }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture { onTap() }
                Button(action: {
                    audioManager.playAudio()
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 32, height: 32)
                        Image("audio-headphone")
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .foregroundColor(audioManager.isAudioReady ? .blue : .gray)
                            .opacity(audioManager.isPlaying ? 0.5 : 1.0)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!audioManager.isAudioReady || audioManager.isPlaying)
                .accessibilityLabel("Play Swedish audio")
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .padding(16)
            if showBlurHint && !isEnglishRevealed {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.left")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text("See English here")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(6)
                .scaleEffect(hintAnimationScale)
                .padding(.trailing, 70)
                .padding(.top, 50)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.5)) { hintAnimationScale = 1.0 }
                }
                .onTapGesture { onHintDismiss() }
            }
        }
        .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .onAppear {
            audioManager.generateAudio(for: sentence.swedish)
        }
        .onDisappear {
            audioManager.cleanupAudio()
        }
        .onChange(of: sentence.swedish) { _, newSwedish in
            audioManager.cleanupAudio()
            audioManager.generateAudio(for: newSwedish)
        }
    }
}
