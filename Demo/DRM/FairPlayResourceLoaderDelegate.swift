import Foundation
import AVFoundation

/// Handles FairPlay key requests via AVAssetResourceLoaderDelegate
final class FairPlayResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate {
    private let drmManager: FairPlayDRMManager

    init(drmManager: FairPlayDRMManager) {
        self.drmManager = drmManager
        super.init()
    }

    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        guard let url = loadingRequest.request.url, url.scheme == "skd" else {
            loadingRequest.finishLoading(with: NSError(domain: "FairPlay", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid key URL scheme"]))
            return false
        }

        let contentId: String
        if let override = drmManager.contentIdOverride {
            contentId = override(url)
        } else {
            contentId = Self.extractContentId(from: url)
        }
        let options: [String: Any] = [
            AVAssetResourceLoadingRequestStreamingContentKeyRequestRequiresPersistentKey: true
        ]

        drmManager.makeSPC(loadingRequest: loadingRequest, contentId: contentId, options: options) { [weak loadingRequest, weak self] result in
            guard let loadingRequest = loadingRequest else { return }
            switch result {
            case .failure(let error):
                loadingRequest.finishLoading(with: error)
            case .success(let spc):
                self?.drmManager.requestCKC(spcData: spc, contentId: contentId) { ckcResult in
                    switch ckcResult {
                    case .failure(let error):
                        loadingRequest.finishLoading(with: error)
                    case .success(let ckc):
                        loadingRequest.dataRequest?.respond(with: ckc)
                        loadingRequest.finishLoading()
                    }
                }
            }
        }
        return true
    }

    static func extractContentId(from url: URL) -> String {
        if let host = url.host, !host.isEmpty {
            return host + url.path
        }
        var absolute = url.absoluteString
        if absolute.hasPrefix("skd://") {
            absolute.removeFirst("skd://".count)
        }
        return absolute
    }
}
