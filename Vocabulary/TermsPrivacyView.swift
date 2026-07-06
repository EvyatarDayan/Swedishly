//
//  TermsPrivacyView.swift
//  SWVocabulary
//
//  Created by EVYATAR DAYAN on 2026-01-26.
//

import SwiftUI

struct TermsPrivacyView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Segmented Control
                Picker("Section", selection: $selectedTab) {
                    Text("Terms").tag(0)
                    Text("Privacy").tag(1)
                    Text("Disclaimer").tag(2)
                }
                .pickerStyle(.segmented)
                .tint(.appRed)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(contentText)
                            .font(.body)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Terms & Privacy")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.appRed)
                }
                SettingsModalToolbarItem(placement: .navigationBarTrailing) {
                    SettingsModalPlainButton(title: "Done", action: { dismiss() })
                }
            }
        }
    }
    
    private var contentText: String {
        switch selectedTab {
        case 0:
            return termsContent
        case 1:
            return privacyContent
        default:
            return disclaimerContent
        }
    }
    
    private let termsContent = """
    TERMS OF USE
    
    Last Updated: January 26, 2026
    
    Welcome to Swedishly. These Terms of Use ("Terms") govern your access to and use of the Swedishly mobile application ("App"). By using the App, you agree to be bound by these Terms.
    
    1. ACCEPTANCE OF TERMS
    By downloading, installing, or using Swedishly, you acknowledge that you have read, understood, and agree to be bound by these Terms and our Privacy Policy.
    
    2. DESCRIPTION OF SERVICE
    Swedishly is a mobile application designed to help users learn Swedish through multiple topics, including vocabulary, grammar, verbs, adjectives, and word order. The App allows users to:
    - Learn Swedish words with English translations
    - Practice vocabulary with multiple-choice questions
    - Practice grammar, verbs, adjectives, and word order with interactive exercises and tests
    - Save favorite words and sentences for quick access
    - Track learning progress through practice sessions and tests
    - Review word states (new, learning, review, weak, mastered)
    
    3. USER ACCOUNTS
    You may use the App without creating an account. All data is stored locally on your device.
    
    4. ACCEPTABLE USE
    You agree to use the App only for lawful purposes and in accordance with these Terms. You agree not to:
    - Use the App for any illegal or unauthorized purpose
    - Attempt to gain unauthorized access to any part of the App
    - Interfere with or disrupt the App's functionality
    - Use automated systems to access the App
    
    5. INTELLECTUAL PROPERTY
    The App and its content, including but not limited to text, graphics, logos, and software, are the property of Swedishly (ABASHELARI) and are protected by copyright and other intellectual property laws.
    
    6. LIMITATION OF LIABILITY
    Swedishly is provided "as is" without warranties of any kind. We do not guarantee that the App will be error-free or uninterrupted. In no event shall Swedishly be liable for any indirect, incidental, or consequential damages.
    
    7. MODIFICATIONS TO TERMS
    We reserve the right to modify these Terms at any time. Your continued use of the App after any changes constitutes acceptance of the modified Terms.
    
    8. CONTACT INFORMATION
    If you have any questions about these Terms, please contact us through the App's support section.
    """
    
    private let privacyContent = """
    PRIVACY POLICY
    
    Last Updated: January 26, 2026
    
    At Swedishly, we are committed to protecting your privacy. This Privacy Policy explains how we handle your information when you use our mobile application.
    
    1. NO DATA COLLECTION
    Swedishly does not collect, transmit, or store any of your personal information on external servers. We do not collect:
    - Usage analytics
    - Device information
    - Location data
    - Any other personal data
    
    All information you enter into the App remains on your device only.
    
    2. LOCAL DATA STORAGE
    All your data is stored exclusively on your device using secure local storage methods. This includes:
    - Saved words in "Words"
    - Practice sessions and test results
    - Test and practice history
    - Word states (weak, learning, review, mastered)
    - Wrong answers tracking
    - App settings and preferences
    
    Your data never leaves your device and is not transmitted to any external servers or third parties.
    
    3. DATA MANAGEMENT
    You have full control over your data:
    - Clear History: In Settings, you can use the \"Clear History\" option to remove all test and practice history (Vocabulary, Grammar, Verbs, Adjectives, Worder). This action cannot be undone.
    - Clear Cache: In Settings, you can clear all word states and wrong answers cache.
    - My List: You can add or remove words and sentences from your lists at any time.
    These actions are permanent and cannot be reversed.
    
    4. NO DATA SHARING
    Since we do not collect any data, we do not and cannot share your information with anyone. Your privacy is fully protected because your data never leaves your device.
    
    5. DATA SECURITY
    Your data is protected by your device's built-in security features. We use secure local storage methods provided by iOS to ensure your information remains private and secure on your device.
    
    6. YOUR RIGHTS
    You have complete control over your data:
    - All data is stored locally on your device
    - You can clear all data at any time through Settings
    - No external parties have access to your information
    
    7. CHILDREN'S PRIVACY
    Our App is suitable for users of all ages. Since we do not collect any data, we do not collect personal information from anyone, including children.
    
    8. CHANGES TO THIS POLICY
    We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy in the App.
    
    9. CONTACT US
    If you have any questions about this Privacy Policy, please contact us through the App's support section.
    """
    
    private let disclaimerContent = """
    DISCLAIMER
    
    Last Updated: January 26, 2026
    
    1. NO WARRANTY
    Swedishly is provided "as is" and "as available" without any warranties, express or implied. We do not guarantee that the App will be error-free, uninterrupted, or free from defects.
    
    2. ACCURACY OF CONTENT
    While we strive to ensure accurate vocabulary translations and content, we cannot guarantee the accuracy of all translations and learning materials. Users are responsible for verifying information and should consult additional resources for comprehensive learning.
    
    3. LIMITATION OF LIABILITY
    To the fullest extent permitted by law, Swedishly shall not be liable for any indirect, incidental, special, consequential, or punitive damages, including but not limited to loss of data or use, arising out of or in connection with the use of the App.
    
    4. USER RESPONSIBILITY
    Users are solely responsible for:
    - The accuracy of information entered into the App
    - Verifying vocabulary translations
    - Using the App as a supplementary learning tool
    - Maintaining the security of their device
    
    5. THIRD-PARTY SERVICES
    The App may integrate services such as text-to-speech for pronunciation. These are operated by third parties and are subject to their own terms of use and privacy policies.
    
    6. CHANGES TO THE APP
    We reserve the right to modify, suspend, or discontinue the App at any time without prior notice. We shall not be liable to you or any third party for any modification, suspension, or discontinuance.
    
    7. NO PROFESSIONAL ADVICE
    The App is for educational and learning purposes only. It does not constitute professional language instruction or certification. Users should consult with qualified language instructors for formal education.
    
    8. ACCEPTANCE
    By using Swedishly, you acknowledge that you have read, understood, and agree to this Disclaimer.
    """
}

#Preview {
    TermsPrivacyView()
}
