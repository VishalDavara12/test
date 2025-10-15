import Foundation
import AVFoundation

/// Handles HLS offline downloading using AVAssetDownloadURLSession
final class OfflineDownloadManager: NSObject, ObservableObject {
    struct DownloadTaskInfo: Identifiable {
        let id: UUID
        let task: AVAssetDownloadTask
        let urlAsset: AVURLAsset
        var progress: Double
        var title: String
        var localURL: URL?
    }

    @Published private(set) var downloads: [UUID: DownloadTaskInfo] = [:]
    private var fairPlayManager: FairPlayDRMManager?
    private var fairPlayDelegate: FairPlayResourceLoaderDelegate?

    var fairPlayResourceLoaderDelegate: FairPlayResourceLoaderDelegate? { fairPlayDelegate }

    private lazy var configuration: URLSessionConfiguration = {
        let config = URLSessionConfiguration.background(withIdentifier: "com.demo.hls.offline")
        config.allowsCellularAccess = true
        return config
    }()

    private lazy var downloadSession: AVAssetDownloadURLSession = {
        return AVAssetDownloadURLSession(configuration: configuration,
                                         assetDownloadDelegate: self,
                                         delegateQueue: OperationQueue.main)
    }()

    func startDownload(hlsURL: URL,
                       title: String,
                       assetTitle: String? = nil,
                       muteAudio: Bool = false,
                       preferredAudioLocale: Locale? = nil) {
        let urlAsset = AVURLAsset(url: hlsURL)
        if let fairPlayDelegate = fairPlayDelegate {
            urlAsset.resourceLoader.setDelegate(fairPlayDelegate, queue: DispatchQueue.main)
        }

        // Load media selection groups before creating the download task
        urlAsset.loadValuesAsynchronously(forKeys: ["availableMediaCharacteristicsWithMediaSelectionOptions"]) { [weak self] in
            guard let self = self else { return }

            var downloadOptions: [String: Any] = [
                AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: 265_000 // ~240p for small size
            ]

            if let audioGroup = urlAsset.mediaSelectionGroup(forMediaCharacteristic: .audible) {
                let mediaSelection = urlAsset.preferredMediaSelection.mutableCopy() as! AVMutableMediaSelection
                if muteAudio {
                    mediaSelection.select(nil, in: audioGroup)
                } else if let locale = preferredAudioLocale {
                    let localeOptions = AVMediaSelectionGroup.mediaSelectionOptions(from: audioGroup.options, with: locale)
                    if let first = localeOptions.first {
                        mediaSelection.select(first, in: audioGroup)
                    }
                }
                downloadOptions[AVAssetDownloadTaskMediaSelectionKey] = mediaSelection.copy() as! AVMediaSelection
            }

            let task = self.downloadSession.makeAssetDownloadTask(asset: urlAsset,
                                                                  assetTitle: assetTitle ?? title,
                                                                  assetArtworkData: nil,
                                                                  options: downloadOptions)
            guard let task else { return }
            let id = UUID()
            let info = DownloadTaskInfo(id: id, task: task, urlAsset: urlAsset, progress: 0, title: title, localURL: nil)
            DispatchQueue.main.async {
                self.downloads[id] = info
                task.resume()
            }
        }
    }

    func configureFairPlay(certificateURL: URL, licenseURL: URL) {
        let manager = FairPlayDRMManager()
        manager.configure(certificateURL: certificateURL, licenseServerURL: licenseURL)
        self.fairPlayManager = manager
        self.fairPlayDelegate = FairPlayResourceLoaderDelegate(drmManager: manager)
    }

    func localURL(for taskIdentifier: Int) -> URL? {
        // AVAssetDownloadTask provides location in delegate callback
        return nil
    }
}

extension OfflineDownloadManager: AVAssetDownloadDelegate {
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask,
                    didFinishDownloadingTo location: URL) {
        if let id = downloads.first(where: { $1.task == assetDownloadTask })?.key {
            var info = downloads[id]!
            info.progress = 1.0
            info.localURL = location
            downloads[id] = info
        }
    }

    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask,
                    didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange) {
        let loaded = loadedTimeRanges
            .map { $0.timeRangeValue }
            .reduce(0.0) { partial, range in
                let seconds = CMTimeGetSeconds(range.duration)
                return partial + seconds
            }
        let expected = CMTimeGetSeconds(timeRangeExpectedToLoad.duration)
        let progress = expected > 0 ? min(max(loaded / expected, 0), 1) : 0

        if let id = downloads.first(where: { $1.task == assetDownloadTask })?.key {
            var info = downloads[id]!
            info.progress = progress
            downloads[id] = info
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("Download error: \(error)")
        }
    }
}
