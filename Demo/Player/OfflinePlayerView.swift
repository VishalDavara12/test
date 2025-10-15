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
        let asset = AVURLAsset(url: localURL)
        if let delegate = resourceLoaderDelegate {
            asset.resourceLoader.setDelegate(delegate, queue: .main)
        }
        let item = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: item)
        self.player = player
        player.play()
    }
}
