import SpriteKit
import SwiftUI

struct ContentView: View {
    @State private var model = GameModel()
    @State private var scene = GameScene()

    var body: some View {
        ZStack {
            SpriteView(scene: scene, preferredFramesPerSecond: 120, options: [.ignoresSiblingOrder])
                .ignoresSafeArea()

            switch model.phase {
            case .menu:
                MenuOverlay(best: model.best, onPlay: { scene.startGame() })
                    .transition(.opacity)
            case .playing:
                ScoreHUD(score: model.score)
                    .transition(.opacity)
            case .gameOver:
                GameOverOverlay(score: model.score, best: model.best,
                                isNewBest: model.isNewBest, onPlay: { scene.startGame() })
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .animation(.easeOut(duration: 0.25), value: model.phase)
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .onAppear { scene.model = model }
    }
}

// MARK: - Overlays

private extension Color {
    static let neonCyan = Color(red: 0.2, green: 0.95, blue: 1.0)
    static let neonPink = Color(red: 1.0, green: 0.2, blue: 0.6)
    static let neonGold = Color(red: 1.0, green: 0.85, blue: 0.3)
}

private struct NeonText: View {
    let text: String
    let size: CGFloat
    var color: Color = .neonCyan

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .shadow(color: color, radius: 4)
            .shadow(color: color, radius: 14)
    }
}

private struct PlayButton: View {
    let title: String
    let action: @MainActor () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .tracking(4)
                .foregroundStyle(.white)
                .padding(.horizontal, 48)
                .padding(.vertical, 18)
                .background(Capsule().fill(Color.neonPink.opacity(0.25)))
                .overlay(Capsule().stroke(Color.neonPink, lineWidth: 2.5))
                .shadow(color: .neonPink, radius: 12)
        }
        .buttonStyle(.plain)
    }
}

private struct MenuOverlay: View {
    let best: Int
    let onPlay: @MainActor () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            VStack(spacing: 0) {
                NeonText(text: "NEON", size: 76, color: .neonPink)
                NeonText(text: "DRIFT", size: 76)
            }
            Text("Drag anywhere to steer.\nDodge the shards. Grab the orbs.")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.75))
            Spacer()
            if best > 0 {
                Text("BEST  \(best)")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.neonGold)
            }
            PlayButton(title: "PLAY", action: onPlay)
            Spacer().frame(height: 80)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.35).ignoresSafeArea())
    }
}

private struct ScoreHUD: View {
    let score: Int

    var body: some View {
        VStack {
            NeonText(text: "\(score)", size: 48)
                .monospacedDigit()
                .contentTransition(.numericText())
                .padding(.top, 12)
            Spacer()
        }
        .allowsHitTesting(false)
    }
}

private struct GameOverOverlay: View {
    let score: Int
    let best: Int
    let isNewBest: Bool
    let onPlay: @MainActor () -> Void

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            NeonText(text: "CRASHED", size: 52, color: .neonPink)
            NeonText(text: "\(score)", size: 96)
                .monospacedDigit()
            if isNewBest {
                Text("NEW BEST!")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .tracking(3)
                    .foregroundStyle(Color.neonGold)
                    .shadow(color: .neonGold, radius: 10)
            } else {
                Text("BEST  \(best)")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.neonGold)
            }
            Spacer()
            PlayButton(title: "AGAIN", action: onPlay)
            Spacer().frame(height: 80)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.45).ignoresSafeArea())
    }
}

#Preview {
    ContentView()
}
