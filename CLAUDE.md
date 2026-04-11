# Buds

iOS 26 / Swift 6 (strict concurrency). SwiftData with CloudKit sync (`cloudKitDatabase: .automatic`).

## Build & test locally
- Build and run on simulator: `xcodebuild -scheme Buds -destination 'platform=iOS Simulator,id=B975D309-06E9-4403-85AD-E267618840A5'`
  - iPhone 17 Pro: `B975D309-06E9-4403-85AD-E267618840A5`
  - iPhone 17 Pro Max: `E44E4BB7-B744-48C3-80A4-9ECD0DA07534`
- Use `xcrun simctl launch --console B975D309-06E9-4403-85AD-E267618840A5 io.lou.app` to capture crash logs
- All `@Model` properties must have defaults or be optional (CloudKit requirement)
- All `@Relationship` properties must be optional (CloudKit requirement)

## Git workflow
- Commit and push directly to main
- Every push to main triggers a TestFlight deploy via fastlane (`.github/workflows/testflight.yml`)
- CI uses macos-15 runner with Xcode 26.3
- After pushing, watch the GitHub Actions build (`gh run watch`) and fix issues until it passes

## Xcode project
- New Swift files must be added to `project.pbxproj` (PBXFileReference, PBXBuildFile, PBXGroup, and PBXSourcesBuildPhase) or they won't compile in CI
