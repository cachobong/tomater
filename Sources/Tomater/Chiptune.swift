import AppKit

/// Plays short square-wave jingles, rendered as real 8-bit PCM.
enum Chiptune {
    typealias Note = (frequency: Double, seconds: Double)

    /// Rising arpeggio for a finished focus timer.
    static let stageClear: [Note] = [(523.25, 0.08), (659.25, 0.08), (783.99, 0.08), (1046.50, 0.08), (0, 0.04), (1046.50, 0.28)]
    /// Short "ready" call when a break ends.
    static let ready: [Note] = [(783.99, 0.09), (0, 0.05), (783.99, 0.09), (0, 0.05), (1174.66, 0.26)]

    private static var current: NSSound?

    static func play(_ notes: [Note]) {
        guard let sound = NSSound(data: wav(notes)) else { return }
        current = sound
        sound.play()
    }

    private static func wav(_ notes: [Note]) -> Data {
        let rate = 22_050
        var samples = [UInt8]()
        for note in notes {
            let count = Int(note.seconds * Double(rate))
            for i in 0..<count {
                guard note.frequency > 0 else { samples.append(128); continue }
                let phase = Double(i) * note.frequency / Double(rate)
                let high = phase.truncatingRemainder(dividingBy: 1) < 0.5
                let fade = 1 - Double(i) / Double(count) * 0.6
                let amplitude = 40.0 * fade
                samples.append(UInt8(128 + (high ? amplitude : -amplitude)))
            }
        }

        var data = Data()
        func append(_ string: String) { data.append(string.data(using: .ascii)!) }
        func append32(_ value: UInt32) { withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) } }
        func append16(_ value: UInt16) { withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) } }

        append("RIFF"); append32(UInt32(36 + samples.count)); append("WAVE")
        append("fmt "); append32(16); append16(1); append16(1)
        append32(UInt32(rate)); append32(UInt32(rate)); append16(1); append16(8)
        append("data"); append32(UInt32(samples.count))
        data.append(contentsOf: samples)
        return data
    }
}
