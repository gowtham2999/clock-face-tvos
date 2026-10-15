import AVFoundation

/// Plays a short synthesized click once per second. "Watch" is a sharp mechanical
/// tick; "System" is a softer, lower blip. Both are generated in code, so no audio
/// assets are needed until real recordings replace them.
final class TickSoundPlayer {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format: AVAudioFormat
    private var buffers: [ChimeSource: AVAudioPCMBuffer] = [:]

    init() {
        let sampleRate = 44_100.0
        format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        buffers[.watch] = Self.makeClick(format: format, frequency: 3_200, duration: 0.025, decay: 220, noise: 0.35)
        buffers[.system] = Self.makeClick(format: format, frequency: 1_100, duration: 0.06, decay: 70, noise: 0)

        try? AVAudioSession.sharedInstance().setCategory(.ambient)
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
    }

    func tick(source: ChimeSource, volume: Double) {
        guard let buffer = buffers[source] else { return }
        play(buffer, volume: volume)
    }

    /// A rising three-note chime for reminders.
    func chime(volume: Double) {
        play(Self.makeChime(format: format), volume: volume)
    }

    private func play(_ buffer: AVAudioPCMBuffer, volume: Double) {
        if !engine.isRunning {
            do { try engine.start() } catch { return }
        }
        player.volume = Float(volume)
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !player.isPlaying { player.play() }
    }

    private static func makeChime(format: AVAudioFormat) -> AVAudioPCMBuffer {
        let notes: [(frequency: Double, start: Double)] = [(880, 0), (1108.73, 0.18), (1318.51, 0.36)]
        let frameCount = AVAudioFrameCount(format.sampleRate * 1.4)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let samples = buffer.floatChannelData![0]
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / format.sampleRate
            var value = 0.0
            for note in notes where t >= note.start {
                let local = t - note.start
                value += sin(2 * .pi * note.frequency * local) * exp(-local * 4) * 0.28
            }
            samples[frame] = Float(value)
        }
        return buffer
    }

    private static func makeClick(
        format: AVAudioFormat,
        frequency: Double,
        duration: Double,
        decay: Double,
        noise: Float
    ) -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(format.sampleRate * duration)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let samples = buffer.floatChannelData![0]
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / format.sampleRate
            let envelope = Float(exp(-t * decay))
            let tone = Float(sin(2 * .pi * frequency * t))
            let grit = noise * Float.random(in: -1...1)
            samples[frame] = (tone * (1 - noise) + grit) * envelope * 0.8
        }
        return buffer
    }
}
