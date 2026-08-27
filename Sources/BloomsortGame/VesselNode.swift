#if canImport(SpriteKit)
import BloomsortDesign
import BloomsortDomain
import SpriteKit

/// Çiçek kabı (`docs/ui-spec.md` §2.2) — oynanışın atomu.
///
/// Tamamen parametrik: `SKShapeNode` + bezier. Elle çizilmiş sprite yok
/// (`CLAUDE.md`, teknik kısıt).
public final class VesselNode: SKNode {
    public let vesselIndex: Int
    public private(set) var capacity: Int
    public private(set) var size: CGSize
    public private(set) var slotDiameter: CGFloat

    private let body: SKShapeNode
    private var slotHints: [SKShapeNode] = []
    private var beadNodes: [BeadNode] = []
    private var lockBadge: SKNode?
    private var presentation: BoardPresentation

    /// Kabın taban orta noktası sahne koordinatında; taneler bunun üstüne dizilir.
    public init(vesselIndex: Int, capacity: Int, size: CGSize,
                slotDiameter: CGFloat, presentation: BoardPresentation) {
        self.vesselIndex = vesselIndex
        self.capacity = capacity
        self.size = size
        self.slotDiameter = slotDiameter
        self.presentation = presentation

        body = SKShapeNode(path: VesselNode.silhouette(size: size))
        body.fillColor = SKColor(Palette.moss.opacity(0.55))
        body.strokeColor = SKColor(Palette.mossHigh)
        body.lineWidth = 2
        body.isAntialiased = true

        super.init()
        zPosition = ZOrder.vessel
        addChild(body)
        buildSlotHints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) kullanılmıyor") }

    /// Organik vazo silueti: taban yarıçapı 20, ağız 8 (§1.5).
    ///
    /// Yol kabın **taban orta noktasına** göre çizilir; y yukarı doğru artar.
    static func silhouette(size: CGSize) -> CGPath {
        let halfWidth = size.width / 2
        let height = size.height
        let bottomRadius = min(CGFloat(Radius.vesselBottom), halfWidth, height / 2)
        let mouthRadius = min(CGFloat(Radius.vesselMouth), halfWidth, height / 2)

        let path = CGMutablePath()
        path.move(to: CGPoint(x: -halfWidth, y: bottomRadius))
        path.addLine(to: CGPoint(x: -halfWidth, y: height - mouthRadius))
        path.addQuadCurve(to: CGPoint(x: -halfWidth + mouthRadius, y: height),
                          control: CGPoint(x: -halfWidth, y: height))
        path.addLine(to: CGPoint(x: halfWidth - mouthRadius, y: height))
        path.addQuadCurve(to: CGPoint(x: halfWidth, y: height - mouthRadius),
                          control: CGPoint(x: halfWidth, y: height))
        path.addLine(to: CGPoint(x: halfWidth, y: bottomRadius))
        path.addQuadCurve(to: CGPoint(x: halfWidth - bottomRadius, y: 0),
                          control: CGPoint(x: halfWidth, y: 0))
        path.addLine(to: CGPoint(x: -halfWidth + bottomRadius, y: 0))
        path.addQuadCurve(to: CGPoint(x: -halfWidth, y: bottomRadius),
                          control: CGPoint(x: -halfWidth, y: 0))
        path.closeSubpath()
        return path
    }

    /// Bir yuvanın merkezinin kap içindeki yeri (tabandan yukarı).
    public func slotCenter(_ slot: Int) -> CGPoint {
        let inset = (size.height - CGFloat(capacity) * slotDiameter) / 2
        return CGPoint(x: 0, y: inset + slotDiameter * (CGFloat(slot) + 0.5))
    }

    private func buildSlotHints() {
        slotHints.forEach { $0.removeFromParent() }
        slotHints = (0..<capacity).map { slot in
            let hint = SKShapeNode(circleOfRadius: (slotDiameter - 8) / 2)
            hint.fillColor = SKColor(Palette.duskDeep.opacity(0.4))
            hint.strokeColor = .clear
            hint.position = slotCenter(slot)
            hint.zPosition = -1
            addChild(hint)
            return hint
        }
    }

    // MARK: - İçerik

    /// Kabı verilen domain durumuna göre yeniden kurar (animasyonsuz).
    public func setContents(_ vessel: Vessel, presentation: BoardPresentation) {
        self.presentation = presentation
        beadNodes.forEach { $0.removeFromParent() }
        beadNodes = vessel.beads.enumerated().map { slot, bead in
            let node = BeadNode(color: bead.color,
                                diameter: slotDiameter - 6,
                                presentation: presentation)
            node.position = slotCenter(slot)
            node.zPosition = ZOrder.bead
            addChild(node)
            if vessel.dewIndex == slot { node.setFrozen(true) }
            return node
        }
        setLocked(vessel.lockCountdown)
        // Boş kap: kenarlık %60 opaklık, içeride kesikli daire ipucu.
        body.alpha = vessel.isEmpty ? 0.6 : 1.0
    }

