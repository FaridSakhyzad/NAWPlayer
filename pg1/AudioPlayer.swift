import Combine
import AVFoundation

@MainActor
final class AudioPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var onPause: Bool = false

    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var currentURL: URL?

    private var player: AVAudioPlayer?
    private var timer: Timer?

    override init() {
        super.init()

        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true, options: [])
    }

    func load(url: URL) throws {
        stop()
        let p = try AVAudioPlayer(contentsOf: url)
        p.delegate = self
        p.prepareToPlay()

        player = p
        currentURL = url
        duration = p.duration
        currentTime = 0
        isPlaying = false
        onPause = false
    }

    func play() {
        guard let p = player else {
            return
        }
        
        p.play()
        
        isPlaying = true
        
        onPause = false
        
        startTick()
    }

    func pause() {
        player?.pause()

        isPlaying = false

        onPause = true
        
        stopTick()
    }

    func togglePlayPause() {
        isPlaying ? pause() : play()
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        onPause = false
        stopTick()
        duration = 0
        currentTime = 0
        currentURL = nil
    }

    private func startTick() {
        stopTick()

        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            guard let self, let p = self.player else { return }
            self.currentTime = p.currentTime
        }
    }

    private func stopTick() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        stopTick()
        currentTime = duration
    }
}
