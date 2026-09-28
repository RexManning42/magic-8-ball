import AVFoundation

@MainActor
final class SoundPlayer {
    private let slosh = SoundPlayer.load("slosh", volume: 0.9)
    private let gong = SoundPlayer.load("gong", volume: 0.55)

    init() {
        // .ambient respects the silent switch and mixes with other audio.
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
    }

    func playSlosh() { play(slosh) }
    func playGong() { play(gong) }

    private func play(_ player: AVAudioPlayer?) {
        player?.currentTime = 0
        player?.play()
    }

    private static func load(_ name: String, volume: Float) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav"),
              let player = try? AVAudioPlayer(contentsOf: url) else { return nil }
        player.volume = volume
        player.prepareToPlay()
        return player
    }
}
