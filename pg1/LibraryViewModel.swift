import Combine
import Foundation

@MainActor
final class LibraryVM: ObservableObject {
    @Published var tracks: [Track] = []
    
    @Published var selected: Track?
    
    @Published var order: TrackOrder?

    func select(_ track: Track) {
        selected = track
    }

    func clearSelection() {
        selected = nil
    }

    // Простой сканер папки Documents/Audio -> наполняет tracks
    func scanAudioFolder() {
        let fm = FileManager.default
        let folder = AppDirs.audioDir  // см. вспом. утилиту ниже

        guard let items = try? fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else {
            return
        }

        // допустимые расширения
        let allowed = Set(["mp3", "m4a", "aac", "wav", "aiff", "aif"])

        var result: [Track] = []

        for url in items {
            let ext = url.pathExtension.lowercased()

            guard allowed.contains(ext) else { continue }

            result.append(Track(id: UUID(), fileName: url.lastPathComponent, localURL: url))
        }

        // простая сортировка по имени файла
        result.sort { $0.fileName.localizedCaseInsensitiveCompare($1.fileName) == .orderedAscending }
        self.tracks = result

        let trackIds: [UUID] = result.map({ track in
            return track.id
        })
        
        self.order = TrackOrder(newTrackIds: trackIds)
        
        // Если выбранный трек больше не существует — снимем выделение
        if let sel = selected, !result.contains(sel) {
            selected = nil
        }
    }
}

enum AppDirs {
    static var audioDir: URL {
        let fm = FileManager.default

        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!

        let folder = docs.appendingPathComponent("Audio", isDirectory: true)

        if !fm.fileExists(atPath: folder.path) {
            try? fm.createDirectory(at: folder, withIntermediateDirectories: true)
        }

        return folder
    }
}

