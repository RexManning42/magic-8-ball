// Generates the app's sound effects: the slosh is cut from a recording, the gong is synthesized.
// Usage: swift tools/make_sounds.swift tools/source/water-sloshing.mp3 EightBall/Sounds

import AVFoundation
import Foundation

let sampleRate = 44100.0

var rng = SystemRandomNumberGenerator()
func noise() -> Double { Double.random(in: -1...1, using: &rng) }

/// Chamberlin state-variable filter.
struct SVF {
    var low = 0.0, band = 0.0
    mutating func step(_ input: Double, cutoff: Double, q: Double) -> (low: Double, band: Double, high: Double) {
        let f = 2 * sin(.pi * min(cutoff, sampleRate / 6) / sampleRate)
        low += f * band
        let high = input - low - band / q
        band += f * high
        return (low, band, high)
    }
}

func normalize(_ samples: [Double], peak: Double) -> [Double] {
    let maxValue = samples.map { abs($0) }.max() ?? 1
    return samples.map { $0 / max(maxValue, 1e-9) * peak }
}

func writeWAV(_ samples: [Double], sampleRate: Double = sampleRate, to path: String) {
    var data = Data()
    func append<T: FixedWidthInteger>(_ value: T) {
        withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
    }
    let byteCount = UInt32(samples.count * 2)
    data.append(contentsOf: Array("RIFF".utf8)); append(36 + byteCount)
    data.append(contentsOf: Array("WAVEfmt ".utf8)); append(UInt32(16))
    append(UInt16(1)); append(UInt16(1))                      // PCM, mono
    append(UInt32(sampleRate)); append(UInt32(sampleRate) * 2) // sample rate, byte rate
    append(UInt16(2)); append(UInt16(16))                      // block align, bits
    data.append(contentsOf: Array("data".utf8)); append(byteCount)
    for s in samples { append(Int16(max(-1, min(1, s)) * 32767)) }
    try! data.write(to: URL(fileURLWithPath: path))
}

// MARK: - Slosh: the liveliest stretch of a water recording

func makeSlosh(from path: String) -> (samples: [Double], sampleRate: Double) {
    let start = 0.3, length = 1.3, fadeIn = 0.02, fadeOut = 0.25

    let file = try! AVAudioFile(forReading: URL(fileURLWithPath: path))
    let format = file.processingFormat
    let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(file.length))!
    try! file.read(into: buffer)

    let rate = format.sampleRate
    let channels = Int(format.channelCount)
    let first = Int(start * rate)
    let count = min(Int(length * rate), Int(buffer.frameLength) - first)
    var out = [Double](repeating: 0, count: count)
    for i in 0..<count {
        for channel in 0..<channels {
            out[i] += Double(buffer.floatChannelData![channel][first + i]) / Double(channels)
        }
        let t = Double(i) / rate
        let remaining = Double(count - i) / rate
        out[i] *= min(1, t / fadeIn) * min(1, remaining / fadeOut)
    }
    return (normalize(out, peak: 0.85), rate)
}

// MARK: - Gong: large, low, far away

func reverb(_ input: [Double], wet: Double) -> [Double] {
    let combs: [(delay: Int, feedback: Double)] = [(1557, 0.87), (1617, 0.86), (1491, 0.88), (1422, 0.87), (1277, 0.85)]
    var mix = [Double](repeating: 0, count: input.count)
    for comb in combs {
        var buffer = [Double](repeating: 0, count: comb.delay)
        var damp = 0.0
        for i in 0..<input.count {
            let delayed = buffer[i % comb.delay]
            damp = delayed * 0.6 + damp * 0.4
            buffer[i % comb.delay] = input[i] + damp * comb.feedback
            mix[i] += delayed / Double(combs.count)
        }
    }
    for (delay, g) in [(556, 0.5), (225, 0.5)] {
        var buffer = [Double](repeating: 0, count: delay)
        for i in 0..<mix.count {
            let delayed = buffer[i % delay]
            let value = mix[i] + delayed * g
            buffer[i % delay] = value
            mix[i] = delayed - value * g
        }
    }
    return zip(input, mix).map { $0 * (1 - wet) + $1 * wet }
}

func makeGong() -> [Double] {
    let duration = 3.5
    let count = Int(duration * sampleRate)
    var out = [Double](repeating: 0, count: count)

    let fundamental = 58.0
    let ratios = [1.0, 1.48, 2.0, 2.41, 2.93, 3.56, 4.23, 5.41, 6.79]
    for (index, ratio) in ratios.enumerated() {
        let n = Double(index)
        let gain = 1 / pow(n + 1, 0.85)
        let decay = 2.1 / (1 + 0.4 * n)
        let attack = 0.012 + 0.05 * n          // upper partials bloom late, like a tam-tam
        let beat = Double.random(in: 0.25...0.9, using: &rng)
        let phaseA = Double.random(in: 0...(2 * .pi), using: &rng)
        let phaseB = Double.random(in: 0...(2 * .pi), using: &rng)
        let freq = fundamental * ratio
        for i in 0..<count {
            let t = Double(i) / sampleRate
            let env = (1 - exp(-t / attack)) * exp(-t / decay)
            out[i] += gain * env * 0.5 * (sin(2 * .pi * (freq - beat / 2) * t + phaseA)
                                        + sin(2 * .pi * (freq + beat / 2) * t + phaseB))
        }
    }

    // Soft mallet thump.
    var thump = SVF()
    for i in 0..<Int(0.12 * sampleRate) {
        let t = Double(i) / sampleRate
        out[i] += thump.step(noise(), cutoff: 140, q: 0.8).low * exp(-t / 0.03) * 0.6
    }

    // Distance: roll off the highs, then drown it in reverb.
    var lowpass = 0.0
    let alpha = 1 - exp(-2 * .pi * 1500 / sampleRate)
    for i in 0..<count {
        lowpass += alpha * (out[i] - lowpass)
        out[i] = lowpass
    }
    out = reverb(out, wet: 0.6)

    for i in 0..<count {
        let remaining = Double(count - i) / sampleRate
        if remaining < 1.0 { out[i] *= remaining / 1.0 }
    }
    return normalize(out, peak: 0.8)
}

guard CommandLine.arguments.count == 3 else {
    print("Usage: swift tools/make_sounds.swift <slosh recording> <output directory>")
    exit(1)
}
let recording = CommandLine.arguments[1]
let directory = CommandLine.arguments[2]
try! FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
let slosh = makeSlosh(from: recording)
writeWAV(slosh.samples, sampleRate: slosh.sampleRate, to: "\(directory)/slosh.wav")
writeWAV(makeGong(), to: "\(directory)/gong.wav")
print("Wrote slosh.wav and gong.wav to \(directory)")
