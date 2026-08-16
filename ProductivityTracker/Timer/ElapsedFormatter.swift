import Foundation

enum ElapsedFormatter {
    static func stopwatch(_ interval: TimeInterval) -> String {
        let clamped = max(0, interval)
        let totalCentiseconds = Int((clamped * 100).rounded(.towardZero))
        let hours = totalCentiseconds / 360_000
        let minutes = (totalCentiseconds % 360_000) / 6_000
        let seconds = (totalCentiseconds % 6_000) / 100
        let centiseconds = totalCentiseconds % 100
        if hours > 0 {
            return String(format: "%d:%02d:%02d.%02d", hours, minutes, seconds, centiseconds)
        }
        return String(format: "%02d:%02d.%02d", minutes, seconds, centiseconds)
    }

    static func compact(_ interval: TimeInterval) -> String {
        let clamped = max(0, interval)
        let totalSeconds = Int(clamped.rounded(.towardZero))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
