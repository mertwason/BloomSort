#if canImport(SpriteKit)
import BloomsortDesign
import SpriteKit

/// Arı (`docs/ui-spec.md` §2.3): 18 × 14 pt, 5 parça, kanatlar 60 ms döngüde
/// 12° salınıyor. Uçuş sırasında arkasında 5 noktalı iz bırakır.
public final class BeeNode: SKNode {
    public static let bodySize = CGSize(width: 18, height: 14)

    private let leftWing: SKShapeNode
    private let rightWing: SKShapeNode
    private let presentation: BoardPresentation
    /// Taşınan polen (varsa) arının altında asılı durur.
    private var cargo: BeadNode?

    public init(presentation: BoardPresentation) {
        self.presentation = presentation

        let bodyPath = CGPath(ellipseIn: CGRect(x: -9, y: -5, width: 18, height: 10), transform: nil)
        let body = SKShapeNode(path: bodyPath)
        body.fillColor = SKColor(Palette.pollen)
        body.strokeColor = .clear

        func stripe(x: CGFloat) -> SKShapeNode {
            let stripe = SKShapeNode(rectOf: CGSize(width: 2.5, height: 9), cornerRadius: 1.2)
            stripe.fillColor = SKColor(Palette.dusk)
            stripe.strokeColor = .clear
            stripe.position = CGPoint(x: x, y: 0)
            return stripe
        }

        func wing(mirrored: Bool) -> SKShapeNode {
            let path = CGMutablePath()
            path.move(to: .zero)
            path.addQuadCurve(to: CGPoint(x: mirrored ? -10 : 10, y: 2),
                              control: CGPoint(x: mirrored ? -6 : 6, y: 9))
            path.addQuadCurve(to: .zero, control: CGPoint(x: mirrored ? -5 : 5, y: -1))
            let node = SKShapeNode(path: path)
            node.fillColor = SKColor(Palette.mist.opacity(0.55))
            node.strokeColor = .clear
            node.position = CGPoint(x: mirrored ? -2 : 2, y: 4)
            return node
        }

        leftWing = wing(mirrored: true)
        rightWing = wing(mirrored: false)

        super.init()
        zPosition = ZOrder.bee
        addChild(body)
        addChild(stripe(x: -1))
        addChild(stripe(x: 3))
        addChild(leftWing)
        addChild(rightWing)
        startWingBeat()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) kullanılmıyor") }

    private func startWingBeat() {
        guard !presentation.reduceMotion else { return }
        let angle = CGFloat.pi / 15   // 12°
        let half = SKAction.sequence([
            .rotate(toAngle: angle, duration: 0.03, shortestUnitArc: true),
            .rotate(toAngle: -angle, duration: 0.03, shortestUnitArc: true),
        ])
        leftWing.run(.repeatForever(half))
        rightWing.run(.repeatForever(half.reversed()))
    }

    public func carry(_ bead: BeadNode) {
        cargo = bead
        bead.position = CGPoint(x: 0, y: -12)
        bead.zPosition = -1
        addChild(bead)
    }

    public func releaseCargo() -> BeadNode? {
        let bead = cargo
        cargo = nil
        bead?.removeFromParent()
        return bead
    }

    /// Uçuş süresi ve eğrisi `BloomsortDesign.BeeFlight`'tan gelir — orası
    /// platformdan bağımsız ve testli.
    public static func flightDuration(distance: CGFloat, presentation: BoardPresentation) -> TimeInterval {
        BeeFlight.duration(distance: Double(distance), reduceMotion: presentation.reduceMotion)
    }

    /// Kaynak → hedef kuadratik Bézier; kontrol noktası orta noktanın 40 pt üstünde.
    public static func flightPath(from start: CGPoint, to end: CGPoint) -> CGPath {
        let control = BeeFlight.controlPoint(from: Point(x: Double(start.x), y: Double(start.y)),
                                             to: Point(x: Double(end.x), y: Double(end.y)))
        let path = CGMutablePath()
        path.move(to: start)
        path.addQuadCurve(to: end, control: CGPoint(x: control.x, y: control.y))
        return path
    }

    /// Uçuş eylemi. İz, `trailHost` üzerine bırakılır.
    public func flyAction(from start: CGPoint, to end: CGPoint,
                          trailHost: SKNode?) -> SKAction {
        let distance = hypot(end.x - start.x, end.y - start.y)
        let duration = BeeNode.flightDuration(distance: distance, presentation: presentation)
        let follow = SKAction.follow(BeeNode.flightPath(from: start, to: end),
                                    asOffset: false, orientToPath: false, duration: duration)
        follow.timingMode = .easeInEaseOut
        guard let trailHost, !presentation.reduceMotion else { return follow }
        return .group([follow, trailAction(on: trailHost, duration: duration)])
    }

    /// 5 noktalı sönümlenen iz: çap 3 → 1, opaklık %40 → 0, 60 ms gecikmeli.
    private func trailAction(on host: SKNode, duration: TimeInterval) -> SKAction {
        let dotCount = BeeFlight.trailDotCount
        let interval = max(duration / Double(dotCount * 2), 0.06)
        return .repeat(.sequence([
            .run { [weak self, weak host] in
                guard let self, let host else { return }
                let dot = SKShapeNode(circleOfRadius: CGFloat(BeeFlight.trailStartDiameter) / 2)
                dot.fillColor = SKColor(Palette.pollen.opacity(BeeFlight.trailStartOpacity))
                dot.strokeColor = .clear
                dot.position = self.position
                dot.zPosition = ZOrder.bee - 1
                host.addChild(dot)
                dot.run(.sequence([
                    .group([.fadeOut(withDuration: interval * Double(dotCount)),
                            .scale(to: CGFloat(BeeFlight.trailEndDiameter / BeeFlight.trailStartDiameter),
                                   duration: interval * Double(dotCount))]),
                    .removeFromParent(),
                ]))
            },
            .wait(forDuration: interval),
        ]), count: Int(duration / interval))
    }
}
#endif
