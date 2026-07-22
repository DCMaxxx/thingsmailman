import SwiftUI

struct AutomationAboutSection: View {
    private let contactURL = URL(string: "mailto:maxime.dechalendar@me.com")
    private let privacyPolicyURL = URL(string: "https://dcmaxxx.github.io/thingsmailman/privacy.html")

    var body: some View {
        Section {
            VStack(spacing: 4) {
                Text("Things Mailman \(version) (\(build))")
                    .foregroundStyle(.secondary)
                Text("Made with love by Maxime de Chalendar")
                    .foregroundStyle(.secondary)

                HStack {
                    if let contactURL {
                        Link("Contact me", destination: contactURL)
                            .accessibilityHint("Emails maxime.dechalendar@me.com")
                    }

                    if let privacyPolicyURL {
                        Link("Privacy Policy", destination: privacyPolicyURL)
                            .accessibilityHint("Opens the Things Mailman privacy policy")
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    private var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }
}
