import SwiftUI
import AVKit

struct OfflinePlayerView: View {
    let localURL: URL
    var resourceLoaderDelegate: AVAssetResourceLoaderDelegate? = nil
    @State private var player: AVPlayer? = nil

    var body: some View {
        VideoPlayer(player: player)
            .onAppear { configureAndPlay() }
            .onDisappear { player?.pause() }
            .navigationTitle("Offline Player")
            .navigationBarTitleDisplayMode(.inline)
    }

    private func configureAndPlay() {
        // Use a URLAsset with HTTP header passthrough disabled; offline should read from file URL
        let asset = AVURLAsset(url: localURL)
        if let delegate = resourceLoaderDelegate {
            asset.resourceLoader.setDelegate(delegate, queue: .main)
        }
        // Ensure automaticallyWaitsToMinimizeStalling off for offline
        let item = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: item)
        player.automaticallyWaitsToMinimizeStalling = false
        self.player = player
        player.play()
    }
}
