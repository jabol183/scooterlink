# ScooterLink — Music-first App Store candidate

Independent iOS companion for Honda motorcycles/scooters with compatible RoadSync Bluetooth dashboards. Tested upstream with **Honda PCX 125 (2025)**. The **XL750 Transalp (2023)** has been scanned and its main BLE service and button characteristic UUIDs matched the upstream PCX protocol. **Full pairing and handlebar actions have not yet been tested on the Transalp**.

**This branch is for an App Store submission candidate, not a claim that Apple has approved it.** It uses Apple's public frameworks and documented Shortcuts URL scheme. Navigation is deliberately out of scope.

## Music features

| Feature | Apple Music | All apps (Shortcuts beta) |
| --- | --- | --- |
| Honda BLE pairing, handlebar button notifications | Yes (on compatible dashboards) | Yes |
| Select / Back → Play/Pause | Uses public `MPMusicPlayerController.systemMusicPlayer` | Runs user's Play/Pause Shortcut |
| Next / Previous | Music app's own queue | Runs user's Skip Forward / Skip Backward Shortcut |
| Track title / artist | From your Music library (with permission) | Not available through public iOS APIs |
| Locked iPhone | BLE may wake app; Music commands need device testing | **No**: app must be foreground and iPhone unlocked |
| Third-party services like YouTube Music and Spotify | No | **Experimental**, depends on Shortcuts/current player |

**Do not claim YouTube Music handlebar control while the phone is locked.** There is no confirmed public-API software-only method. The Shortcuts workaround is a foreground, unlocked-phone experiment.

No Spotify SDK, YouTube unofficial API, private iOS framework, undocumented system command, or audio-session injection is included.

## Honda pairing

1. Park the bike. Enable the compatible RoadSync Bluetooth dashboard.
2. Remove any existing RoadSync phone pairing **if necessary** (this resets the bike's stored phone key).
3. In ScooterLink: Diagnostics → Devices → Scan → choose `HONDA BTU ...`.
4. Grant Bluetooth permissions and let the existing RSA/AES authentication complete. This is still unverified on the 2023 Transalp.
5. Use the home screen to select a music mode. Toggle Apple Music permission if using Apple Music.

Pairing keys are stored locally in the iPhone Keychain. Dashboard drawing and experimental colour changes stay disabled; firmware update services are never written to.

## Apple Music

1. In the home screen Music card choose **Apple Music**.
2. Tap **Enable Apple Music access** and grant media-library permission.
3. Open the Music app to begin playback, or select tracks through **Choose songs from Music library**.
4. Test Play/Pause, Previous, and Next on screen.
5. Once the bike is paired, test Select/Back, Previous, and Next on the handlebar.

Apple Music system player controls the Music app's playback queue; it does **not** control YouTube Music or Spotify.

## Experimental YouTube Music / Spotify using Shortcuts

This is an optional alternative inspired by Scenic Motorcycle Navigation's published Shortcuts method. It uses documented Apple `shortcuts://x-callback-url/run-shortcut` links, not private system media commands.

1. Start music playing manually in YouTube Music / Spotify.
2. In Apple's **Shortcuts** app, create three shortcuts. Name them exactly (or change the names in ScooterLink):
   - `Honda Music Play Pause`: add Shortcuts' **Play/Pause** action (target current iPhone).
   - `Honda Music Next`: add **Skip Forward** action.
   - `Honda Music Previous`: add **Skip Backward** action.
3. **Run each shortcut manually in Shortcuts** and verify it actually affects the music player. If the player doesn't support the chosen skip action, this technique cannot fix it.
4. Open ScooterLink, select **All apps (Beta)**, and confirm the three shortcut names match.
5. With the phone **unlocked** and ScooterLink **foregrounded**, press a handlebar music button or use the test controls on the Music card.
6. Shortcuts should open, run the user shortcut, and return to ScooterLink via an x-callback URL. Device testing is required on your installed iOS version.

**Caveats:** App switching can be visible/slow. iOS may require one-time permissions. Shortcuts may return without controlling playback. The app only knows whether it could launch Shortcuts, not whether a song actually changed. This is **not hands-free operation on a locked iPhone** and should not be used to operate the phone while moving.

References:
- Apple Shortcuts URL scheme: https://support.apple.com/guide/shortcuts/run-a-shortcut-from-a-url-apd624386f42/ios
- Apple Shortcuts x-callback-url: https://support.apple.com/guide/shortcuts/use-x-callback-url-apdcd7f20a6f/ios
- Scenic's approach: https://scenic.app/help/control-music-playback-for-all-media-apps-not-just-apple-music/
- Apple media player: https://developer.apple.com/documentation/mediaplayer/mpmusicplayercontroller/systemmusicplayer

## Building for App Store / TestFlight

Requires macOS, Xcode 16+, and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
cd App
cp Config/Signing.example.xcconfig Config/Signing.xcconfig
# Set your actual DEVELOPMENT_TEAM and unique PRODUCT_BUNDLE_IDENTIFIER
xcodegen generate
xcodebuild -project ScooterLink.xcodeproj -scheme ScooterLink \
  -destination 'generic/platform=iOS' -configuration Release \
  CODE_SIGNING_ALLOWED=NO build
```

For distribution, set your Apple Developer team, a unique bundle identifier and provisioning, create an Archive in Xcode or a signed build from CI, then upload to App Store Connect. Do not submit until hardware interactions and shortcut behavior are tested on a physical iPhone.

The music-card controls allow testing without Honda hardware, but Apple also requires [a physical-device video showing pairing with required hardware](https://developer.apple.com/help/app-review/before-submitting-for-review/complete-review). See [App Store review checklist](docs/APP_STORE_REVIEW.md).

### Tests

```bash
cd App
swiftc Sources/ShortcutURL.swift Tests/Shortcuts/main.swift -o /tmp/scl-shortcuts
/tmp/scl-shortcuts
# Upstream crypto/protocol tests (on macOS):
xcrun swiftc -o /tmp/sl-test Sources/SABCrypto.swift Sources/SABProtocol.swift Sources/DashScreen.swift Tests/main.swift
/tmp/sl-test
```

## Scope / safety

- No navigation or location access.
- No analytics, servers, third-party SDKs, subscriptions or ads.
- Does not read tracks from YouTube Music or Spotify.
- No custom TFT drawing. No firmware writes.
- Bluetooth GATT and Keychain access only for connecting to the motorcycle.
- The Shortcuts bridge is an opt-in experimental feature requiring user-created shortcuts.
- Never manipulate phone controls while riding.

## Legal

This project is independent of Honda, Apple, Google, Spotify and Scenic, and is not endorsed or affiliated with them. Third-party names identify compatibility only. Original ScooterLink code remains under the MIT license; retain all upstream copyright notices. See [LICENSE](LICENSE).
