import Foundation
import MediaPlayer
import SwiftUI
import UIKit

/// Music integration using only Apple's public MediaPlayer APIs.
/// The system player controls the Music app, not Spotify or YouTube Music.
enum MusicSource: String, CaseIterable, Identifiable {
    case appleMusic = "Apple Music"
    case shortcuts = "All apps (Beta)"
    var id: String { rawValue }
}

enum MusicCommand {
    case togglePlayPause, next, previous
}

final class MusicController: ObservableObject {
    @Published var source: MusicSource {
        didSet {
            UserDefaults.standard.set(source.rawValue, forKey: Self.preferenceKey)
            refresh()
        }
    }
    @Published private(set) var authorization: MPMediaLibraryAuthorizationStatus = MPMediaLibrary.authorizationStatus()
    @Published private(set) var isPlaying = false
    @Published private(set) var trackTitle = "Nothing playing"
    @Published private(set) var artist = "Start music in the Music app or choose songs here"
    @Published private(set) var feedback = "Ready for Apple Music"
    @Published var playPauseShortcut: String {
        didSet { UserDefaults.standard.set(playPauseShortcut, forKey: "shortcutPlayPause") }
    }
    @Published var nextShortcut: String {
        didSet { UserDefaults.standard.set(nextShortcut, forKey: "shortcutNext") }
    }
    @Published var previousShortcut: String {
        didSet { UserDefaults.standard.set(previousShortcut, forKey: "shortcutPrevious") }
    }

    private static let preferenceKey = "preferredMusicSource"
    private let player = MPMusicPlayerController.systemMusicPlayer
    private var observers: [NSObjectProtocol] = []

    init() {
        source = MusicSource(rawValue: UserDefaults.standard.string(forKey: Self.preferenceKey) ?? "") ?? .appleMusic
        playPauseShortcut = UserDefaults.standard.string(forKey: "shortcutPlayPause") ?? "Honda Music Play Pause"
        nextShortcut = UserDefaults.standard.string(forKey: "shortcutNext") ?? "Honda Music Next"
        previousShortcut = UserDefaults.standard.string(forKey: "shortcutPrevious") ?? "Honda Music Previous"
        player.beginGeneratingPlaybackNotifications()
        for name in [Notification.Name.MPMusicPlayerControllerPlaybackStateDidChange,
                     Notification.Name.MPMusicPlayerControllerNowPlayingItemDidChange] {
            observers.append(NotificationCenter.default.addObserver(forName: name, object: player, queue: .main) { [weak self] _ in
                self?.refresh()
            })
        }
        refresh()
    }

    deinit {
        for observer in observers { NotificationCenter.default.removeObserver(observer) }
        player.endGeneratingPlaybackNotifications()
    }

    var isAuthorized: Bool { authorization == .authorized }

    func requestAccess() {
        MPMediaLibrary.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.authorization = status
                self?.refresh()
            }
        }
    }

    func refresh() {
        authorization = MPMediaLibrary.authorizationStatus()
        guard authorization == .authorized else {
            isPlaying = false
            trackTitle = "Apple Music access needed"
            artist = "Grant media-library access to enable playback controls"
            return
        }
        isPlaying = player.playbackState == .playing
        trackTitle = player.nowPlayingItem?.title ?? "Nothing playing"
        artist = player.nowPlayingItem?.artist ?? "Start music in the Music app or choose songs here"
    }

    /// Always called on the main thread: the Bluetooth delegate uses the main queue.
    /// No universal media control is attempted when an external app is selected.
    @discardableResult
    func perform(_ command: MusicCommand) -> String {
        if source == .shortcuts { return runUserShortcut(command) }
        refresh()
        guard isAuthorized else {
            feedback = "Enable Apple Music access in the app first."
            return feedback
        }
        switch command {
        case .togglePlayPause:
            if player.playbackState == .playing {
                player.pause()
                feedback = "Apple Music: pause requested"
            } else {
                player.play()
                feedback = "Apple Music: play requested"
            }
        case .next:
            player.skipToNextItem()
            feedback = "Apple Music: next track requested"
        case .previous:
            player.skipToPreviousItem()
            feedback = "Apple Music: previous track requested"
        }
        refresh()
        return feedback
    }

    /// Experimental unlocked, foreground-only handoff to the user's own Shortcut.
    /// No system-wide playback command is sent by this app.
    private func runUserShortcut(_ command: MusicCommand) -> String {
        guard UIApplication.shared.applicationState == .active else {
            feedback = "Shortcuts needs ScooterLink in the foreground and the iPhone unlocked."
            return feedback
        }
        let name: String
        switch command {
        case .togglePlayPause: name = playPauseShortcut
        case .next: name = nextShortcut
        case .previous: name = previousShortcut
        }
        guard let url = ShortcutURL.run(name: name) else {
            feedback = "Enter a Shortcut name in music settings."
            return feedback
        }
        feedback = "Requested Shortcut: \(name). Playback is not yet confirmed."
        UIApplication.shared.open(url, options: [:]) { [weak self] launched in
            if !launched {
                DispatchQueue.main.async {
                    self?.feedback = "Could not open Shortcuts. Is the Shortcuts app installed?"
                }
            }
        }
        return feedback
    }

    func play(_ collection: MPMediaItemCollection) {
        guard isAuthorized, !collection.items.isEmpty else {
            feedback = "Enable Apple Music access and choose at least one song."
            return
        }
        player.setQueue(with: collection)
        player.play()
        feedback = "Playing your selected Music library songs"
        refresh()
    }
}

/// Apple's standard music-library picker. Does not download tracks or use private APIs.
struct MusicLibraryPicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onPicked: (MPMediaItemCollection) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> MPMediaPickerController {
        let picker = MPMediaPickerController(mediaTypes: .music)
        picker.delegate = context.coordinator
        picker.allowsPickingMultipleItems = true
        picker.showsCloudItems = true
        return picker
    }

    func updateUIViewController(_ controller: MPMediaPickerController, context: Context) {}

    final class Coordinator: NSObject, MPMediaPickerControllerDelegate {
        var parent: MusicLibraryPicker
        init(_ parent: MusicLibraryPicker) { self.parent = parent }

        func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
            parent.onPicked(mediaItemCollection)
            parent.isPresented = false
        }

        func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
            parent.isPresented = false
        }
    }
}
