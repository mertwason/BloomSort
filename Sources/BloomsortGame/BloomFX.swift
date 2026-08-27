#if canImport(SpriteKit)
import BloomsortDesign
import SpriteKit

/// Çiçek açma sekansı (`docs/gdd.md` §2.5).
///
/// 1. 120 ms bekleme (oyuncu görsün)
/// 2. Petaller açılır — 6 yaprak, 420 ms, `spring(response .42, damping .68)`
/// 3. Polen tozu patlar — 24 parçacık, 700 ms
/// 4. Kap yükselip levha şeridine uçar (520 ms)
/// 5. Kap yerini boşaltır
public enum BloomFX {
    public static let petalCount = 6
    public static let holdBeforeBloom: TimeInterval = 0.12
    public static let particleCount = 24
    public static let particleLifetime: TimeInterval = 0.7
    public static let flightToPlate: TimeInterval = 0.52

    /// Altı yapraklı çiçek. Yarıçap kabın genişliğine göre ölçeklenir.
    public static func flower(radius: CGFloat, color: RGB) -> SKNode {
        let flower = SKNode()
        for index in 0..<petalCount {
            let petal = SKShapeNode(path: petalPath(radius: radius))
            petal.fillColor = SKColor(color)
            petal.strokeColor = SKColor(color.opacity(0.6))
            petal.lineWidth = 1
            petal.zRotation = CGFloat(index) * (.pi * 2 / CGFloat(petalCount))
            petal.setScale(0.01)
            flower.addChild(petal)
        }
        let core = SKShapeNode(circleOfRadius: radius * 0.28)
        core.fillColor = SKColor(Palette.pollen)
        core.strokeColor = .clear
        core.zPosition = 1
        flower.addChild(core)
        return flower
    }

    private static func petalPath(radius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: .zero)
        path.addQuadCurve(to: CGPoint(x: 0, y: radius),
                          control: CGPoint(x: radius * 0.62, y: radius * 0.5))
        path.addQuadCurve(to: .zero,
                          control: CGPoint(x: -radius * 0.62, y: radius * 0.5))
        path.closeSubpath()
        return path
    }

    /// Yaprakların açılma eylemi.
    ///
    /// Azaltılmış hareket açıkken yay yerine tek kareli çapraz geçiş (§1.7).
    public static func openAction(presentation: BoardPresentation) -> SKAction {
        guard !presentation.reduceMotion else {
            return .fadeIn(withDuration: presentation.duration(Motion.bloom))
        }
        let duration = presentation.duration(Motion.bloom)
        let overshoot = SKAction.scale(to: 1.12, duration: duration * 0.55)
        overshoot.timingMode = .easeOut
        let settle = SKAction.scale(to: 1.0, duration: duration * 0.45)
        settle.timingMode = .easeInEaseOut
        return .sequence([overshoot, settle])
    }

    /// Polen tozu — `SKEmitterNode` yerine hafif parçacıklar, çünkü tek bir
    /// `.sks` dosyası bile "elle çizilmiş asset yok" kuralına takılıyor ve
    /// parçacıklar da parametrik üretiliyor.
    public static func dustBurst(radius: CGFloat, color: RGB,
                                 presentation: BoardPresentation) -> SKNode {
        let container = SKNode()
        let count = presentation.particleCount(particleCount)
        guard count > 0 else { return container }
        for index in 0..<count {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 1...2.5))
            particle.fillColor = SKColor(color.opacity(0.9))
            particle.strokeColor = .clear
            let angle = CGFloat(index) / CGFloat(count) * .pi * 2
            let distance = radius * CGFloat.random(in: 1.2...2.4)
            let target = CGPoint(x: cos(angle) * distance, y: sin(angle) * distance)
            particle.run(.sequence([
                .group([
                    .move(to: target, duration: particleLifetime),
                    .fadeOut(withDuration: particleLifetime),
                    .scale(to: 0.2, duration: particleLifetime),
                ]),
                .removeFromParent(),
            ]))
            container.addChild(particle)
        }
        container.run(.sequence([.wait(forDuration: particleLifetime), .removeFromParent()]))
        return container
    }

    /// Kabın levha şeridine uçuşu (§2.5 adım 4).
    public static func flyToPlateAction(destination: CGPoint,
                                        presentation: BoardPresentation) -> SKAction {
        let duration = presentation.duration(flightToPlate)
        let move = SKAction.move(to: destination, duration: duration)
        move.timingMode = .easeInEaseOut
        return .group([move,
                       .scale(to: 0.3, duration: duration),
                       .fadeAlpha(to: 0.0, duration: duration)])
    }
}
#endif
