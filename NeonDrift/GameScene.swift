import SpriteKit
import UIKit

final class GameScene: SKScene {
    weak var model: GameModel?

    // MARK: Types

    private enum Kind { case shard, orb }

    private struct Entity {
        let node: SKShapeNode
        let kind: Kind
        let radius: CGFloat
        let speed: CGFloat
        let spin: CGFloat
    }

    private struct Star {
        let node: SKShapeNode
        let speed: CGFloat
    }

    // MARK: Palette

    private let pink = UIColor(red: 1.0, green: 0.2, blue: 0.6, alpha: 1)
    private let cyan = UIColor(red: 0.2, green: 0.95, blue: 1.0, alpha: 1)
    private let gold = UIColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1)

    // MARK: Nodes

    private let world = SKNode()
    private let player = SKShapeNode(circleOfRadius: 16)
    private let playerRadius: CGFloat = 16
    private var stars: [Star] = []
    private var entities: [Entity] = []

    // MARK: State

    private var didSetup = false
    private var isPlaying = false
    private var lastTime: TimeInterval = 0
    private var elapsed: TimeInterval = 0
    private var spawnTimer: TimeInterval = 0
    private var orbTimer: TimeInterval = 1.5
    private var trailTimer: TimeInterval = 0
    private var distance: CGFloat = 0
    private var orbsCollected = 0

    private var targetX: CGFloat = 0
    private var touchStartX: CGFloat?
    private var playerStartX: CGFloat = 0

    private let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    private let crashHaptic = UINotificationFeedbackGenerator()

    /// Base fall speed in points/second; ramps up over time.
    private var fallSpeed: CGFloat {
        min(300 + CGFloat(elapsed) * 11, 900)
    }

    // MARK: Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.03, green: 0.02, blue: 0.08, alpha: 1)
        scaleMode = .resizeFill
        guard !didSetup else { return }
        didSetup = true
        addChild(world)
        buildStars()
        buildPlayer()
        layoutForSize()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        if didSetup { layoutForSize() }
    }

    private func layoutForSize() {
        guard size.width > 0, size.height > 0 else { return }
        for star in stars {
            star.node.position = CGPoint(x: .random(in: 0...size.width), y: .random(in: 0...size.height))
        }
        if !isPlaying {
            targetX = size.width / 2
            player.position = CGPoint(x: targetX, y: size.height * 0.2)
        }
    }

    // MARK: Building

    private func buildStars() {
        for _ in 0..<90 {
            let r = CGFloat.random(in: 0.6...1.8)
            let star = SKShapeNode(circleOfRadius: r)
            star.fillColor = UIColor(white: 1, alpha: .random(in: 0.3...0.9))
            star.strokeColor = .clear
            star.zPosition = 0
            world.addChild(star)
            stars.append(Star(node: star, speed: r * 60))
        }
    }

    private func buildPlayer() {
        player.fillColor = UIColor(red: 0.9, green: 1, blue: 1, alpha: 1)
        player.strokeColor = cyan
        player.lineWidth = 4
        player.zPosition = 5

        let halo = SKShapeNode(circleOfRadius: 26)
        halo.fillColor = cyan.withAlphaComponent(0.15)
        halo.strokeColor = cyan.withAlphaComponent(0.35)
        halo.lineWidth = 2
        halo.zPosition = -1
        halo.run(.repeatForever(.sequence([
            .scale(to: 1.15, duration: 0.6),
            .scale(to: 0.95, duration: 0.6),
        ])))
        player.addChild(halo)
        world.addChild(player)
    }

    private func makeShard(radius r: CGFloat) -> SKShapeNode {
        let sides = Int.random(in: 3...5)
        let path = CGMutablePath()
        for i in 0..<sides {
            let angle = CGFloat(i) / CGFloat(sides) * .pi * 2 + .random(in: -0.25...0.25)
            let len = r * .random(in: 0.8...1.1)
            let p = CGPoint(x: cos(angle) * len, y: sin(angle) * len)
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()

        let node = SKShapeNode(path: path)
        node.strokeColor = pink
        node.fillColor = pink.withAlphaComponent(0.18)
        node.lineWidth = 3
        node.lineJoin = .round
        node.zPosition = 2

        let glow = SKShapeNode(path: path)
        glow.strokeColor = pink.withAlphaComponent(0.25)
        glow.fillColor = .clear
        glow.lineWidth = 10
        glow.lineJoin = .round
        glow.zPosition = -0.5
        node.addChild(glow)
        return node
    }

    private func makeOrb() -> SKShapeNode {
        let node = SKShapeNode(circleOfRadius: 10)
        node.fillColor = gold
        node.strokeColor = gold.withAlphaComponent(0.4)
        node.lineWidth = 8
        node.zPosition = 2
        node.run(.repeatForever(.sequence([
            .scale(to: 1.2, duration: 0.35),
            .scale(to: 1.0, duration: 0.35),
        ])))
        return node
    }

    // MARK: Game flow

    func startGame() {
        guard !isPlaying, size.width > 0 else { return }
        for e in entities { e.node.removeFromParent() }
        entities.removeAll()

        elapsed = 0
        spawnTimer = 0.6
        orbTimer = 1.5
        distance = 0
        orbsCollected = 0
        targetX = size.width / 2
        player.position = CGPoint(x: targetX, y: size.height * 0.2)
        player.isHidden = false
        player.setScale(1)
        world.position = .zero
        isPlaying = true

        lightHaptic.prepare()
        crashHaptic.prepare()
        model?.begin()
    }

    private func crash() {
        isPlaying = false
        touchStartX = nil
        crashHaptic.notificationOccurred(.error)
        burst(at: player.position, color: pink, count: 26, distance: 140)
        burst(at: player.position, color: cyan, count: 18, distance: 90)
        player.isHidden = true

        let shake = SKAction.sequence((0..<8).map { i -> SKAction in
            let mag: CGFloat = 14 * (1 - CGFloat(i) / 8)
            return SKAction.move(to: CGPoint(x: .random(in: -mag...mag), y: .random(in: -mag...mag)), duration: 0.035)
        } + [.move(to: .zero, duration: 0.035)])
        world.run(shake)

        // Give the explosion a moment before the overlay appears.
        run(.sequence([.wait(forDuration: 0.7), .run { [weak self] in self?.model?.end() }]))
    }

    private func collect(_ e: Entity) {
        lightHaptic.impactOccurred()
        orbsCollected += 1
        burst(at: e.node.position, color: gold, count: 12, distance: 60)
        e.node.removeFromParent()

        let label = SKLabelNode(text: "+10")
        label.fontName = "AvenirNext-Heavy"
        label.fontSize = 22
        label.fontColor = gold
        label.position = e.node.position
        label.zPosition = 6
        world.addChild(label)
        label.run(.sequence([
            .group([.moveBy(x: 0, y: 50, duration: 0.6), .fadeOut(withDuration: 0.6)]),
            .removeFromParent(),
        ]))
    }

    private func burst(at point: CGPoint, color: UIColor, count: Int, distance: CGFloat) {
        for _ in 0..<count {
            let p = SKShapeNode(circleOfRadius: .random(in: 2...4.5))
            p.fillColor = color
            p.strokeColor = .clear
            p.position = point
            p.zPosition = 4
            world.addChild(p)
            let angle = CGFloat.random(in: 0...(.pi * 2))
            let dist = CGFloat.random(in: distance * 0.4...distance)
            let t = TimeInterval.random(in: 0.35...0.7)
            let move = SKAction.moveBy(x: cos(angle) * dist, y: sin(angle) * dist, duration: t)
            move.timingMode = .easeOut
            p.run(.sequence([.group([move, .fadeOut(withDuration: t), .scale(to: 0.3, duration: t)]),
                             .removeFromParent()]))
        }
    }

    // MARK: Spawning

    private func spawnShard() {
        let big = Double.random(in: 0...1) < min(0.08 + elapsed * 0.004, 0.3)
        let r: CGFloat = big ? .random(in: 34...48) : .random(in: 14...28)
        let node = makeShard(radius: r)
        node.position = CGPoint(x: .random(in: r...(size.width - r)), y: size.height + r + 10)
        world.addChild(node)
        entities.append(Entity(node: node, kind: .shard, radius: r * 0.78,
                               speed: fallSpeed * .random(in: 0.85...1.25),
                               spin: .random(in: -3...3)))
    }

    private func spawnOrb() {
        let node = makeOrb()
        node.position = CGPoint(x: .random(in: 30...(size.width - 30)), y: size.height + 20)
        world.addChild(node)
        entities.append(Entity(node: node, kind: .orb, radius: 16, speed: fallSpeed * 0.9, spin: 0))
    }

    private func dropTrail() {
        let dot = SKShapeNode(circleOfRadius: 11)
        dot.fillColor = cyan.withAlphaComponent(0.45)
        dot.strokeColor = .clear
        dot.position = player.position
        dot.zPosition = 1
        world.addChild(dot)
        let t = 0.35
        dot.run(.sequence([
            .group([.moveBy(x: 0, y: -fallSpeed * CGFloat(t) * 0.6, duration: t),
                    .fadeOut(withDuration: t),
                    .scale(to: 0.2, duration: t)]),
            .removeFromParent(),
        ]))
    }

    // MARK: Update loop

    override func update(_ currentTime: TimeInterval) {
        let dt = lastTime == 0 ? 1.0 / 60 : min(currentTime - lastTime, 1.0 / 30)
        lastTime = currentTime
        let fdt = CGFloat(dt)

        // Starfield always drifts; faster while playing.
        let starBoost: CGFloat = isPlaying ? fallSpeed / 120 : 1
        for star in stars {
            star.node.position.y -= star.speed * starBoost * fdt
            if star.node.position.y < -4 {
                star.node.position = CGPoint(x: .random(in: 0...max(size.width, 1)), y: size.height + 4)
            }
        }

        guard isPlaying else { return }
        elapsed += dt

        // Ease the player toward the finger.
        player.position.x += (targetX - player.position.x) * min(1, fdt * 20)

        trailTimer -= dt
        if trailTimer <= 0 { trailTimer = 1.0 / 45; dropTrail() }

        spawnTimer -= dt
        if spawnTimer <= 0 {
            spawnTimer = max(0.16, 0.65 - elapsed * 0.012)
            spawnShard()
            if elapsed > 25 && Bool.random() { spawnShard() }
        }

        orbTimer -= dt
        if orbTimer <= 0 {
            orbTimer = .random(in: 1.4...2.6)
            spawnOrb()
        }

        var survivors: [Entity] = []
        survivors.reserveCapacity(entities.count)
        for e in entities {
            e.node.position.y -= e.speed * fdt
            e.node.zRotation += e.spin * fdt

            let dx = e.node.position.x - player.position.x
            let dy = e.node.position.y - player.position.y
            if hypot(dx, dy) < e.radius + playerRadius {
                switch e.kind {
                case .orb:
                    collect(e)
                    continue
                case .shard:
                    crash()
                    return
                }
            }

            if e.node.position.y < -80 {
                e.node.removeFromParent()
                continue
            }
            survivors.append(e)
        }
        entities = survivors

        distance += fallSpeed * fdt
        let newScore = Int(distance / 40) + orbsCollected * 10
        if model?.score != newScore { model?.score = newScore }
    }

    // MARK: Touch input (relative drag — your thumb never covers the ship)

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isPlaying, let touch = touches.first else { return }
        touchStartX = touch.location(in: self).x
        playerStartX = targetX
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isPlaying, let touch = touches.first, let startX = touchStartX else { return }
        let x = playerStartX + (touch.location(in: self).x - startX) * 1.4
        targetX = min(max(x, playerRadius + 6), size.width - playerRadius - 6)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchStartX = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchStartX = nil
    }
}
