#if canImport(SpriteKit)
import BloomsortDesign
import BloomsortDomain
import SpriteKit

/// Polen tanesi (`docs/ui-spec.md` §2.2).
///
/// Daire + üstte 30° açılı %18 beyaz highlight. Renk körlüğü modunda merkeze
/// 10 pt sembol çizilir — renk asla tek bilgi kaynağı değil (§5).
public final class BeadNode: SKNode {
    public let color: PollenColor
    public private(set) var diameter: CGFloat

    private let disc: SKShapeNode
    private let highlight: SKShapeNode
    private var symbol: SKLabelNode?
    /// Çiy damlası katmanı (§2.2, "Çiy donmuş" durumu).
    private var frost: SKShapeNode?

    public init(color: PollenColor, diameter: CGFloat, presentation: BoardPresentation) {
        self.color = color
        self.diameter = diameter

        let palette = Palette.pollen(color.index)
        disc = SKShapeNode(circleOfRadius: diameter / 2)
        disc.fillColor = SKColor(palette.color)
        disc.strokeColor = .clear
        disc.isAntialiased = true

        // Üstte 30° açılı highlight: tanenin üst-sol yayı.
        let highlightRadius = diameter / 2 - 2
        let path = CGMutablePath()
        path.addArc(center: .zero, radius: highlightRadius,
                    startAngle: .pi * 0.75, endAngle: .pi * 1.45, clockwise: false)
        highlight = SKShapeNode(path: path)
        highlight.strokeColor = SKColor(RGB(red: 1, green: 1, blue: 1, alpha: 0.18))
        highlight.lineWidth = max(1.5, diameter * 0.08)
        highlight.lineCap = .round
        highlight.zRotation = .pi / 6   // 30°

        super.init()
        addChild(disc)
        addChild(highlight)
        setColorBlindSymbols(presentation.colorBlindSymbols)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) kullanılmıyor") }

    /// Renk körlüğü sembolünü açar/kapatır.
    public func setColorBlindSymbols(_ enabled: Bool) {
        if enabled, symbol == nil {
            let label = SKLabelNode(text: Palette.pollen(color.index).symbol)
            label.fontSize = CGFloat(Palette.symbolPointSize)
            label.fontName = "SFProRounded-Bold"
            label.fontColor = SKColor(Palette.symbolColor)
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.zPosition = 1
            addChild(label)
            symbol = label
        } else if !enabled {
            symbol?.removeFromParent()
            symbol = nil
        }
    }

    /// Çiy damlası: `--dew` %35 buzlu katman + ◇ ikon (§2.2).
    public func setFrozen(_ frozen: Bool) {
        if frozen, frost == nil {
            let layer = SKShapeNode(circleOfRadius: diameter / 2)
            layer.fillColor = SKColor(Palette.dew.opacity(0.35))
            layer.strokeColor = SKColor(Palette.dew)
            layer.lineWidth = 1
            layer.zPosition = 2
            let icon = SKLabelNode(text: "◇")
            icon.fontSize = CGFloat(Palette.symbolPointSize)
            icon.fontColor = SKColor(Palette.duskDeep)
            icon.verticalAlignmentMode = .center
            layer.addChild(icon)
            addChild(layer)
            frost = layer
        } else if !frozen {
            frost?.removeFromParent()
            frost = nil
        }
    }

    /// Seçili kaynağın üst tanesi 8 pt yükselir ve ışır (§2.2).
    public func setSelected(_ selected: Bool, presentation: BoardPresentation) {
        removeAction(forKey: "selection")
        let lift = selected ? CGFloat(VesselMetrics.selectionLift) : 0
        let duration = presentation.duration(Motion.micro)
        run(.moveTo(y: lift, duration: duration), withKey: "selection")
        disc.glowWidth = selected ? 8 : 0
    }

    /// Polen düşüşü: `move` + `easeIn` 180 ms, ardından 60 ms %6 squash (§2.6).
    public func dropAction(to point: CGPoint, presentation: BoardPresentation) -> SKAction {
        let move = SKAction.move(to: point, duration: presentation.duration(Motion.micro))
        move.timingMode = .easeIn
        let squashDuration = presentation.duration(0.06)
        let squash = SKAction.sequence([
            .group([.scaleX(to: 1.06, duration: squashDuration / 2),
                    .scaleY(to: 0.94, duration: squashDuration / 2)]),
            .group([.scaleX(to: 1.0, duration: squashDuration / 2),
                    .scaleY(to: 1.0, duration: squashDuration / 2)]),
        ])
        return .sequence([move, squash])
    }
}
#endif
