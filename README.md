# Demo: Offline DRM HLS (SwiftUI)

This sample shows how to download a small HLS VOD (with optional FairPlay DRM) for offline playback using SwiftUI and AVFoundation.

## Features
- SwiftUI-only UI (no UIKit)
- Offline HLS download via `AVAssetDownloadURLSession`
- Optional FairPlay DRM with persistent keys using `AVAssetResourceLoader`
- Simple `VideoPlayer` playback from the downloaded local URL

## Setup
1. Open `Demo.xcodeproj` in Xcode 15+
2. In `Demo/ContentView.swift`, provide an HLS URL. For DRM-protected HLS, also provide Certificate and License URLs.
3. If using FairPlay, you must supply a valid certificate and license server that matches the stream.

> Note: The sample enables ATS exceptions in `Info.plist` (`NSAllowsArbitraryLoads`) for convenience. For production, configure ATS properly.

## How to use
- Build & run the app on a device or simulator.
- Enter an HLS `.m3u8` URL.
- Toggle FairPlay and enter certificate & license URLs if needed.
- Tap Download. Progress appears under Downloads.
- When finished, tap Play to view the offline asset.

## Files of interest
- `Demo/ContentView.swift` – SwiftUI UI for input and control
- `Demo/Download/OfflineDownloadManager.swift` – HLS background download and progress
- `Demo/DRM/FairPlayDRMManager.swift` – Certificate loading, SPC generation, and license request
- `Demo/DRM/FairPlayResourceLoaderDelegate.swift` – Resource loader delegate for key requests
- `Demo/Player/OfflinePlayerView.swift` – Simple `VideoPlayer` wrapper

## Limitations
- You need access to compatible DRM streams and servers to test DRM.
- The sample stores local URL in-memory only; persist as needed.
- Error handling is minimal and for demonstration only.
