import Foundation

/// Maps handlebar events to public, App Store-eligible music integrations.
/// All-app playback uses Apple's documented Shortcuts URL scheme, not MediaRemote.
enum ButtonActions {
    static func handle(_ function: ButtonFunction, music: MusicController, log: @escaping (String) -> Void) {
        let command: MusicCommand
        switch function {
        case .select, .back:
            command = .togglePlayPause
        case .next:
            command = .next
        case .previous:
            command = .previous
        default:
            return
        }
        log(music.perform(command))
    }
}
