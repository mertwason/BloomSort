#if canImport(SpriteKit)
import BloomsortDesign
import BloomsortDomain
import SpriteKit

/// Sahnenin dışarıya bağlandığı yer.
///
/// Sahne `GameState`'i **yalnızca okur**; mutasyonu domain'e delege eder
/// (`CLAUDE.md`, Görev 4). Hamleyi delegate uygular ve sonucu geri verir.
public protocol BoardSceneDelegate: AnyObject {
    /// Oyuncu bir hamle istedi. Uygulanabiliyorsa delegate `animate(move:resulting:)`
    /// çağırmalı; uygulanamıyorsa `rejectMove(to:)`.
    func boardScene(_ scene: BoardScene, didRequestMoveFrom source: Int, to destination: Int)
    /// Tahtada iki parmak dokunuş — geri al (§2.2).
    func boardSceneDidRequestUndo(_ scene: BoardScene)
    /// Uzun basma: kap içeriğini büyütülmüş göster (§2.2, erişilebilirlik).
    func boardScene(_ scene: BoardScene, didLongPressVessel index: Int)
    /// Haptik tetikleyicisi (§1.8) — servis katmanı çalar.
    func boardScene(_ scene: BoardScene, didTrigger haptic: Haptic)
    /// Bir kap çiçek açtı (§2.5) — ses ve levha şeridi için.
    func boardScene(_ scene: BoardScene, didBloomVessel index: Int, color: PollenColor)
    /// Bir polen yerleşti — pentatonik nota için yığın derinliği (§7.3).
    func boardScene(_ scene: BoardScene, didLandBeadAtDepth depth: Int, color: PollenColor)
}

/// Oyun tahtası (`docs/ui-spec.md` §3.5).
public final class BoardScene: SKScene {
    public weak var boardDelegate: BoardSceneDelegate?
    public private(set) var state: GameState
    public var presentation: BoardPresentation {
        didSet { rebuild() }
    }

    /// Aynı anda en fazla 3 arı animasyonu; fazlası kuyrukta (`CLAUDE.md`).
    public static let maximumConcurrentBees = 3

    private var vesselNodes: [VesselNode] = []
    private var selectedIndex: Int?
    /// Eşzamanlılık kuyruğu `BloomsortDesign`'dan — sırası testli.
    private var queue = AnimationQueue<Int>(concurrencyLimit: BoardScene.maximumConcurrentBees)
    private var jobs: [Int: () -> Void] = [:]
    private var nextJobIdentifier = 0
    private var longPressStart: (index: Int, time: TimeInterval)?
    private let beeLayer = SKNode()
    /// Levha şeridinin sahne koordinatındaki yeri — çiçekler oraya uçar (§2.5).
    public var plateStripPoint: CGPoint = .zero

    public init(state: GameState, size: CGSize, presentation: BoardPresentation = .init()) {
        self.state = state
        self.presentation = presentation
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = SKColor(Palette.duskDeep)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) kullanılmıyor") }

    public override func didMove(to view: SKView) {
        beeLayer.zPosition = ZOrder.bee
        addChild(beeLayer)
        buildBackground()
        rebuild()
    }

    // MARK: - Kurulum

    /// Zemin: `--dusk-deep`'ten `--dusk`'a dikey gradyan (§3.5).
    private func buildBackground() {
        let gradient = SKShapeNode(rect: CGRect(origin: .zero, size: size))
        gradient.fillColor = SKColor(Palette.dusk)
        gradient.strokeColor = .clear
        gradient.zPosition = ZOrder.background
        gradient.alpha = 0.9
        addChild(gradient)
    }

    /// Tahtayı sıfırdan kurar — seviye açılışı, geri al, sıfırla.
    public func present(state newState: GameState) {
        state = newState
        rebuild()
    }

