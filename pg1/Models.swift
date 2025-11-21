import Foundation

struct Track: Identifiable, Codable, Equatable {
    let id: UUID
    let fileName: String
    let localURL: URL
}

struct TrackOrder: Identifiable, Codable, Equatable {
    let id: UUID
    var trackIds: [UUID]
    
    init(newTrackIds: [UUID]) {
        self.id = UUID()
        self.trackIds = newTrackIds
    }
}
