//
//  ManualModals.swift
//  Swedishly
//

import SwiftUI

// MARK: - AddManualSentenceModal
struct AddManualSentenceModal: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var manualManager = ManualManager.shared
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @StateObject private var sessionManager = SessionManager.shared
    @State private var swedishText = ""
    @State private var englishText = ""
    @State private var isRecordingSwedish = false
    @State private var isRecordingEnglish = false
    @State private var showDictationHint = false
    @State private var hintAnimationScale: CGFloat = 0.8
    @State private var recordingDots = ""
    @State private var isActuallyRecordingSwedish = false
    @State private var isActuallyRecordingEnglish = false
    @State private var recordingTimer: Timer?
    @State private var speechErrorText: String?
    @FocusState private var isSwedishFieldFocused: Bool
    @FocusState private var isEnglishFieldFocused: Bool

    private var canSave: Bool {
        !swedishText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !englishText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func saveSentence() {
        guard canSave else { return }
        speechRecognizer.stopRecording()
        let sw = swedishText.trimmingCharacters(in: .whitespacesAndNewlines)
        let en = englishText.trimmingCharacters(in: .whitespacesAndNewlines)
        manualManager.addManualSentence(Sentence(swedish: sw, english: en))
        dismiss()
    }

    private func cancelAdd() {
        speechRecognizer.stopRecording()
        dismiss()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                VStack(spacing: 0) {
                    VStack(spacing: 20) {
                        Text("Swedish")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        VStack(alignment: .leading, spacing: 15) {
                            HStack(spacing: 12) {
                                Spacer()
                                if isActuallyRecordingSwedish {
                                    HStack(spacing: 2) {
                                        Text("Recording")
                                            .font(.body)
                                            .fontWeight(.bold)
                                            .foregroundColor(.green)
                                            .lineLimit(1)
                                        Text(recordingDots)
                                            .font(.body)
                                            .fontWeight(.bold)
                                            .foregroundColor(.green)
                                            .frame(width: 15, alignment: .leading)
                                            .fixedSize()
                                    }
                                    .fixedSize()
                                    .transition(.opacity)
                                }
                                Spacer()
                                Button(action: {
                                    if isRecordingSwedish {
                                        speechRecognizer.stopRecording()
                                        isRecordingSwedish = false
                                    } else {
                                        speechRecognizer.startRecording(language: "sv-SE") { text in
                                            swedishText = text
                                        }
                                        isRecordingSwedish = true
                                    }
                                    if showDictationHint {
                                        sessionManager.hasShownManualDictationHint = true
                                        showDictationHint = false
                                    }
                                }) {
                                    Image(systemName: isRecordingSwedish ? "stop.circle.fill" : "mic.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(isRecordingSwedish ? .red : .appRed)
                                }
                                .disabled(isRecordingEnglish)
                            }
                            HStack(spacing: 8) {
                                TextField("Skriv en mening på svenska\nEx: Jag arbetar hemma idag.", text: $swedishText, axis: .vertical)
                                    .lineLimit(4...8)
                                    .font(.title3)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 19)
                                    .focused($isSwedishFieldFocused)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                if !swedishText.isEmpty {
                                    Button(action: { swedishText = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                            .font(.system(size: 20))
                                            .padding(.trailing, 12)
                                    }
                                }
                            }
                            .frame(minHeight: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isSwedishFieldFocused ? Color.blue : Color(.systemGray4), lineWidth: isSwedishFieldFocused ? 2 : 1.5)
                            )
                            .animation(.easeInOut(duration: 0.2), value: isSwedishFieldFocused)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 100)
                    .padding(.bottom, 20)
                    
                    Rectangle()
                        .frame(height: 10)
                        .foregroundColor(Color(.separator))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                    
                    VStack(spacing: 20) {
                        Text("English")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        VStack(alignment: .leading, spacing: 15) {
                            HStack(spacing: 12) {
                                Spacer()
                                if isActuallyRecordingEnglish {
                                    HStack(spacing: 2) {
                                        Text("Recording")
                                            .font(.body)
                                            .fontWeight(.bold)
                                            .foregroundColor(.green)
                                            .lineLimit(1)
                                        Text(recordingDots)
                                            .font(.body)
                                            .fontWeight(.bold)
                                            .foregroundColor(.green)
                                            .frame(width: 15, alignment: .leading)
                                            .fixedSize()
                                    }
                                    .fixedSize()
                                    .transition(.opacity)
                                }
                                Spacer()
                                Button(action: {
                                    if isRecordingEnglish {
                                        speechRecognizer.stopRecording()
                                        isRecordingEnglish = false
                                    } else {
                                        speechRecognizer.startRecording(language: "en-US") { text in
                                            englishText = text
                                        }
                                        isRecordingEnglish = true
                                    }
                                }) {
                                    Image(systemName: isRecordingEnglish ? "stop.circle.fill" : "mic.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(isRecordingEnglish ? .red : .appRed)
                                }
                                .disabled(isRecordingSwedish)
                            }
                            HStack(spacing: 8) {
                                TextField("Write the English meaning\nEx: I work from home today.", text: $englishText, axis: .vertical)
                                    .lineLimit(4...8)
                                    .font(.title3)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 16)
                                    .focused($isEnglishFieldFocused)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                if !englishText.isEmpty {
                                    Button(action: { englishText = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                            .font(.system(size: 20))
                                            .padding(.trailing, 12)
                                    }
                                }
                            }
                            .frame(minHeight: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isEnglishFieldFocused ? Color.blue : Color(.systemGray4), lineWidth: isEnglishFieldFocused ? 2 : 1.5)
                            )
                            .animation(.easeInOut(duration: 0.2), value: isEnglishFieldFocused)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 40)
                }
            }

                VStack(spacing: 0) {
                    HStack {
                        Text("Save")
                            .font(.body)
                            .foregroundColor(canSave ? .appRed : .gray)
                            .contentShape(Rectangle())
                            .onTapGesture { saveSentence() }

                        Spacer()

                        Text("Cancel")
                            .font(.body)
                            .foregroundColor(.appRed)
                            .contentShape(Rectangle())
                            .onTapGesture { cancelAdd() }
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 30)

                    Image("Talking")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: UIDevice.current.userInterfaceIdiom == .pad ? 150 : 100, height: UIDevice.current.userInterfaceIdiom == .pad ? 150 : 100)
                        .padding(.top, 8)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear {
            speechRecognizer.setOnRecordingStopped {
                isRecordingSwedish = false
                isRecordingEnglish = false
            }
            if !sessionManager.hasShownManualDictationHint {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if !sessionManager.hasShownManualDictationHint {
                        showDictationHint = true
                        withAnimation(.easeInOut(duration: 0.5)) { hintAnimationScale = 1.0 }
                    }
                }
            }
        }
        .onChange(of: isRecordingSwedish) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if speechRecognizer.isRecording && isRecordingSwedish {
                        isActuallyRecordingSwedish = true
                        startRecordingAnimation()
                    }
                }
            } else {
                isActuallyRecordingSwedish = false
                stopRecordingAnimation()
            }
        }
        .onChange(of: isRecordingEnglish) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if speechRecognizer.isRecording && isRecordingEnglish {
                        isActuallyRecordingEnglish = true
                        startRecordingAnimation()
                    }
                }
            } else {
                isActuallyRecordingEnglish = false
                stopRecordingAnimation()
            }
        }
        .onChange(of: speechRecognizer.isRecording) { _, newValue in
            if newValue {
                if isRecordingSwedish {
                    isActuallyRecordingSwedish = true
                    startRecordingAnimation()
                } else if isRecordingEnglish {
                    isActuallyRecordingEnglish = true
                    startRecordingAnimation()
                }
            } else {
                isActuallyRecordingSwedish = false
                isActuallyRecordingEnglish = false
                stopRecordingAnimation()
            }
        }
        .onDisappear {
            speechRecognizer.stopRecording()
            stopRecordingAnimation()
        }
        .onChange(of: speechRecognizer.errorMessage) { _, new in
            speechErrorText = new
        }
        .alert("Dictation unavailable", isPresented: Binding(
            get: { speechErrorText != nil },
            set: { if !$0 { speechErrorText = nil; speechRecognizer.errorMessage = nil } }
        )) {
            Button("OK") {
                speechErrorText = nil
                speechRecognizer.errorMessage = nil
            }
        } message: {
            Text(speechErrorText ?? "")
        }
    }
    
    private func startRecordingAnimation() {
        recordingTimer?.invalidate()
        recordingDots = "."
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            withAnimation {
                recordingDots = recordingDots == "." ? ".." : "."
            }
        }
        RunLoop.main.add(recordingTimer!, forMode: .common)
    }
    
    private func stopRecordingAnimation() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        recordingDots = ""
    }
}

