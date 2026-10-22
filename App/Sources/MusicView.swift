import SwiftUI
import MediaPlayer

/// Foreground music UI. Honda buttons and the on-screen controls call the same
/// MusicController public-API implementation.
struct MusicCard: View {
    @ObservedObject var music: MusicController
    @State private var showPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("MUSIC", systemImage: "music.note")
                    .font(.headline.weight(.bold))
                Spacer()
                Text("Public APIs only")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Picker("Music service", selection: $music.source) {
                ForEach(MusicSource.allCases) { source in
                    Text(source.rawValue).tag(source)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Music source")

            if music.source == .appleMusic {
                appleMusicContent
            } else {
                shortcutsContent
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(.white.opacity(0.08)))
        .sheet(isPresented: $showPicker) {
            MusicLibraryPicker(isPresented: $showPicker) { collection in
                music.play(collection)
            }
        }
    }

    @ViewBuilder
    private var appleMusicContent: some View {
        if !music.isAuthorized {
            VStack(alignment: .leading, spacing: 10) {
                Text("Control your Music library using the Honda handlebar buttons.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button {
                    music.requestAccess()
                } label: {
                    Label(music.authorization == .denied || music.authorization == .restricted
                          ? "Music permission unavailable — open Settings"
                          : "Enable Apple Music access", systemImage: "lock.open")
                }
                .buttonStyle(.borderedProminent)
                .disabled(music.authorization == .denied || music.authorization == .restricted)
                if music.authorization == .denied || music.authorization == .restricted {
                    Text("Allow media-library access in iPhone Settings to enable these controls.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text(music.trackTitle)
                    .font(.title3.weight(.semibold))
                    .lineLimit(2)
                Text(music.artist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Label(music.isPlaying ? "Playing" : "Paused / idle",
                      systemImage: music.isPlaying ? "waveform" : "pause.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 24) {
                Spacer()
                Button { music.perform(.previous) } label: {
                    Image(systemName: "backward.end.fill").font(.title2)
                }
                .accessibilityLabel("Previous song")
                Button { music.perform(.togglePlayPause) } label: {
                    Image(systemName: music.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                        .frame(width: 58, height: 58)
                        .background(.orange, in: Circle())
                        .foregroundStyle(.black)
                }
                .accessibilityLabel(music.isPlaying ? "Pause" : "Play")
                Button { music.perform(.next) } label: {
                    Image(systemName: "forward.end.fill").font(.title2)
                }
                .accessibilityLabel("Next song")
                Spacer()
            }
            .buttonStyle(.plain)

            Button {
                showPicker = true
            } label: {
                Label("Choose songs from Music library", systemImage: "music.note.list")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Text(music.feedback)
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("musicFeedback")
        }
    }

    private var shortcutsContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Experimental: all media apps", systemImage: "testtube.2")
                .font(.subheadline.weight(.semibold))

            Text("This mode runs user-created Apple Shortcuts to control the active audio player, potentially including YouTube Music and Spotify.")
                .font(.subheadline)

            Label("Requires ScooterLink in the foreground, with iPhone unlocked. Not suitable for a locked phone in a pocket.", systemImage: "exclamationmark.triangle")
                .font(.caption)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 8) {
                Text("Create three Shortcuts in Apple's Shortcuts app:")
                    .font(.subheadline.weight(.semibold))
                Text("• Play/Pause action → Honda Music Play Pause")
                Text("• Skip Forward action → Honda Music Next")
                Text("• Skip Backward action → Honda Music Previous")
                Text("Test each directly in Shortcuts before connecting the motorcycle. Skip behavior varies between audio players.")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Group {
                TextField("Play/Pause shortcut name", text: $music.playPauseShortcut)
                    .accessibilityLabel("Play Pause Shortcut Name")
                TextField("Next shortcut name", text: $music.nextShortcut)
                    .accessibilityLabel("Next Shortcut Name")
                TextField("Previous shortcut name", text: $music.previousShortcut)
                    .accessibilityLabel("Previous Shortcut Name")
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .textFieldStyle(.roundedBorder)

            HStack(spacing: 18) {
                Button { music.perform(.previous) } label: {
                    Image(systemName: "backward.end.fill")
                }
                .accessibilityLabel("Test previous shortcut")
                Spacer()
                Button { music.perform(.togglePlayPause) } label: {
                    Image(systemName: "playpause.fill")
                }
                .accessibilityLabel("Test play pause shortcut")
                Spacer()
                Button { music.perform(.next) } label: {
                    Image(systemName: "forward.end.fill")
                }
                .accessibilityLabel("Test next shortcut")
            }
            .font(.title2)
            .buttonStyle(.bordered)
            Text(music.feedback)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Link("YouTube Music", destination: URL(string: "https://music.youtube.com/")!)
                Spacer()
                Link("Spotify", destination: URL(string: "https://open.spotify.com/")!)
            }
            .font(.subheadline)
        }
    }
}
