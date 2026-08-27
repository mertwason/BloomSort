#if canImport(UIKit) && !os(watchOS)
import UIKit

/// Gerçek haptik motoru — `docs/ui-spec.md` §1.8 haritası.
///
/// Sesten **bağımsız** kapatılabilir (`CLAUDE.md`).
@MainActor
public final class HapticEngine: HapticEngineProtocol {
    public var isEnabled = true

    private let soft = UIImpactFeedbackGenerator(style: .soft)
    private let light = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()

    public init() {
        [soft, light, medium, rigid].forEach { $0.prepare() }
        notification.prepare()
        selection.prepare()
    }

    public func play(_ haptic: HapticKind) {
        guard isEnabled else { return }
        switch haptic {
        case .vesselSelected: soft.impactOccurred(intensity: 0.4)
        case .beadLanded:     light.impactOccurred(intensity: 0.6)
        case .bloomed:        medium.impactOccurred(intensity: 0.8)
        case .platePressed:   rigid.impactOccurred(intensity: 1.0)
        case .invalidMove:    notification.notificationOccurred(.warning)
        case .levelComplete:  notification.notificationOccurred(.success)
        case .button:         selection.selectionChanged()
        }
    }
}
#endif
