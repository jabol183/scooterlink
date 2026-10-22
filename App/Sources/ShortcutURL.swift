import Foundation

/// Builds Apple's documented Shortcuts x-callback-url using only public URL schemes.
/// This launches the user's own Shortcut; it is NOT a private system media command.
enum ShortcutURL {
    static let callbackScheme = "scooterlinkmusic"
    static let completionURL = "scooterlinkmusic://shortcut-complete"

    static func run(name: String) -> URL? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        var components = URLComponents()
        components.scheme = "shortcuts"
        components.host = "x-callback-url"
        components.path = "/run-shortcut"
        components.queryItems = [
            URLQueryItem(name: "name", value: trimmed),
            URLQueryItem(name: "x-success", value: completionURL),
            URLQueryItem(name: "x-cancel", value: completionURL),
            URLQueryItem(name: "x-error", value: completionURL)
        ]
        return components.url
    }
}