    /// Ağızdan `count` tane alır ve düğümlerini döner (arı taşıyacak).
    public func detachTop(_ count: Int) -> [BeadNode] {
        let taken = Array(beadNodes.suffix(count))
        beadNodes.removeLast(count)
        return taken
    }

    /// Taneyi kabın en üst boş yuvasına yerleştirir.
    public func attach(_ bead: BeadNode) -> CGPoint {
        let slot = beadNodes.count
        beadNodes.append(bead)
        return slotCenter(slot)
    }

    public var topBead: BeadNode? { beadNodes.last }
    public var beadCount: Int { beadNodes.count }

    // MARK: - Durumlar (§2.2)

    /// Seçili kaynak: kap 4 pt yükselir, kenarlık `--pollen` 2,5 pt.
    public func setSelected(_ selected: Bool) {
        removeAction(forKey: "selection")
        let duration = presentation.duration(Motion.micro)
        run(.moveTo(y: selected ? CGFloat(VesselMetrics.selectionHop) : 0, duration: duration),
            withKey: "selection")
        body.strokeColor = SKColor(selected ? Palette.pollen : Palette.mossHigh)
        body.lineWidth = selected ? 2.5 : 2
        topBead?.setSelected(selected, presentation: presentation)
    }

    /// Geçersiz hedef: 6 pt yatay titreme, 3 döngü, 240 ms, kenarlık 1 kare `--ember`.
    public func playInvalidFeedback() {
        let amplitude = CGFloat(VesselMetrics.invalidShake)
        let total = presentation.duration(VesselMetrics.invalidShakeDuration)
        let step = total / 12
        var steps: [SKAction] = []
        for _ in 0..<3 {
            steps.append(.moveBy(x: -amplitude, y: 0, duration: step))
            steps.append(.moveBy(x: amplitude * 2, y: 0, duration: step * 2))
            steps.append(.moveBy(x: -amplitude, y: 0, duration: step))
        }
        run(.sequence(steps), withKey: "invalid")
        body.strokeColor = SKColor(Palette.ember)
        run(.sequence([.wait(forDuration: step),
                       .run { [weak self] in self?.body.strokeColor = SKColor(Palette.mossHigh) }]))
    }

    /// Tek renkle dolu, çiçek açma öncesi: kenarlık `--pollen`, 200 ms nabız.
    public func playReadyToBloomPulse() {
        body.strokeColor = SKColor(Palette.pollen)
        let pulse = SKAction.sequence([
            .fadeAlpha(to: 0.7, duration: presentation.duration(0.1)),
            .fadeAlpha(to: 1.0, duration: presentation.duration(0.1)),
        ])
        body.run(pulse)
    }

    /// Kapalı tomurcuk: %45 opaklık + kalan sayaç rozeti (§2.2).
    public func setLocked(_ countdown: Int) {
        lockBadge?.removeFromParent()
        lockBadge = nil
        guard countdown > 0 else {
            alpha = 1
            return
        }
        alpha = 0.45
        let badge = SKNode()
        let pill = SKShapeNode(rectOf: CGSize(width: 30, height: 20), cornerRadius: 10)
        pill.fillColor = SKColor(Palette.moss)
        pill.strokeColor = SKColor(Palette.pollen)
        pill.lineWidth = 1
        let label = SKLabelNode(text: "\(countdown)")
        label.fontSize = 12
        label.fontName = "SFProRounded-Bold"
        label.fontColor = SKColor(Palette.pollen)
        label.verticalAlignmentMode = .center
        badge.addChild(pill)
        badge.addChild(label)
        badge.position = CGPoint(x: 0, y: size.height + 14)
        badge.zPosition = ZOrder.selection
        addChild(badge)
        lockBadge = badge
    }

    // MARK: - Erişilebilirlik

    /// VoiceOver etiketi. Metin `BloomsortDesign.BoardAccessibility`'de —
    /// orası platformdan bağımsız ve testli.
    public static func accessibilityLabel(for vessel: Vessel, index: Int) -> String {
        BoardAccessibility.vesselLabel(index: index,
                                       capacity: vessel.capacity,
                                       filled: vessel.count,
                                       topColorIndex: vessel.top?.color.index,
                                       lockCountdown: vessel.lockCountdown,
                                       hasDew: vessel.hasDew)
    }
}
#endif
