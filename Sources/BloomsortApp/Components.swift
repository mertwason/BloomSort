#if canImport(SwiftUI)
import BloomsortDesign
import SwiftUI

/// Buton varyantları (`docs/ui-spec.md` §2.1).
public enum ButtonVariant {
    case primary, secondary, ghost, destructive, rewarded
}

/// Ortak buton. Dokunma alanı her zaman ≥ 44 × 44 pt.
public struct BloomButton: View {
    let title: String
    let variant: ButtonVariant
    var isLoading: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void

    public init(_ title: String, variant: ButtonVariant = .primary,
                isLoading: Bool = false, isEnabled: Bool = true,
                action: @escaping () -> Void) {
        self.title = title
        self.variant = variant
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.s2) {
                if variant == .rewarded {
                    Image(systemName: "play.fill").font(.system(size: 18))
                }
                if isLoading {
                    LoadingDots()
                } else {
                    Text(title).textStyle(Typography.bodyStrong)
                }
            }
            .frame(maxWidth: .infinity, minHeight: height)
            .padding(.horizontal, horizontalPadding)
            .background(background)
            .overlay(border)
            .foregroundStyle(foreground)
            .clipShape(Capsule())
        }
        .buttonStyle(PressedScaleStyle())
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1 : 0.38)
        .frame(minHeight: Layout.minimumTapTarget)
    }

    private var height: CGFloat { variant == .ghost ? 48 : 56 }
    private var horizontalPadding: CGFloat { variant == .ghost ? 20 : 24 }

    @ViewBuilder private var background: some View {
        switch variant {
        case .primary: Theme.pollen
        case .secondary, .rewarded: Theme.moss
        case .ghost, .destructive: Color.clear
        }
    }

    @ViewBuilder private var border: some View {
        switch variant {
        case .secondary: Capsule().strokeBorder(Theme.mossHigh, lineWidth: 1.5)
        case .destructive: Capsule().strokeBorder(Theme.ember, lineWidth: 1.5)
        case .rewarded: Capsule().strokeBorder(Theme.pollen, lineWidth: 1.5)
        default: EmptyView()
        }
    }

    private var foreground: Color {
        switch variant {
        case .primary: return Theme.dusk
        case .secondary: return Theme.mist
        case .ghost: return Theme.mistDim
        case .destructive: return Theme.ember
        case .rewarded: return Theme.pollen
        }
    }
}

/// Basılı hâl: `scale 0.96`, 90 ms (§2.1).
struct PressedScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: Motion.tap), value: configuration.isPressed)
    }
}

/// Yükleniyor: metin yerine 3 noktalı polen animasyonu (§2.1).
struct LoadingDots: View {
    @State private var phase = 0.0
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Theme.dusk)
                    .frame(width: 6, height: 6)
                    .opacity(0.4 + 0.6 * abs(sin(phase + Double(index) * 0.6)))
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 80_000_000)
                phase += 0.35
            }
        }
    }
}

/// Sayaç pill'i — HUD'daki arı ve geri al (§2.4).
public struct CounterPill: View {
    let systemImage: String
    let value: Int
    /// Sayaç 0 iken ödüllü varyantına döner: sağında küçük ▶ rozeti.
    var showsRewardedBadge: Bool { value == 0 }

    public init(systemImage: String, value: Int) {
        self.systemImage = systemImage
        self.value = value
    }

    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage).font(.system(size: 16))
            Text("\(value)").textStyle(Typography.bodyStrong)
            if showsRewardedBadge {
                Image(systemName: "play.fill").font(.system(size: 9))
            }
        }
        .foregroundStyle(showsRewardedBadge ? Theme.pollen : Theme.mist)
        .padding(.horizontal, Spacing.s3)
        .frame(height: 32)
        .background(Theme.moss.opacity(0.7), in: Capsule())
        .frame(minWidth: Layout.minimumTapTarget, minHeight: Layout.minimumTapTarget)
    }
}

/// Toast (§2.8): üstten iner, 2,4 sn kalır, çıkar. Aynı anda en fazla 1.
public struct Toast: Equatable, Identifiable {
    public let id = UUID()
    public let message: String
    public var isError: Bool

    public init(_ message: String, isError: Bool = false) {
        self.message = message
        self.isError = isError
    }

    public static func == (lhs: Toast, rhs: Toast) -> Bool { lhs.id == rhs.id }
}

public struct ToastView: View {
    let toast: Toast
    public init(toast: Toast) { self.toast = toast }

    public var body: some View {
        Text(toast.message)
            .textStyle(Typography.caption)
            .foregroundStyle(Theme.mist)
            .padding(.horizontal, Spacing.s4)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .background(toast.isError ? Theme.ember.opacity(0.25) : Theme.mossHigh,
                        in: RoundedRectangle(cornerRadius: Radius.medium))
            .padding(.horizontal, Spacing.screenMargin)
            .shadow(color: .black.opacity(0.45), radius: 24, y: 8)
    }
}

public extension View {
    /// Ekranın üstünde tek toast gösterir.
    func toast(_ toast: Binding<Toast?>) -> some View {
        overlay(alignment: .top) {
            if let value = toast.wrappedValue {
                ToastView(toast: value)
                    .padding(.top, Spacing.s3)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .task(id: value.id) {
                        try? await Task.sleep(nanoseconds: 2_400_000_000)
                        withAnimation { toast.wrappedValue = nil }
                    }
            }
        }
        .animation(.spring(response: Motion.sheet, dampingFraction: 0.86),
                   value: toast.wrappedValue)
    }
}

/// Sheet gövdesi (§2.7): `--moss` zemin, üst yarıçap 32, 36 × 4 tutamak.
public struct SheetContainer<Content: View>: View {
    let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }

    public var body: some View {
        VStack(spacing: Spacing.s4) {
            Capsule()
                .fill(Theme.mistDim.opacity(0.4))
                .frame(width: 36, height: 4)
                .padding(.top, Spacing.s3)
            content
        }
        .frame(maxWidth: .infinity)
        .background(Theme.moss)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: Radius.extraLarge,
                                          topTrailingRadius: Radius.extraLarge))
    }
}

/// Boş durum (§6): başlık + tek eylem.
public struct EmptyStateView: View {
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    public init(message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: Spacing.s5) {
            Text(message)
                .textStyle(Typography.body)
                .foregroundStyle(Theme.mistDim)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                BloomButton(actionTitle, variant: .ghost, action: action)
            }
        }
        .padding(Spacing.s6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
#endif
