# TrafficVisionCompanion — NEW INDEPENDENT PROJECT

This is **not** an update to `TrafficVisionWatch`. Keep the old source/repository unchanged.

## Features

- iPhone: GitHub JSON HTTPS source, refresh, Vietnamese accent-insensitive search, favorites, snapshot viewer, send snapshot to Watch.
- Watch: camera list, search, favorites, JSON reload, snapshot view; synchronization of camera list/favorites/URL via `WatchConnectivity` application context.
- Data is cached separately on each device. JSON can be loaded directly by Watch if internet is available.
- **Not live video**: HLS/M3U8 streams are not automatically converted into JPEG snapshots; a server-side snapshot endpoint is required for stream-only cameras.
- Images are only transferred when both apps are reachable; image transmission is best-effort, not background live mirroring.

## Instructions (Windows + GitHub)

1. Create a **new** GitHub repository `TrafficVisionCompanion`; upload all files in this folder, including `.github/workflows/build.yml`.
2. Actions > `Build TrafficVision Companion` > Run workflow. Build output is an **unsigned Simulator-only** app, **not** an IPA installable on an iPhone.
3. Edit `project.yml` bundle identifiers for both targets: iOS `com.YOURTEAM.trafficvisioncompanion` and watch `com.YOURTEAM.trafficvisioncompanion.watchkitapp`. Match the watch `INFOPLIST_KEY_WKCompanionAppBundleIdentifier` to the iOS bundle ID.
4. Insert HTTPS URL for camera JSON from within the iPhone application or Watch settings; this new repository does not contain your private/previous camera catalog.
5. To make an actual IPA, obtain appropriate signing and provisioning for **both** iOS and watchOS targets, and use a signed `xcodebuild archive` plus `-exportArchive` workflow with an ExportOptions.plist appropriate to the distribution method. This source archive intentionally **does not** claim to produce a signed/installable IPA.
6. Apple Watch companion installation via ESign/iPhone sideload is **not assured**. Official supported routes include Xcode (eligible registered development devices) or TestFlight/App Store Connect with proper developer-team access.

## Security

Do not commit `.p12`, `.mobileprovision`, secrets, UDIDs, or passwords to GitHub. Third-party iPhone certificates/profiles do not guarantee watchOS signing support.

## Compatibility

Deployment targets iOS 17+ / watchOS 10+. Apple Watch SE generation/watchOS version must meet requirement. Actual Xcode compilation needs verification via GitHub Actions (macOS Xcode not available in this environment).

## Data schema

Root can be a JSON array, or an object with `cameras`, `items`, `features` or `data` arrays. Fields supported: id/camId/cameraId; name/location/camLocation; latitude/longitude; imageURL/snapshot/thumbnail; videoURL/stream/m3u8; source/provider/district. Image links must be actual HTTPS still-image URLs. `Sample/cameras.json` is demonstration data only.

## Known limitations

- Updating favorites on two devices simultaneously can lead to last-writer-wins via `updateApplicationContext`.
- Long lists may exceed the 4 MB context serialization threshold; consider lightweight summaries or batching for larger catalogs.
- Reachable image transfer requires app foreground; no automatic continuous refresh from background.
- The `scripts/fix-watch-embed.py` workaround addresses an XcodeGen embedding difference seen with Xcode 26; verify build logs and resulting packaging.
