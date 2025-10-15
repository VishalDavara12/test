import Foundation

struct OfflineAsset: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let playlistURL: URL
    let localAssetPath: URL?
    let mediaSelectionDisplayName: String?
    let isDRMProtected: Bool
    let createdAt: Date
    let lastUpdatedAt: Date

    init(id: UUID = UUID(),
         name: String,
         playlistURL: URL,
         localAssetPath: URL? = nil,
         mediaSelectionDisplayName: String? = nil,
         isDRMProtected: Bool,
         createdAt: Date = Date(),
         lastUpdatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.playlistURL = playlistURL
        self.localAssetPath = localAssetPath
        self.mediaSelectionDisplayName = mediaSelectionDisplayName
        self.isDRMProtected = isDRMProtected
        self.createdAt = createdAt
        self.lastUpdatedAt = lastUpdatedAt
    }
}
