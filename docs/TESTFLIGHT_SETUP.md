# ScooterLink: signed TestFlight builds without a Mac

Workflow: [`.github/workflows/testflight.yml`](../.github/workflows/testflight.yml)

The workflow runs **manually**, on `main` only. It builds the Swift iPhone app with Xcode 26 on GitHub's macOS runner, signs the app, exports an IPA, and uploads to App Store Connect TestFlight. It does **not** publicly release the app to the App Store.

## 1. Set up the Apple app

- Apple Developer account must be active, and agreements requiring acceptance must be completed.
- Bundle identifier **`com.jabol183.scooterlink`** must be registered under [Apple Developer > Certificates, IDs & Profiles](https://developer.apple.com/account/resources/identifiers/list). If you already registered a different identifier, update `BUNDLE_ID`, `PROFILE_NAME`, `PRODUCT_BUNDLE_IDENTIFIER`, and the profile to match it before running.
- Create an app record named ScooterLink (or an original product name) at [App Store Connect > Apps](https://appstoreconnect.apple.com/apps) using this exact bundle identifier. Apple's new-app wizard also asks for a SKU you choose.

## 2. Create a **team** App Store Connect API key

Visit [App Store Connect > Users and Access > Integrations > App Store Connect API](https://appstoreconnect.apple.com/access/integrations/api). If your account does not show the API page, your Account Holder may first have to request access.

Create a **Team Key** with **App Manager** access (or an appropriately authorized higher role). **Do not use an Individual API Key**: Apple doesn't permit individual keys to access provisioning endpoints used by this workflow.

Record its *Issuer ID*, *Key ID* and download `AuthKey_<KEY_ID>.p8` **once**. Keep the private key out of chat and Git; store its *entire text including BEGIN/END PRIVATE KEY lines* as a GitHub Actions secret. Also obtain your 10-character [Apple Developer Team ID](https://developer.apple.com/account) (Membership details).

## 3. Create signing certificate + profile, including from Windows

You need an **Apple Distribution** signing identity containing its private key (in password-protected `.p12` form) and an **iOS App Store** provisioning profile named exactly:

`AppStore com.jabol183.scooterlink`

Use existing valid signing materials, or generate them without owning a Mac using the [Apple-Actions provisioning profile setup scripts](https://github.com/Apple-Actions/download-provisioning-profiles). These scripts use `curl`, `openssl`, `jq`, `python3`, and GitHub CLI `gh`, and can run in **WSL/Ubuntu on Windows**. You will need to sign in to GitHub CLI using `gh auth login`.

Example on WSL, after placing the one-time Apple `.p8` key safely on your local machine:

```bash
sudo apt-get update
sudo apt-get install -y git curl jq openssl python3
# Install and sign in to the GitHub CLI: https://cli.github.com/
gh auth login
git clone https://github.com/Apple-Actions/download-provisioning-profiles.git
cd download-provisioning-profiles
./scripts/setup.sh \
  --bundle-id com.jabol183.scooterlink \
  --name 'ScooterLink' \
  --issuer-id 'YOUR_ISSUER_UUID' \
  --api-key-id 'YOUR_KEY_ID' \
  --api-private-key-path '/path/to/your/AuthKey_KEY_ID.p8' \
  --p12-password 'YOUR_NEW_STRONG_P12_PASSWORD' \
  --github-repo jabol183/scooterlink \
  --export-options ./ScooterLink-ExportOptions.plist
```

**This command is an example, not an unattended step in the TestFlight workflow.** It operates on your Apple and GitHub accounts, can create a certificate and profile, and uploads signing credentials as GitHub secrets. Verify the exact setup-script options and its GitHub security permissions before executing. Store the generated P12 securely. Never paste Apple keys or signing certificates into an issue/PR/chat.

Alternatively: create the signing certificate and profile in the Apple Developer portal, securely export the certificate *with private key* as `.p12`, base64-encode the `.p12` bytes, and add the resulting text to a GitHub secret.

## 4. GitHub Actions repository configuration

Open [ScooterLink repository Actions Secrets/Variables](https://github.com/jabol183/scooterlink/settings/secrets/actions).

| Type | Exact name | Value |
| --- | --- | --- |
| Variable | `APPLE_TEAM_ID` | 10-character Developer Team ID |
| Variable | `APPSTORE_ISSUER_ID` | Team API Issuer ID |
| Variable | `APPSTORE_API_KEY_ID` | Team API Key ID |
| Secret | `APPSTORE_API_PRIVATE_KEY` | Complete downloaded `.p8` file contents |
| Secret | `APPSTORE_CERTIFICATES_FILE_BASE64` | Base64-encoded distribution `.p12` bytes |
| Secret | `APPSTORE_CERTIFICATES_PASSWORD` | Password for the `.p12` |

The Apple-Actions setup script populates the canonical `APPSTORE_*` credentials when configured with `--github-repo`. **Add `APPLE_TEAM_ID` separately** in the Variables tab. If using manual setup, add all six entries yourself.

The profile is retrieved automatically using the team API key on each run. It must be **active** and have the exact name specified above; otherwise the workflow stops before building.

## 5. Trigger build and install on iPhone

1. Once the workflow is merged into `main`, open [Actions](https://github.com/jabol183/scooterlink/actions/workflows/testflight.yml).
2. Select **Build and upload ScooterLink to TestFlight** → **Run workflow** → **Branch: main**.
3. Look for **Upload signed IPA to TestFlight** in the successful run. It means the binary was submitted, not necessarily processed.
4. Apple will process the upload; open [App Store Connect](https://appstoreconnect.apple.com/apps) → ScooterLink → **TestFlight**. Finish any required export-compliance information (ScooterLink uses RSA/AES for Honda pairing; do not assume an exemption without checking Apple's questions).
5. Add your Apple Account as an **internal tester** (App Store Connect user with access), create an internal group, and assign the build. Optionally enable automatic distribution of future uploads to this group.
6. Install [Apple's TestFlight app](https://apps.apple.com/app/testflight/id899247664) on your iPhone, accept the invitation and tap **Install**.

Internal TestFlight builds do not require a public App Store release. The TestFlight build expires after 90 days.

## 6. Common failures and what they mean

- **Missing XYZ**: a variable/secret was not configured; the preflight check names it.
- **No active profile**: profile named `AppStore com.jabol183.scooterlink` wasn't created, expired, or used an incompatible certificate.
- **No signing identity**: the P12 password or base64 content is incorrect, or the file lacks the private key.
- **Profile/team mismatch**: `APPLE_TEAM_ID`, bundle ID, provisioning profile and distribution certificate must belong to the same Apple team.
- **App not found / upload rejected**: create the App Store Connect record, check Apple agreements, verify key role.
- **Build failed**: the code or Xcode project has an actual compile/signing issue; inspect the run's Xcode archive log. This workflow has not yet been executed on a macOS runner.

Each workflow execution uses a new `GITHUB_RUN_NUMBER` as `CURRENT_PROJECT_VERSION` so successive successful uploads have increasing build numbers. The marketing version remains 1.2 until changed in `App/project.yml`.

No IPA is saved as a public GitHub Actions artifact. Signed binary is uploaded directly to Apple. Builds are deliberately manual to control costs and avoid automatic uploads on every commit.

This setup does **not** imply that Apple's App Review has approved the app, or that 2023 Transalp music controls have already been verified on the motorcycle.