// MARK: - EditManualSentenceModal
struct EditManualSentenceModal: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @StateObject private var sessionManager = SessionManager.shared
    let sentence: Sentence
    let onUpdate: (Sentence) -> Void
    @State private var swedishText: String
    @State private var englishText: String
    @State private var isRecordingSwedish = false
    @State private var isRecordingEnglish = false
    @State private var showDictationHint = false
    @State private var hintAnimationScale: CGFloat = 0.8
    @State private var recordingDots = ""
    @State private var isActuallyRecordingSwedish = false
    @State private var isActuallyRecordingEnglish = false
    @State private var recordingTimer: Timer?
    @State private var speechErrorText: String?
    @FocusState private var isSwedishFieldFocused: Bool
    @FocusState private var isEnglishFieldFocused: Bool
    
    init(sentence: Sentence, onUpdate: @escaping (Sentence) -> Void) {
        self.sentence = sentence
        self.onUpdate = onUpdate
        _swedishText = State(initialValue: sentence.swedish)
        _englishText = State(initialValue: sentence.english)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    VStack(spacing: 20) {
                        Text("Swedish")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        VStack(alignment: .leading, spacing: 15) {
                            HStack(spacing: 12) {
                                Spacer()
                                if isActuallyRecordingSwedish {
                                    HStack(spacing: 2) {
                                        Text("Recording")
                                            .font(.body)
                                            .fontWeight(.bold)
                                            .foregroundColor(.green)
                                            .lineLimit(1)
                                        Text(recordingDots)
                                            .font(.body)
                                            .fontWeight(.bold)
                                            .foregroundColor(.green)
                                            .frame(width: 15, alignment: .leading)
                                            .fixedSize()
                                    }
                                    .fixedSize()
                                    .transition(.opacity)
                                }
                                Spacer()
                                Button(action: {
                                    if isRecordingSwedish {
                                        speechRecognizer.stopRecording()
                                        isRecordingSwedish = false
                                    } else {
                                        speechRecognizer.startRecording(language: "sv-SE") { text in
                                            swedishText = text
                                        }
                                        isRecordingSwedish = true
                                    }
                                    if showDictationHint {
                                        sessionManager.hasShownManualDictationHint = true
                                        showDictationHint = false
                                    }
                                }) {
                                    Image(systemName: isRecordingSwedish ? "stop.circle.fill" : "mic.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(isRecordingSwedish ? .red : .appRed)
                                }
                                .disabled(isRecordingEnglish)
                            }
                            HStack(spacing: 8) {
                                TextField("Skriv en mening på svenska", text: $swedishText, axis: .vertical)
                                    .lineLimit(4...8)
                                    .font(.title3)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 19)
                                    .focused($isSwedishFieldFocused)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                if !swedishText.isEmpty {
                                    Button(action: { swedishText = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                            .font(.system(size: 20))
                                            .padding(.trailing, 12)
                                    }
                                }
                            }
                            .frame(minHeight: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isSwedishFieldFocused ? Color.blue : Color(.systemGray4), lineWidth: isSwedishFieldFocused ? 2 : 1.5)
                            )
                            .animation(.easeInOut(duration: 0.2), value: isSwedishFieldFocused)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 100)
                    .padding(.bottom, 20)
                    Rectangle()
                        .frame(height: 10)
                        .foregroundColor(Color(.separator))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                    VStack(spacing: 20) {
                        Text("English")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        VStack(alignment: .leading, spacing: 15) {
                            HStack(spacing: 12) {
                                Spacer()
                                if isActuallyRecordingEnglish {
                                    HStack(spacing: 2) {
                                        Text("Recording")
                                            .font(.body)
                                            .fontWeight(.bold)
                                            .foregroundColor(.green)
                                            .lineLimit(1)
                                        Text(recordingDots)
                                            .font(.body)
                                            .fontWeight(.bold)
                                            .foregroundColor(.green)
                                            .frame(width: 15, alignment: .leading)
                                            .fixedSize()
                                    }
                                    .fixedSize()
                                    .transition(.opacity)
                                }
                                Spacer()
                                Button(action: {
                                    if isRecordingEnglish {
                                        speechRecognizer.stopRecording()
                                        isRecordingEnglish = false
                                    } else {
                                        speechRecognizer.startRecording(language: "en-US") { text in
                                            englishText = text
                                        }
                                        isRecordingEnglish = true
                                    }
                                }) {
                                    Image(systemName: isRecordingEnglish ? "stop.circle.fill" : "mic.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(isRecordingEnglish ? .red : .appRed)
                                }
                                .disabled(isRecordingSwedish)
                            }
                            HStack(spacing: 8) {
                                TextField("Write the English meaning", text: $englishText, axis: .vertical)
                                    .lineLimit(4...8)
                                    .font(.title3)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 16)
                                    .focused($isEnglishFieldFocused)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                if !englishText.isEmpty {
                                    Button(action: { englishText = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                            .font(.system(size: 20))
                                            .padding(.trailing, 12)
                                    }
                                }
                            }
                            .frame(minHeight: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isEnglishFieldFocused ? Color.blue : Color(.systemGray4), lineWidth: isEnglishFieldFocused ? 2 : 1.5)
                            )
                            .animation(.easeInOut(duration: 0.2), value: isEnglishFieldFocused)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Edit Sentence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        speechRecognizer.stopRecording()
                        let sw = swedishText.trimmingCharacters(in: .whitespacesAndNewlines)
                        let en = englishText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !sw.isEmpty && !en.isEmpty {
                            onUpdate(Sentence(id: sentence.id, swedish: sw, english: en))
                            dismiss()
                        }
                    }) {
                        Text("Save")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                    .disabled(swedishText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                             englishText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                ToolbarItem(placement: .principal) {
                    Image("Talking")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: UIDevice.current.userInterfaceIdiom == .pad ? 150 : 100, height: UIDevice.current.userInterfaceIdiom == .pad ? 150 : 100)
                        .padding(.top, 150)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        speechRecognizer.stopRecording()
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            speechRecognizer.setOnRecordingStopped {
                isRecordingSwedish = false
                isRecordingEnglish = false
            }
            if !sessionManager.hasShownManualDictationHint {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if !sessionManager.hasShownManualDictationHint {
                        showDictationHint = true
                        withAnimation(.easeInOut(duration: 0.5)) { hintAnimationScale = 1.0 }
                    }
                }
            }
        }
        .onChange(of: isRecordingSwedish) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if speechRecognizer.isRecording && isRecordingSwedish {
                        isActuallyRecordingSwedish = true
                        editStartRecordingAnimation()
                    }
                }
            } else {
                isActuallyRecordingSwedish = false
                editStopRecordingAnimation()
            }
        }
        .onChange(of: isRecordingEnglish) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if speechRecognizer.isRecording && isRecordingEnglish {
                        isActuallyRecordingEnglish = true
                        editStartRecordingAnimation()
                    }
                }
            } else {
                isActuallyRecordingEnglish = false
                editStopRecordingAnimation()
            }
        }
        .onChange(of: speechRecognizer.isRecording) { _, newValue in
            if newValue {
                if isRecordingSwedish {
                    isActuallyRecordingSwedish = true
                    editStartRecordingAnimation()
                } else if isRecordingEnglish {
                    isActuallyRecordingEnglish = true
                    editStartRecordingAnimation()
                }
            } else {
                isActuallyRecordingSwedish = false
                isActuallyRecordingEnglish = false
                editStopRecordingAnimation()
            }
        }
        .onDisappear {
            speechRecognizer.stopRecording()
            editStopRecordingAnimation()
        }
        .onChange(of: speechRecognizer.errorMessage) { _, new in
            speechErrorText = new
        }
        .alert("Dictation unavailable", isPresented: Binding(
            get: { speechErrorText != nil },
            set: { if !$0 { speechErrorText = nil; speechRecognizer.errorMessage = nil } }
        )) {
            Button("OK") {
                speechErrorText = nil
                speechRecognizer.errorMessage = nil
            }
        } message: {
            Text(speechErrorText ?? "")
        }
    }
    
    private func editStartRecordingAnimation() {
        recordingTimer?.invalidate()
        recordingDots = "."
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            withAnimation { recordingDots = recordingDots == "." ? ".." : "." }
        }
        RunLoop.main.add(recordingTimer!, forMode: .common)
    }
    
    private func editStopRecordingAnimation() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        recordingDots = ""
    }
}

