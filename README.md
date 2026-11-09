# Neon Drift

A simple neon arcade dodger for iPhone (tuned for the iPhone 18 Pro Max — runs at 120 Hz ProMotion, edge-to-edge around the Dynamic Island).

**How to play:** drag anywhere on the screen to steer your orb left and right. Dodge the pink shards, grab the gold orbs (+10). It gets faster the longer you survive. Your best score is saved.

## Run it on your phone

1. Open `NeonDrift.xcodeproj` in Xcode 16 or newer (on a Mac).
2. Select the **NeonDrift** target → *Signing & Capabilities* → pick your Team (a free Apple ID works). If Xcode complains about the bundle ID, change `com.example.NeonDrift` to something unique.
3. Plug in your iPhone (or pick an iPhone simulator), choose it as the run destination, and press **⌘R**.
   - First time on a real device: enable *Settings → Privacy & Security → Developer Mode*, and trust your developer certificate under *Settings → General → VPN & Device Management*.

## Code

| File | What it does |
| --- | --- |
| `NeonDrift/GameScene.swift` | SpriteKit scene: spawning, movement, collisions, particles, haptics |
| `NeonDrift/ContentView.swift` | SwiftUI menu, score HUD and game-over screens over a `SpriteView` |
| `NeonDrift/GameModel.swift` | Shared game state + best-score persistence |
| `Config/Info.plist` | Enables 120 Hz on ProMotion iPhones |

No third-party dependencies; requires iOS 18+.
