//
//  ContentView.swift
//  Swedishly
//
//  Created by EVYATAR DAYAN on 2026-03-07.
//

import SwiftUI

// MARK: - Tab bar button (defined first so ContentView can use it)

struct TabBarButton: View {
    let icon: String
    let label: String
    let isCustomIcon: Bool
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                if isCustomIcon {
                    Image(icon)
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .foregroundColor(isSelected ? .blue : .secondary)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .blue : .secondary)
                }
                Text(label)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, -30)
            .padding(.bottom, 6)
        }
        .buttonStyle(PlainButtonStyle())
        .allowsHitTesting(true)
    }
}

// MARK: - Vocabulary view (Practice, Test, Words)

struct VocabularyView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            backButtonRow(title: "Vocabulary", onBack: { dismiss() })
            SplitTitleView("Vocabulary", splitIndex: 5)
                .padding(.top, 8)
                .padding(.bottom, 16)

            Spacer(minLength: 0)
            VStack(spacing: 16) {
                NavigationLink(destination: PracticeView()) {
                    VocabularyOptionButtonLabel(
                        title: "Practice",
                        icon: "play.circle.fill",
                        subtitle: "Learn at your own pace",
                        compactLayout: true
                    )
                }
                .buttonStyle(PlainButtonStyle())
                NavigationLink(destination: SWVocabularyTestView()) {
                    VocabularyOptionButtonLabel(
                        title: "Test",
                        icon: "doc.text.fill",
                        subtitle: "Quiz yourself and track your score",
                        compactLayout: true
                    )
                }
                .buttonStyle(PlainButtonStyle())
                NavigationLink(destination: MyListView()) {
                    VocabularyOptionButtonLabel(
                        title: "Words",
                        icon: "character.book.closed.fill",
                        subtitle: "Browse and manage your saved words",
                        compactLayout: true
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Grammar (4 main options: Pronouns, Verbs, Reflexiva, Gender)

struct GrammarMainWrapperView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var verbQuizViewModel = VerbQuizViewModel()
    @StateObject private var pronounQuizViewModel = PronounQuizViewModel()
    @StateObject private var nounGenderQuizViewModel = NounGenderQuizViewModel()
    @StateObject private var reflexiveQuizViewModel = ReflexiveQuizViewModel()
    @StateObject private var testResultsManager = TestResultsManager()

    var body: some View {
        VStack(spacing: 0) {
            BackButtonRow(onBack: { dismiss() })
            SplitTitleView("Grammar", splitIndex: 4)
                .padding(.top, 8)
                .padding(.bottom, 16)

            Spacer(minLength: 0)
            VStack(spacing: 16) {
                NavigationLink(destination: PronounTestView(viewModel: pronounQuizViewModel, resultsManager: testResultsManager)) {
                    VocabularyOptionButtonLabel(
                        title: "Pronouns",
                        icon: "person.2.fill",
                        subtitle: "Learn Swedish pronouns in context",
                        compactLayout: true
                    )
                }
                .buttonStyle(PlainButtonStyle())
                NavigationLink(destination: GrammarVerbTestView(viewModel: verbQuizViewModel, resultsManager: testResultsManager)) {
                    VocabularyOptionButtonLabel(
                        title: "Verbs",
                        icon: "textformat",
                        subtitle: "Conjugation and verb forms",
                        compactLayout: true
                    )
                }
                .buttonStyle(PlainButtonStyle())
                NavigationLink(destination: ReflexiveTestView(viewModel: reflexiveQuizViewModel, resultsManager: testResultsManager)) {
                    VocabularyOptionButtonLabel(
                        title: "Reflexiva",
                        icon: "arrow.triangle.2.circlepath",
                        subtitle: "Reflexive pronouns in practice",
                        compactLayout: true
                    )
                }
                .buttonStyle(PlainButtonStyle())
                NavigationLink(destination: NounGenderTestView(viewModel: nounGenderQuizViewModel, resultsManager: testResultsManager)) {
                    VocabularyOptionButtonLabel(
                        title: "Gender",
                        icon: "person.crop.circle",
                        subtitle: "en or ett - noun gender",
                        compactLayout: true
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Verbs view (All Verbs, Practice, Test)

struct VerbsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            backButtonRow(title: "Verbs", onBack: { dismiss() })
            SplitTitleView("Verbs", splitIndex: 3)
                .padding(.top, 8)
                .padding(.bottom, 16)

            Spacer(minLength: 0)
            VStack(spacing: 16) {
                NavigationLink(destination: SearchView()) {
                    VocabularyOptionButtonLabel(
                        title: "All Verbs",
                        icon: "list.bullet",
                        subtitle: "Browse and search the full verb list",
                        compactLayout: true
                    )
                }
                .buttonStyle(PlainButtonStyle())
                NavigationLink(destination: VerbsPracticeView()) {
                    VocabularyOptionButtonLabel(
                        title: "Practice",
                        icon: "play.circle.fill",
                        subtitle: "Learn at your own pace",
                        compactLayout: true
                    )
                }
                .buttonStyle(PlainButtonStyle())
                NavigationLink(destination: TestsView()) {
                    VocabularyOptionButtonLabel(
                        title: "Test",
                        icon: "doc.text.fill",
                        subtitle: "Quiz yourself and track your score",
                        compactLayout: true
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Adjectives view (Antonyms, Agreement, Comparison)

struct AdjectivesView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            backButtonRow(title: "Adjectives", onBack: { dismiss() })
            SplitTitleView("Adjectives", splitIndex: 5)
                .padding(.top, 8)
                .padding(.bottom, 16)

            Spacer(minLength: 0)
            VStack(spacing: 16) {
                NavigationLink(destination: AntonymsView()) {
                    VocabularyOptionButtonLabel(
                        title: "Antonyms",
                        icon: "arrow.left.arrow.right",
                        subtitle: "Opposite meanings and word pairs",
                        compactLayout: true
                    )
                }
                .buttonStyle(PlainButtonStyle())
                NavigationLink(destination: AgreementView()) {
                    VocabularyOptionButtonLabel(
                        title: "Agreement",
                        icon: "checkmark.circle.fill",
                        subtitle: "Gender and number with nouns",
                        compactLayout: true
                    )
                }
                .buttonStyle(PlainButtonStyle())
                NavigationLink(destination: ComparisonView()) {
                    VocabularyOptionButtonLabel(
                        title: "Comparison",
                        icon: "chart.bar.fill",
                        subtitle: "Comparative and superlative forms",
                        compactLayout: true
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Worder view (Practice, Test, My List)

struct WorderView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            backButtonRow(title: "Word Order", onBack: { dismiss() })
            SplitTitleView("Word Order", splitIndex: 4)
                .padding(.top, 8)
                .padding(.bottom, 16)

            Spacer(minLength: 0)
            VStack(spacing: 16) {
                NavigationLink(destination: WorderPracticeView()) {
                    VocabularyOptionButtonLabel(
                        title: "Practice",
                        icon: "play.circle.fill",
                        subtitle: "Arrange words into correct Swedish sentences",
                        compactLayout: true
                    )
                }
                .buttonStyle(PlainButtonStyle())
                NavigationLink(destination: WorderTestView()) {
                    VocabularyOptionButtonLabel(
                        title: "Test",
                        icon: "doc.text.fill",
                        subtitle: "Quiz yourself and track your score",
                        compactLayout: true
                    )
                }
                .buttonStyle(PlainButtonStyle())
                NavigationLink(destination: WorderMyListView()) {
                    VocabularyOptionButtonLabel(
                        title: "My List",
                        icon: "list.bullet.clipboard.fill",
                        subtitle: "Sentences you've saved for review",
                        compactLayout: true
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}

// Reusable blue Back button row (Vocabulary, Grammar, and all future pushed views)
struct BackButtonRow: View {
    var onBack: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                    Text("Back")
                        .font(.body)
                }
                .foregroundColor(.blue)
            }
            .padding(.top, 8)
            .padding(.leading, 4)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}

// Back button row used by category views (no nav bar)
private func backButtonRow(title: String, onBack: @escaping () -> Void) -> some View {
    BackButtonRow(onBack: onBack)
}

/// Option button label matching home topic card design: text-only, same card style (used in Vocabulary, Grammar, Verbs, Adjectives, Worder).
struct VocabularyOptionButtonLabel: View {
    @Environment(\.colorScheme) var colorScheme
    let title: String
    let icon: String
    /// Optional second line (e.g. Vocabulary section descriptions). When nil, layout matches title-only cards elsewhere.
    var subtitle: String? = nil
    /// Tighter card height and spacing (e.g. Grammar hub — roll out to other hubs when ready).
    var compactLayout: Bool = false

    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    private var hasSubtitle: Bool {
        subtitle != nil && !(subtitle?.isEmpty ?? true)
    }

    private var cardMinHeight: CGFloat {
        if hasSubtitle {
            if compactLayout {
                return isPad ? 158 : 116
            }
            return isPad ? 180 : 140
        }
        if compactLayout {
            return isPad ? 140 : 102
        }
        return isPad ? 160 : 120
    }

    private var titleSubtitleStackSpacing: CGFloat {
        hasSubtitle ? (compactLayout ? 4 : 8) : 0
    }

    private var cardVerticalPadding: CGFloat {
        guard hasSubtitle else { return 0 }
        return compactLayout ? 8 : 12
    }

    var body: some View {
        Group {
            if let subtitle = subtitle, !subtitle.isEmpty {
                VStack(spacing: titleSubtitleStackSpacing) {
                    Text(title)
                        .font(.system(size: isPad ? 35 : 25, weight: .semibold, design: .rounded))
                        .foregroundColor(.blue)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.system(size: isPad ? (compactLayout ? 17 : 18) : (compactLayout ? 14 : 15), weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                Text(title)
                    .font(.system(size: isPad ? 35 : 25, weight: .semibold, design: .rounded))
                    .foregroundColor(.blue)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: cardMinHeight)
        .padding(.horizontal, 12)
        .padding(.vertical, cardVerticalPadding)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(colorScheme == .dark ? Color(.systemGray4).opacity(0.5) : Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.08), radius: 6, x: 0, y: 2)
    }
}

struct VocabularyOptionButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VocabularyOptionButtonLabel(title: title, icon: icon)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Topic card (for home view) – text-only tile

struct TopicCard: View {
    @Environment(\.colorScheme) var colorScheme
    let topic: String
    let isPopular: Bool
    /// When true, tile looks disabled (grayed out) and does not respond to taps.
    var isDisabled: Bool = false
    let onTopicSelected: (String) -> Void

    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    private var titleColor: Color {
        if isDisabled {
            return colorScheme == .dark ? Color(.systemGray2) : Color(.systemGray)
        }
        return .blue
    }

    private var cardBackground: Color {
        if isDisabled {
            return colorScheme == .dark ? Color(.systemGray5).opacity(0.6) : Color(.systemGray6)
        }
        return colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)
    }

    private var cardStroke: Color {
        if isDisabled {
            return colorScheme == .dark ? Color(.systemGray4).opacity(0.35) : Color.black.opacity(0.04)
        }
        return colorScheme == .dark ? Color(.systemGray4).opacity(0.5) : Color.black.opacity(0.06)
    }

    /// SF Symbol name for each home topic (blue when active, gray when disabled).
    private var topicIconName: String {
        switch topic {
        case "Vocabulary": return "character.book.closed.fill"
        case "Grammar": return "text.book.closed.fill"
        case "Verbs": return "square.grid.2x2.fill"
        case "Adjectives": return "a.square.fill"
        case "Word Order": return "arrow.left.arrow.right.square.fill"
        case "Coming soon...": return "clock.fill"
        default: return "star.fill"
        }
    }

    /// Uniform square so every topic glyph matches in footprint (Verbs stays square like the others).
    private var topicIconFrame: CGFloat { isPad ? 36 : 25 }

    /// Blue + green split (like the “Swedish” + “ly” title); same gray when disabled.
    private static func topicSplitParts(for topic: String) -> (String, String) {
        switch topic {
        case "Vocabulary": return ("Vocab", "ulary")
        case "Grammar": return ("Gram", "mar")
        case "Verbs": return ("Ver", "bs")
        case "Adjectives": return ("Adjec", "tives")
        case "Word Order": return ("Word", " Order")
        case "Coming soon...": return ("Coming", " soon...")
        default: return (topic, "")
        }
    }

    private var topicTitleText: Text {
        let (prefix, suffix) = Self.topicSplitParts(for: topic)
        let full = prefix + suffix
        if suffix.isEmpty {
            return Text(full).foregroundColor(titleColor)
        }
        if isDisabled {
            return Text(full).foregroundColor(titleColor)
        }
        return (Text(prefix).foregroundColor(.blue) + Text(suffix).foregroundColor(.green))
    }

    var body: some View {
        Button(action: { onTopicSelected(topic) }) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: isPad ? 12 : 10) {
                    Image(systemName: topicIconName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: topicIconFrame, height: topicIconFrame)
                        .foregroundColor(titleColor)
                    topicTitleText
                        .font(.system(size: isPad ? 35 : 20, weight: .semibold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: isPad ? 170 : 120)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(cardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(cardStroke, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(isDisabled ? 0.03 : (colorScheme == .dark ? 0.2 : 0.08)), radius: isDisabled ? 2 : 6, x: 0, y: isDisabled ? 1 : 2)

                if isPopular {
                    Text("Popular")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.green)
                        .cornerRadius(6)
                        .padding(.top, 12)
                        .padding(.trailing, 12)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.92 : 1)
    }
}

// MARK: - Main content view

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @AppStorage("manualWelcomeDontShowAgain") private var manualWelcomeDontShowAgain = false
    @State private var selectedTab = 2
    @State private var historyInitialFilter: HistoryView.FilterOption? = nil
    @State private var showManualWelcomeOverlay = false
    @State private var showVocabularyView = false
    @State private var showGrammarView = false
    @State private var showVerbsView = false
    @State private var showAdjectivesView = false
    @State private var showWorderView = false
    @State private var topicsAppeared = false

    // Menu height constant - adjust this to change menu height
    private let menuHeight: CGFloat = 40
    // Menu button spacing - adjust this to change spacing between buttons (negative values bring them closer)
    private let menuButtonSpacing: CGFloat = -40

    // Six categories for the home view
    private let topics = [
        "Vocabulary",
        "Grammar",
        "Verbs",
        "Adjectives",
        "Word Order",
        "Coming soon..."
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Light gray background for entire view including safe area
                Color(.systemGroupedBackground)
                    .ignoresSafeArea(.all)

                VStack(spacing: 0) {
                    // Main content area
                    mainContentArea
                        .frame(width: geometry.size.width, height: geometry.size.height - menuHeight)
                        .clipped()

                    // Footer menu with new design
                    footerMenu(geometry: geometry)
                }
            }
            .overlay(
                // Manual welcome popup: drawn on top, does not affect layout; full-screen dim; enlarge/reverse animation
                Group {
                    if selectedTab == 3 {
                        ZStack {
                            Color.black.opacity(0.4)
                                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                                .ignoresSafeArea(.all)
                                .opacity(showManualWelcomeOverlay ? 1 : 0)
                            ManualWelcomePopupView(
                                dontShowAgain: $manualWelcomeDontShowAgain,
                                onDismiss: { withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { showManualWelcomeOverlay = false } }
                            )
                            .padding(.horizontal, 32)
                            .scaleEffect(showManualWelcomeOverlay ? 1 : 0.3)
                            .opacity(showManualWelcomeOverlay ? 1 : 0)
                        }
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                        .ignoresSafeArea(.all)
                        .allowsHitTesting(showManualWelcomeOverlay)
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showManualWelcomeOverlay)
                    }
                }
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .openHistoryWithVocabularyFilter)) { _ in
            selectedTab = 0
            historyInitialFilter = .vocabulary
        }
        .onReceive(NotificationCenter.default.publisher(for: .openHistoryWithGrammarFilter)) { _ in
            selectedTab = 0
            historyInitialFilter = .grammar
        }
        .onReceive(NotificationCenter.default.publisher(for: .openHistoryWithAdjectivesFilter)) { _ in
            selectedTab = 0
            historyInitialFilter = .adjectives
        }
        .onReceive(NotificationCenter.default.publisher(for: .openHistoryWithWorderFilter)) { _ in
            selectedTab = 0
            historyInitialFilter = .worder
        }
        .preferredColorScheme(darkModeEnabled ? .dark : .light)
    }

    // MARK: - View Components

    @ViewBuilder
    private var mainContentArea: some View {
        if selectedTab == 0 {
            HistoryView(filterType: nil, useAsMainTab: true, initialFilter: $historyInitialFilter)
        } else if selectedTab == 1 {
            AppFavoritesView()
        } else if selectedTab == 2 {
            homeView
        } else if selectedTab == 3 {
            ManualView(showWelcomePopup: $showManualWelcomeOverlay)
        } else {
            AppSettingsView()
        }
    }

    @ViewBuilder
    private var homeView: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Fixed header section
                VStack(spacing: 0) {
                    // Title
                    HStack(spacing: 0) {
                        Text("Swedi")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                        Text("shly")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(.green)
                    }
                    .padding(.top, 20)
//                    .padding(.bottom, 2)

                    // Talking image (add "Talking" to Assets.xcassets to display)
                    Image("Talking")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 160, height: 160)
                        .padding(.bottom, 20)
                        .padding(.top, 5)

                    // Subtitle: black in light mode, gray in dark mode
                    Text("What would you like to learn today?")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundColor(colorScheme == .dark ? Color(.systemGray) : .black)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.top, -10)
                        .padding(.bottom, 35)
                }

                // Topics section (6 topics, no scroll)
                LazyVGrid(columns: [
                    GridItem(.flexible(minimum: 160)),
                    GridItem(.flexible(minimum: 160))
                ], spacing: 8) {
                    ForEach(Array(topics.enumerated()), id: \.element) { index, topic in
                        TopicCard(
                            topic: topic,
                            isPopular: false,
                            isDisabled: topic == "Coming soon..."
                        ) { selectedTopic in
                            if selectedTopic == "Vocabulary" {
                                showVocabularyView = true
                            } else if selectedTopic == "Grammar" {
                                showGrammarView = true
                            } else if selectedTopic == "Verbs" {
                                showVerbsView = true
                            } else if selectedTopic == "Adjectives" {
                                showAdjectivesView = true
                            } else if selectedTopic == "Word Order" {
                                showWorderView = true
                            }
                        }
                        .opacity(topicsAppeared ? 1 : 0)
                        .scaleEffect(topicsAppeared ? 1 : 0.85)
                        .offset(y: topicsAppeared ? 0 : 24)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.75)
                                .delay(Double(index) * 0.08),
                            value: topicsAppeared
                        )
                    }
                }
                .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 40 : 20)
                .padding(.bottom, 20)
                .onAppear {
                    topicsAppeared = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        topicsAppeared = true
                    }
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationDestination(isPresented: $showVocabularyView) {
                VocabularyView()
            }
            .navigationDestination(isPresented: $showGrammarView) {
                GrammarMainWrapperView()
            }
            .navigationDestination(isPresented: $showVerbsView) {
                VerbsView()
            }
            .navigationDestination(isPresented: $showAdjectivesView) {
                AdjectivesView()
            }
            .navigationDestination(isPresented: $showWorderView) {
                WorderView()
            }
        }
    }

    @ViewBuilder
    private func footerMenu(geometry: GeometryProxy) -> some View {
        // Footer menu with 5 buttons - simple layout with top curved background
        ZStack(alignment: .bottom) {
            // System background extending to bottom including safe area
            VStack(spacing: 0) {
                // Main menu background with curved top edges and shadow
                UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 20)
                    .fill(Color(.systemBackground))
                    .frame(width: geometry.size.width, height: menuHeight)
                    .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: -3)

                // Extension to fill bottom safe area
                Rectangle()
                    .fill(Color(.systemBackground))
                    .frame(width: geometry.size.width)
                    .frame(height: geometry.safeAreaInsets.bottom)
            }

            // Buttons
            HStack(spacing: menuButtonSpacing) {
                TabBarButton(
                    icon: tabIcon(for: 0),
                    label: tabTitle(for: 0),
                    isCustomIcon: false,
                    isSelected: selectedTab == 0,
                    action: { selectedTab = 0 }
                )

                TabBarButton(
                    icon: tabIcon(for: 1),
                    label: tabTitle(for: 1),
                    isCustomIcon: false,
                    isSelected: selectedTab == 1,
                    action: { selectedTab = 1 }
                )

                TabBarButton(
                    icon: tabIcon(for: 2),
                    label: tabTitle(for: 2),
                    isCustomIcon: false,
                    isSelected: selectedTab == 2,
                    action: { selectedTab = 2 }
                )

                TabBarButton(
                    icon: tabIcon(for: 3),
                    label: tabTitle(for: 3),
                    isCustomIcon: false,
                    isSelected: selectedTab == 3,
                    action: { selectedTab = 3 }
                )

                TabBarButton(
                    icon: tabIcon(for: 4),
                    label: tabTitle(for: 4),
                    isCustomIcon: false,
                    isSelected: selectedTab == 4,
                    action: { selectedTab = 4 }
                )
            }
            .frame(width: geometry.size.width, height: menuHeight)
        }
        .zIndex(1) // Ensure menu is above content
    }

    private func tabIcon(for index: Int) -> String {
        switch index {
        case 0: return "clock.arrow.circlepath"
        case 1: return "star.fill"
        case 2: return "house.fill"
        case 3: return "list.bullet.clipboard.fill"
        case 4: return "gearshape.fill"
        default: return "house.fill"
        }
    }

    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "History"
        case 1: return "Favorites"
        case 2: return "Home"
        case 3: return "My list"
        case 4: return "Settings"
        default: return "Home"
        }
    }
}

extension Notification.Name {
    /// Posted by Vocabulary PracticeView "Previous practices" to open the History tab with Vocabulary filter.
    static let openHistoryWithVocabularyFilter = Notification.Name("OpenHistoryWithVocabularyFilter")
    /// Posted by Grammar test views "My previous tests" to open the History tab with Grammar filter.
    static let openHistoryWithGrammarFilter = Notification.Name("OpenHistoryWithGrammarFilter")
    /// Posted by Adjective views "Previous practices" to open the History tab with Adjectives filter.
    static let openHistoryWithAdjectivesFilter = Notification.Name("OpenHistoryWithAdjectivesFilter")
    /// Posted by Worder views "Previous practices/tests" to open the History tab with Worder filter.
    static let openHistoryWithWorderFilter = Notification.Name("OpenHistoryWithWorderFilter")
}

#Preview {
    ContentView()
}
