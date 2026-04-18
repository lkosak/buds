# Apple Signing Setup

This repo uses **Fastlane Match** to manage certificates and provisioning profiles across all apps.
All certs and profiles live in a single encrypted private repo (`lkosak/certificates`), so
adding a new app is one command and cert renewal benefits every app automatically.

## Architecture

```
github.com/lkosak/certificates  ← private, encrypted by Match
  └── holds all .p12 certs and .mobileprovision files for all apps

github.com/lkosak/buds          ← this repo
github.com/lkosak/newapp        ← future apps
  └── each points at the certificates repo via fastlane/Matchfile
  └── each uses the same 6 GitHub secrets (see below)
```

## GitHub Secrets

Set these in each app repo under Settings → Secrets and variables → Actions.
They are identical across all repos — you set them once per repo and never touch them again
unless you rotate the API key or Match password.

| Secret | What it is |
|---|---|
| `APP_STORE_CONNECT_KEY_ID` | Key ID from App Store Connect → Integrations → API |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID from the same page |
| `APP_STORE_CONNECT_API_KEY` | Full text of the .p8 file |
| `DEVELOPMENT_TEAM` | Your 10-character Apple Team ID from developer.apple.com/account |
| `MATCH_PASSWORD` | Passphrase Match uses to encrypt/decrypt the certificates repo |
| `MATCH_GIT_BASIC_AUTHORIZATION` | base64 of `username:ghp_token` — lets CI clone the certificates repo |

**Remove** these old secrets if they exist: `BUILD_CERTIFICATE_BASE64`, `P12_PASSWORD`,
`BUILD_PROVISION_PROFILE_BASE64`

## One-Time Setup (run locally, not in CI)

### 1. App Store Connect API key

1. Go to appstoreconnect.apple.com → Users and Access → Integrations → App Store Connect API
2. Create a key with "App Manager" role, download the .p8 file
3. Note the Key ID and Issuer ID on that page
4. Set `APP_STORE_CONNECT_API_KEY` = the full text of the .p8 file

### 2. Create the certificates repo

Create a new **empty private** GitHub repo named `lkosak/certificates`. No README, no files.

### 3. Initialize Match

From this repo directory:

```bash
bundle exec fastlane match init
# When prompted:
#   storage_mode: git
#   URL: https://github.com/lkosak/certificates
```

This creates `fastlane/Matchfile`.

### 4. Create certs and provisioning profile for this app

```bash
bundle exec fastlane match appstore --app_identifier io.lou.app
```

Match will:
- Create a new Apple Distribution certificate (if needed)
- Create an App Store provisioning profile for the bundle ID
- Encrypt everything and push to `lkosak/certificates`

For each future app, run this with its bundle ID.

### 5. Generate a GitHub PAT for CI

Create a GitHub Personal Access Token with `repo` scope so CI can clone the certificates repo:

1. GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens
2. Resource owner: lkosak, Repository access: Only select repositories → `lkosak/certificates`
3. Permissions: Contents = Read-only
4. Generate and copy the token, then base64-encode it:

```bash
echo -n "lkosak:ghp_yourtoken" | base64
```

Store the result as `MATCH_GIT_BASIC_AUTHORIZATION`.

### 6. Update GitHub secrets for this repo

Add: `MATCH_PASSWORD`, `MATCH_GIT_BASIC_AUTHORIZATION`
Remove: `BUILD_CERTIFICATE_BASE64`, `P12_PASSWORD`, `BUILD_PROVISION_PROFILE_BASE64`

## Adding a New App

```bash
# 1. Create the app record in App Store Connect first, then:
bundle exec fastlane match appstore --app_identifier com.you.newapp

# 2. In the new app's repo, copy fastlane/Matchfile and update app_identifier
# 3. Add the same 6 secrets to the new repo's GitHub settings
# 4. Done — CI works on first push
```

## Renewing / Replacing Certificates

When a cert expires or you want to start fresh:

```bash
# Revoke the old cert and create a new one (updates the certificates repo automatically)
bundle exec fastlane match nuke distribution
bundle exec fastlane match appstore --app_identifier io.lou.app
# Repeat the last line for each other app if needed
```

No secrets need to be updated — CI pulls from the certificates repo automatically.

## Apple Developer Account Cleanup

After Match is set up and CI is passing, you can safely clean up old manual artifacts.
Match names everything with a `match AppStore io.lou.app` prefix, so anything outside
that naming scheme is old/manual and can be removed.

### Certificates (developer.apple.com → Certificates)

**Remove:** Any Apple Distribution certificates that don't start with `match AppStore`
in their name. These are the old manually-exported ones. Revoking them here also
invalidates any provisioning profiles that relied on them, but those are being replaced anyway.

**Keep:** Certificates created by Match (they'll show up after you run `match appstore`).

### Provisioning Profiles (developer.apple.com → Profiles)

**Remove:** Any App Store profiles that don't start with `match AppStore`. These are
old manually-created profiles.

**Keep:** Profiles created by Match.

### App Store Connect API Keys (appstoreconnect.apple.com → Integrations → API)

**Remove:** Any old API keys you created for other tools or previous workflows, if
they're no longer in use. Keep the one you created in step 1 above.

### Development Certificates

If you have duplicate or expired development certificates, those can also be revoked.
Match can manage development certs too if you ever need to add team members — just run
`bundle exec fastlane match development` to set that up.
