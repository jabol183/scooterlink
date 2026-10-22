# App Store review checklist — music-only release

## What is implemented

- Honda RoadSync-compatible Bluetooth discovery, RSA/AES key exchange and handlebar notifications retained from the MIT-licensed ScooterLink project.
- Apple Music control and media-library picker through public iOS MediaPlayer APIs.
- Optional user-configured **Shortcuts Beta**, launched via Apple's public x-callback-url, for foreground experimentation with third-party active playback (e.g., YouTube Music and Spotify).
- Music UI, diagnostics, logging and on-screen buttons.
- No navigation, no private MediaRemote, no unsupported background-audio mode, no firmware modification.

## Before submission — required real-device checks

- [ ] Build and install on a physical iPhone, not just the simulator.
- [ ] Confirm Bluetooth permission description and Music permission description appear correctly.
- [ ] Verify Transalp 2023 pairing, RSA/AES authentication, and every handlebar button. **The scan only establishes a UUID match.**
- [ ] Ensure RoadSync re-pairing can be restored if needed.
- [ ] Test Apple Music playback with phone active, with screen locked, after app suspension and reconnection.
- [ ] Manually create, run and test each of the three Shortcuts with YouTube Music and Spotify.
- [ ] Test a Honda button in foreground Shortcuts mode and its x-success return path.
- [ ] Confirm Shortcuts mode refuses to run while phone is locked or app is in background.
- [ ] Check no automatic shortcut launches without selecting Shortcuts mode.
- [ ] Run a Release build and check for private frameworks: no dlopen, dlsym or MediaRemote calls.
- [ ] Supply a real photo/video of the motorcycle and a physical iPhone interacting from pairing to playback, as required for hardware-based apps.
- [ ] Set your own Apple Developer team, provisioning, unique bundle identifier, and App Store support/privacy links.

## App Review notes (suggested)

ScooterLink is an independent Bluetooth music-control companion for compatible Honda motorcycle dashboards. It uses CoreBluetooth to receive handlebar button events. Its Apple Music controls use the publicly documented MediaPlayer system music player. An optional experimental mode launches user-created Apple Shortcuts using Apple's public x-callback-url scheme; the mode explicitly requires the companion app to be open and unlocked and does not directly access other applications' media sessions.

To test without motorcycle hardware, open the Music card and select Apple Music, grant media-library access, then use the on-screen music controls or choose library songs. To test Shortcuts Beta, create the three user Shortcuts named in the app and test the on-screen shortcut buttons. Bluetooth pairing with the hardware is demonstrated in the attached video.

This app does not use Apple private frameworks, navigate, or draw custom TFT content. It has no external server, account requirement, or paid functionality.

## Disclosures

- Music-library authorization: used only to select/play Music library items and display metadata from the Music system player.
- Bluetooth: used to pair/connect to the motorcycle dashboard and receive button events.
- Pairing secret: stored on device in Keychain.
- Preferred music mode and shortcut names: stored locally in UserDefaults.
- No app-collected analytics, ads, or sale of personal data.
- Hardware manufacturer and music-platform trademarks are used descriptively, with no claimed affiliation.

## Known gaps

The Shortcuts workaround has precedent in an App Store app (Scenic) but is **not verified on this branch**. It is expected to switch apps, cannot issue commands from a locked phone, and cannot guarantee YouTube Music's interpretation of Skip. Apple alone determines review approval.

The 2023 Transalp connection is **not yet field-verified**, even though its GATT UUIDs match the upstream PCX. Do not claim production support until a bike and iPhone test succeeds.