    private func rebuild() {
        vesselNodes.forEach { $0.removeFromParent() }
        selectedIndex = nil

        let layout = BoardLayout.compute(capacities: state.vessels.map(\.capacity),
                                         width: Double(size.width),
                                         height: Double(size.height))
        vesselNodes = layout.frames.map { frame in
            let vessel = state.vessels[frame.vesselIndex]
            let node = VesselNode(vesselIndex: frame.vesselIndex,
                                  capacity: vessel.capacity,
                                  size: CGSize(width: frame.width, height: frame.height),
                                  slotDiameter: CGFloat(VesselMetrics.size(forCapacity: vessel.capacity).slotDiameter)
                                      * CGFloat(layout.scale),
                                  presentation: presentation)
            // Sahne koordinatı: y yukarı artar, düzen ise yukarıdan aşağı ölçüyor.
            node.position = CGPoint(x: CGFloat(frame.baseCenterX),
                                    y: size.height - CGFloat(frame.baseY))
            node.setContents(vessel, presentation: presentation)
            addChild(node)
            return node
        }
        markWindTargets()
    }

    /// Rüzgârın hedeflediği kaplar `--erguvan` kenarlıkla işaretlenir (§3.5).
    private func markWindTargets() {
        guard let announced = state.announcedWind else { return }
        for index in [announced.pair.first, announced.pair.second] {
            guard let node = node(for: index) else { continue }
            node.run(.repeat(.sequence([
                .fadeAlpha(to: 0.75, duration: presentation.duration(0.3)),
                .fadeAlpha(to: 1.0, duration: presentation.duration(0.3)),
            ]), count: announced.movesAway))
        }
    }

    private func node(for index: Int) -> VesselNode? {
        vesselNodes.first { $0.vesselIndex == index }
    }

    // MARK: - Girdi (§2.2)

