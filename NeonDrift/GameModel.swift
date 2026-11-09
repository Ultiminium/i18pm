import Foundation
import Observation

/// Shared state between the SpriteKit scene and the SwiftUI overlay.
@Observable
final class GameModel {
    enum Phase { case menu, playing, gameOver }

    var phase: Phase = .menu
    var score = 0
    var best = UserDefaults.standard.integer(forKey: GameModel.bestKey)
    var isNewBest = false

    private static let bestKey = "neondrift.best"

    func begin() {
        score = 0
        isNewBest = false
        phase = .playing
    }

    func end() {
        if score > best {
            best = score
            isNewBest = true
            UserDefaults.standard.set(best, forKey: GameModel.bestKey)
        }
        phase = .gameOver
    }
}