// MARK: - ManualSentenceModalView
struct ManualSentenceModalView: View {
    let initialSentence: Sentence
    let manualSentences: [Sentence]
    let onDismiss: () -> Void
    
    @State private var currentSentence: Sentence
    @State private var showTranslation = false
    @State private var isRefreshing = false
    @State private var currentIndex: Int
    @State private var showingEditModal = false
    @StateObject private var audioManager = AudioManager()
    @StateObject private var manualManager = ManualManager.shared
    
    init(sentence: Sentence, manualSentences: [Sentence], onDismiss: @escaping () -> Void) {
        self.initialSentence = sentence
        self.manualSentences = manualSentences
        self.onDismiss = onDismiss
        _currentSentence = State(initialValue: sentence)
        _currentIndex = State(initialValue: manualSentences.firstIndex(where: { $0.id == sentence.id }) ?? 0)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    VStack(spacing: 20) {
                        Text("Svenska")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .scaleEffect(isRefreshing ? 0.9 : 1.0)
                            .opacity(isRefreshing ? 0.5 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: isRefreshing)
                        Text(currentSentence.swedish)
                            .font(.title)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .opacity(isRefreshing ? 0.3 : 1.0)
                            .scaleEffect(isRefreshing ? 0.85 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: isRefreshing)
                    }
                    .padding(.top, 130)
                    .padding(.bottom, 20)
                    Spacer()
                    Rectangle()
                        .frame(height: 10)
                        .foregroundColor(Color(.separator))
                        .padding(.horizontal, 20)
                        .scaleEffect(isRefreshing ? 0.9 : 1.0)
                        .opacity(isRefreshing ? 0.5 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: isRefreshing)
                    Spacer()
                    VStack {
                        if !showTranslation {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.4)) { showTranslation = true }
                            }) {
                                HStack {
                                    Text("English")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 50)
                                .background(Color.appRed)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 20)
                            .scaleEffect(isRefreshing ? 0.2 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: isRefreshing)
                            .transition(.asymmetric(insertion: .scale(scale: 0), removal: .scale(scale: 0)))
                        }
                    }
                    .frame(height: 120)
                    Spacer()
                    HStack {
                        Button(action: {
                            if currentIndex > 0 {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isRefreshing = true
                                    showTranslation = false
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                    currentIndex -= 1
                                    currentSentence = manualManager.manualSentences[currentIndex]
                                    withAnimation(.easeInOut(duration: 0.3)) { isRefreshing = false }
                                }
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.primary)
                                .frame(width: 60, height: 60)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.separator), lineWidth: 1))
                                )
                                .offset(x: isRefreshing ? -20 : 0)
                                .animation(.easeInOut(duration: 0.3), value: isRefreshing)
                        }
                        .scaleEffect(isRefreshing ? 0.9 : 1.0)
                        .opacity(isRefreshing ? 0.5 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: isRefreshing)
                        Spacer()
                        Button(action: { audioManager.playAudio() }) {
                            Group {
                                if audioManager.isPlaying {
                                    Image(systemName: "pause.circle.fill")
                                        .font(.system(size: 40, weight: .medium))
                                        .foregroundColor(audioManager.isAudioReady ? .appRed : .gray)
                                } else {
                                    Image("audio-headphone")
                                        .resizable()
                                        .renderingMode(.template)
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(audioManager.isAudioReady ? .appRed : .gray)
                                }
                            }
                            .frame(width: 60, height: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.separator), lineWidth: 1))
                            )
                        }
                        .disabled(audioManager.isPlaying || !audioManager.isAudioReady)
                        .scaleEffect(isRefreshing ? 0.9 : 1.0)
                        .opacity(isRefreshing ? 0.5 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: isRefreshing)
                        Spacer()
                        Button(action: {
                            if currentIndex < manualManager.manualSentences.count - 1 {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isRefreshing = true
                                    showTranslation = false
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                    currentIndex += 1
                                    currentSentence = manualManager.manualSentences[currentIndex]
                                    withAnimation(.easeInOut(duration: 0.3)) { isRefreshing = false }
                                }
                            }
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.primary)
                                .frame(width: 60, height: 60)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.separator), lineWidth: 1))
                                )
                                .offset(x: isRefreshing ? 20 : 0)
                                .animation(.easeInOut(duration: 0.3), value: isRefreshing)
                        }
                        .scaleEffect(isRefreshing ? 0.9 : 1.0)
                        .opacity(isRefreshing ? 0.5 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: isRefreshing)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                }
                if showTranslation {
                    VStack {
                        Spacer()
                        VStack(spacing: 20) {
                            Text("English")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .scaleEffect(isRefreshing ? 0.9 : 1.0)
                                .opacity(isRefreshing ? 0.5 : 1.0)
                                .animation(.easeInOut(duration: 0.3), value: isRefreshing)
                            Text(currentSentence.english)
                                .font(.title)
                                .fontWeight(.medium)
                                .foregroundColor(.appRed)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .scaleEffect(isRefreshing ? 0.85 : 1.0)
                                .opacity(isRefreshing ? 0.3 : 1.0)
                                .animation(.easeInOut(duration: 0.3), value: isRefreshing)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 230)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .leading)),
                            removal: .opacity
                        ))
                        Spacer()
                    }
                    .zIndex(1)
                }

                VStack(spacing: 0) {
                    HStack {
                        Text("Edit")
                            .font(.body)
                            .foregroundColor(.appRed)
                            .contentShape(Rectangle())
                            .onTapGesture { showingEditModal = true }

                        Spacer()

                        Text("Close")
                            .font(.body)
                            .foregroundColor(.appRed)
                            .contentShape(Rectangle())
                            .onTapGesture { onDismiss() }
                            .scaleEffect(isRefreshing ? 0.9 : 1.0)
                            .opacity(isRefreshing ? 0.5 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: isRefreshing)
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 30)

                    Image("Talking")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: UIDevice.current.userInterfaceIdiom == .pad ? 150 : 100, height: UIDevice.current.userInterfaceIdiom == .pad ? 150 : 100)
                        .scaleEffect(isRefreshing ? 0.9 : 1.0)
                        .opacity(isRefreshing ? 0.5 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: isRefreshing)
                        .padding(.top, 8)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingEditModal) {
                EditManualSentenceModal(sentence: currentSentence) { updatedSentence in
                    manualManager.updateManualSentence(updatedSentence)
                    currentSentence = updatedSentence
                    if let newIndex = manualManager.manualSentences.firstIndex(where: { $0.id == updatedSentence.id }) {
                        currentIndex = newIndex
                    }
                }
            }
        }
        .onAppear {
            audioManager.generateAudio(for: currentSentence.swedish)
        }
        .onChange(of: currentSentence) {
            audioManager.generateAudio(for: currentSentence.swedish)
        }
        .onDisappear {
            audioManager.cleanupAudio()
        }
    }
}