    #if os(iOS)
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Tahtada iki parmak dokunuş: geri al.
        if touches.count >= 2 || (event?.allTouches?.count ?? 0) >= 2 {
            boardDelegate?.boardSceneDidRequestUndo(self)
            boardDelegate?.boardScene(self, didTrigger: .button)
            return
        }
        guard let touch = touches.first else { return }
        let index = vesselIndex(at: touch.location(in: self))
        if let index { longPressStart = (index, touch.timestamp) }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        defer { longPressStart = nil }
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        guard let index = vesselIndex(at: location) else {
            deselect()
            return
        }
        // Uzun basma (0,4 sn): büyütülmüş gösterim.
        if let start = longPressStart, start.index == index,
           touch.timestamp - start.time >= 0.4 {
            boardDelegate?.boardScene(self, didLongPressVessel: index)
            return
        }
        handleTap(on: index)
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        longPressStart = nil
    }
    #endif

    /// Dokunma noktasındaki kap — dokunma alanı en az 44 × 44 pt (§2.1).
    func vesselIndex(at point: CGPoint) -> Int? {
        var best: (index: Int, distance: CGFloat)?
        for node in vesselNodes {
            let frame = CGRect(x: node.position.x - node.size.width / 2,
                               y: node.position.y,
                               width: node.size.width,
                               height: node.size.height)
            let padded = frame.insetBy(dx: min(0, (frame.width - CGFloat(Layout.minimumTapTarget)) / 2),
                                       dy: min(0, (frame.height - CGFloat(Layout.minimumTapTarget)) / 2))
            guard padded.contains(point) else { continue }
            let distance = abs(point.x - node.position.x)
            if best == nil || distance < best!.distance { best = (node.vesselIndex, distance) }
        }
        return best?.index
    }

    /// Dokunma mantığı: seçim → hamle → iptal (§2.2).
    public func handleTap(on index: Int) {
        guard state.vessels.indices.contains(index) else { return }
        if let selected = selectedIndex {
            if selected == index {
                deselect()
                return
            }
            boardDelegate?.boardScene(self, didRequestMoveFrom: selected, to: index)
            return
        }
        guard !state.vessels[index].isEmpty, !state.vessels[index].isLocked else { return }
        select(index)
    }

    private func select(_ index: Int) {
        selectedIndex = index
        node(for: index)?.setSelected(true)
        boardDelegate?.boardScene(self, didTrigger: .vesselSelected)
    }

    private func deselect() {
        guard let selected = selectedIndex else { return }
        node(for: selected)?.setSelected(false)
        selectedIndex = nil
    }

    /// Hamle reddedildi: hedef titrer, `.warning` haptik.
    public func rejectMove(to index: Int) {
        node(for: index)?.playInvalidFeedback()
        boardDelegate?.boardScene(self, didTrigger: .invalidMove)
    }

    // MARK: - Animasyon

    /// Hamleyi oynatır ve bitince tahtayı `resulting` ile eşitler.
    ///
    /// Arı `move.count` kez gidip gelir (görsel), sayaçta 1 hamle yazar (§2.3).
    public func animate(move: Move, resulting: GameState, completion: (() -> Void)? = nil) {
        deselect()
        nextJobIdentifier += 1
        let identifier = nextJobIdentifier
        jobs[identifier] = { [weak self] in
            guard let self else { return }
            self.runBeeTrips(move: move) { [weak self] in
                guard let self else { return }
                self.state = resulting
                self.rebuild()
                self.reportBlooms(after: move, in: resulting)
                completion?()
                if let next = self.queue.finish() { self.jobs.removeValue(forKey: next)?() }
            }
        }
        if let started = queue.submit(identifier) {
            jobs[started]?()
        }
    }

    private func runBeeTrips(move: Move, completion: @escaping () -> Void) {
        guard let source = node(for: move.source), let destination = node(for: move.destination) else {
            completion()
            return
        }
        var remaining = move.count
        var depth = destination.beadCount

        func nextTrip() {
            guard remaining > 0 else {
                completion()
                return
            }
            remaining -= 1
            let bee = BeeNode(presentation: presentation)
            let start = CGPoint(x: source.position.x,
                                y: source.position.y + source.size.height)
            let end = CGPoint(x: destination.position.x,
                              y: destination.position.y + destination.size.height)
            bee.position = start
            beeLayer.addChild(bee)

            let carried = source.detachTop(1).first
            if let carried {
                carried.removeFromParent()
                bee.carry(carried)
            }

            let landingDepth = depth
            depth += 1
            bee.run(.sequence([
                bee.flyAction(from: start, to: end, trailHost: beeLayer),
                .run { [weak self] in
                    guard let self else { return }
                    if let bead = bee.releaseCargo() {
                        let slot = destination.attach(bead)
                        bead.position = CGPoint(x: 0, y: destination.size.height + 20)
                        destination.addChild(bead)
                        bead.run(bead.dropAction(to: slot, presentation: self.presentation))
                    }
                    self.boardDelegate?.boardScene(self, didTrigger: .beadLanded)
                    self.boardDelegate?.boardScene(self, didLandBeadAtDepth: landingDepth,
                                                   color: move.color)
                },
                .wait(forDuration: presentation.duration(Motion.micro)),
                .removeFromParent(),
                .run(nextTrip),
            ]))
        }
        nextTrip()
    }

    private func reportBlooms(after move: Move, in resulting: GameState) {
        let vessel = resulting.vessels[move.destination]
        guard vessel.isBloomed, let color = vessel.top?.color else { return }
        boardDelegate?.boardScene(self, didTrigger: .bloomed)
        boardDelegate?.boardScene(self, didBloomVessel: move.destination, color: color)
        playBloom(at: move.destination, color: color)
    }

    /// Çiçek açma sekansı (§2.5).
    public func playBloom(at index: Int, color: PollenColor) {
        guard let node = node(for: index) else { return }
        let radius = node.size.width * 0.55
        let flower = BloomFX.flower(radius: radius, color: Palette.pollen(color.index).color)
        flower.position = CGPoint(x: node.position.x,
                                  y: node.position.y + node.size.height / 2)
        flower.zPosition = ZOrder.bloom
        flower.setScale(0.01)
        addChild(flower)

        let dust = BloomFX.dustBurst(radius: radius,
                                     color: Palette.pollen(color.index).color,
                                     presentation: presentation)
        dust.position = flower.position
        dust.zPosition = ZOrder.bloom
        addChild(dust)

        flower.run(.sequence([
            .wait(forDuration: presentation.duration(BloomFX.holdBeforeBloom)),
            BloomFX.openAction(presentation: presentation),
            BloomFX.flyToPlateAction(destination: plateStripPoint, presentation: presentation),
            .removeFromParent(),
        ]))
        node.run(.sequence([
            .wait(forDuration: presentation.duration(BloomFX.holdBeforeBloom + Motion.bloom)),
            .fadeOut(withDuration: presentation.duration(BloomFX.flightToPlate)),
        ]))
    }
}
#endif
