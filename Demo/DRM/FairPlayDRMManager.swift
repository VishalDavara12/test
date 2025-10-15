import Foundation
import AVFoundation

/// Minimal FairPlay manager for license requests and persistent keys
final class FairPlayDRMManager: NSObject {
    enum DRMError: Error {
        case certificateMissing
        case spcGenerationFailed
        case licenseFailed
        case noContentId
        case badResponse
        case unknown
    }

    // Configure these for your license server integration
    var certificateURL: URL?
    var licenseServerURL: URL?

    private var appCertificate: Data?
    var contentIdOverride: ((URL) -> String)?

    func configure(certificateURL: URL, licenseServerURL: URL) {
        self.certificateURL = certificateURL
        self.licenseServerURL = licenseServerURL
    }

    func loadCertificateIfNeeded(completion: @escaping (Result<Data, Error>) -> Void) {
        if let appCertificate = appCertificate {
            completion(.success(appCertificate))
            return
        }
        guard let certificateURL else {
            completion(.failure(DRMError.certificateMissing))
            return
        }
        let task = URLSession.shared.dataTask(with: certificateURL) { [weak self] data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data, !data.isEmpty else {
                completion(.failure(DRMError.certificateMissing))
                return
            }
            self?.appCertificate = data
            completion(.success(data))
        }
        task.resume()
    }

    // MARK: - SPC / CKC

    /// Generate SPC using the loadingRequest helper (preferred inside resource loader delegate)
    func makeSPC(loadingRequest: AVAssetResourceLoadingRequest,
                 contentId: String,
                 options: [String: Any]? = nil,
                 completion: @escaping (Result<Data, Error>) -> Void) {
        loadCertificateIfNeeded { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let certificateData):
                do {
                    let spc = try loadingRequest.streamingContentKeyRequestData(
                        forApp: certificateData,
                        contentIdentifier: Data(contentId.utf8),
                        options: options
                    )
                    completion(.success(spc))
                } catch {
                    completion(.failure(DRMError.spcGenerationFailed))
                }
            }
        }
    }

    func requestCKC(spcData: Data, contentId: String, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let licenseServerURL = licenseServerURL else {
            completion(.failure(DRMError.licenseFailed))
            return
        }
        var request = URLRequest(url: licenseServerURL)
        request.httpMethod = "POST"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        // Many DRM servers require using base64 spc or adding headers. Customize here if needed.
        request.httpBody = spcData

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode), let data = data else {
                completion(.failure(DRMError.badResponse))
                return
            }
            completion(.success(data))
        }
        task.resume()
    }
}
