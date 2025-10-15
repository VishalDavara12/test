import SwiftUI
import AVKit

struct OfflinePlayerView: View {
    let localURL: URL

    var body: some View {
        VideoPlayer(player: AVPlayer(url: localURL))
            .onAppear {
                // Start playback immediately
            }
            .navigationTitle("Offline Player")
            .navigationBarTitleDisplayMode(.inline)
    }
}
