import Foundation
import MEGADomain

extension Array where Element == NodeEntity {
    func durationText() async -> String {
        let playlistDuration = map(\.duration).reduce(0, +)
        return TimeInterval(playlistDuration).timeString
    }
}
