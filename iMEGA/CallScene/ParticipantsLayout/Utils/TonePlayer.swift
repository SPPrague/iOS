
import Foundation
import MEGADomain

final class TonePlayer: NSObject {
    enum ToneType: String {
        case callEnded
        case participantJoined
        case participantLeft
        case reconnecting
        
        fileprivate var fileURL: URL? {
            Bundle.main.url(forResource: rawValue, withExtension: "wav")
        }
    }
    
    private var audioPlayer: AVAudioPlayer?
    
    func play(tone: ToneType) {
        guard let toneURL = tone.fileURL else {
            MEGALogDebug("\(tone.rawValue) file not found")
            return
        }
        
        try? AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.allowBluetooth, .allowBluetoothA2DP, .mixWithOthers])
        
        if let audioPlayer = audioPlayer {
            audioPlayer.stop()
            resetAudioPlayer()
        }

        self.audioPlayer = try? AVAudioPlayer(contentsOf: toneURL)
        self.audioPlayer?.delegate = self
        self.audioPlayer?.play()
    }
    
    private func resetAudioPlayer() {
        self.audioPlayer?.delegate = nil
        self.audioPlayer = nil
    }
}

extension TonePlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if player === self.audioPlayer {
            resetAudioPlayer()
        }
        
        AudioSessionUseCase(audioSessionRepository: AudioSessionRepository(audioSession: AVAudioSession.sharedInstance(), callActionManager: CallActionManager.shared)).configureAudioSession()
    }
}
