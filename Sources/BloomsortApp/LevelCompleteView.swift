#if canImport(SwiftUI)
import BloomsortDesign
import BloomsortDomain
import BloomsortServices
import SwiftUI

/// Seviye tamam ekranı (`docs/ui-spec.md` §3.7).
///
/// Sekans (toplam 2,6 sn, dokunulunca atlanır): levha presi → yıldızlar →
/// tohum sayacı → butonlar.
public struct LevelCompleteView: View {
    @Environment(AppEnvironment.self) private var environment
    let level: Level
    let stars: Int
    let moves: Int
    let onNext: () -> Void

    @State private var step = 0
    @State private var seedsShown = 0
    @State private var doubledReward = false

    public init(level: Level, stars: Int, moves: Int, onNext: @escaping () -> Void) {
        self.level = level
        self.stars = stars
        self.moves = moves
        self.onNext = onNext
    }

    private var speciesName: String { environment.naming.name(forLevel: level.id) }
    private var reward: Int {
        Economy.seedReward(stars: stars, streakDays: environment.progress.streakDays)
    }

    public var body: some View {
        ZStack {
            Theme.duskDeep.ignoresSafeArea()
            VStack(spacing: Spacing.s5) {
                Spacer()
                plate
                Text(speciesName)
                    .textStyle(Typography.displayM)
                    .foregroundStyle(Theme.mist)
                    .italic()
                starRow
                HStack(spacing: Spacing.s5) {
                    Label("\(seedsShown)", systemImage: "leaf.fill")
                        .textStyle(Typography.numericL)
                        .foregroundStyle(Theme.pollen)
                    Text("\(moves)/\(level.optimalMoves) hamle")
                        .textStyle(Typography.numericL)
                        .foregroundStyle(Theme.mistDim)
                }
                albumProgress
                Spacer()
                buttons
            }
            .padding(.horizontal, Spacing.screenMargin)
        }
        .contentShape(Rectangle())
        .onTapGesture { skipToEnd() }
        .task { await runSequence() }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Seviye \(level.id) tamamlandı, \(stars) yıldız, \(moves) hamle")
    }

    /// Levha 200 × 260, kâğıt `#EDE8DC`, hafif −1,5° rotasyon.
    private var plate: some View {
        RoundedRectangle(cornerRadius: Radius.medium)
            .fill(Theme.platePaper)
            .frame(width: 200, height: 260)
            .overlay {
                VStack {
                    Circle()
                        .fill(Theme.pollenColor(level.id % 12))
                        .frame(width: 96, height: 96)
                        .padding(.top, Spacing.s6)
                    Spacer()
                    Text(speciesName)
                        .textStyle(Typography.caption)
                        .foregroundStyle(Theme.plateInk)
                        .italic()
                        .padding(.bottom, Spacing.s4)
                }
            }
            .rotationEffect(.degrees(-1.5))
            .scaleEffect(step >= 1 ? 1 : 0.6)
            .opacity(step >= 1 ? 1 : 0)
            .shadow(color: .black.opacity(0.45), radius: 24, y: 8)
    }

    private var starRow: some View {
        HStack(spacing: Spacing.s3) {
            ForEach(0..<3, id: \.self) { index in
                Image(systemName: index < stars ? "star.fill" : "star")
                    .font(.system(size: 32))
                    .foregroundStyle(index < stars ? Theme.pollen : Theme.mistDim.opacity(0.4))
                    .scaleEffect(step >= 2 + index ? 1 : 0.2)
                    .opacity(step >= 2 + index ? 1 : 0)
            }
        }
    }

    private var albumProgress: some View {
        VStack(spacing: Spacing.s2) {
            Text(Herbarium.progressLabel(forLevel: level.id).uppercased())
                .textStyle(Typography.micro)
                .foregroundStyle(Theme.mistDim)
            ProgressView(value: Double(Herbarium.plateIndexInAlbum(forLevel: level.id) + 1),
                         total: Double(Herbarium.platesPerAlbum))
                .tint(Theme.pollen)
                .frame(height: 6)
        }
    }

    private var buttons: some View {
        VStack(spacing: Spacing.s3) {
            // R4: ödülü ikiye katla (§6.1). Reklamsız oyuncuya tek dokunuşla
            // ücretsiz verilir (§6.7).
            if !doubledReward {
                BloomButton("Ödülü ikiye katla", variant: .rewarded) { doubleReward() }
            }
            BloomButton("Sıradaki seviye", variant: .primary, action: onNext)
            BloomButton("Herbaryum'a bak", variant: .ghost) { onNext() }
        }
        .opacity(step >= 6 ? 1 : 0)
        .offset(y: step >= 6 ? 0 : 40)
        .padding(.bottom, Spacing.s6)
    }

    private func doubleReward() {
        doubledReward = true
        Task {
            let outcome = await environment.ads.showRewarded(.doubleReward)
            if outcome == .watched || outcome == .grantedWithoutAd {
                environment.recordRewarded()
                environment.progress.grantSeeds(reward)
                seedsShown += reward
                environment.analytics.log(.adRewardGrant(
                    placementID: RewardedPlacement.doubleReward.rawValue,
                    fallback: outcome == .grantedWithoutAd))
            }
        }
    }

    /// §3.7'deki zaman çizelgesi.
    private func runSequence() async {
        let motion = environment.settings.reduceMotion
        func wait(_ seconds: Double) async {
            let scaled = Motion.duration(seconds, reduceMotion: motion)
            try? await Task.sleep(nanoseconds: UInt64(scaled * 1_000_000_000))
        }
        await wait(0.3)
        step = 1                          // levha presi
        environment.play(.platePressed)
        await wait(Motion.plate)
        for index in 0..<stars {          // yıldızlar 180 ms arayla
            step = 2 + index
            environment.play(.beadLanded)
            await wait(0.18)
        }
        step = 5
        // Tohum sayacı 600 ms yukarı sayar.
        let total = reward
        for value in stride(from: 0, through: total, by: max(1, total / 12)) {
            seedsShown = value
            await wait(0.05)
        }
        seedsShown = total
        step = 6
    }

    private func skipToEnd() {
        step = 6
        seedsShown = reward
    }
}

/// Duraklat sheet'i (§3.6).
public struct PauseSheet: View {
    @Environment(AppEnvironment.self) private var environment
    let onResume: () -> Void
    let onRestart: () -> Void
    let onExit: () -> Void

    public init(onResume: @escaping () -> Void, onRestart: @escaping () -> Void,
                onExit: @escaping () -> Void) {
        self.onResume = onResume
        self.onRestart = onRestart
        self.onExit = onExit
    }

    public var body: some View {
        @Bindable var environment = environment
        SheetContainer {
            VStack(spacing: Spacing.s4) {
                Text("Ara").textStyle(Typography.displayM).foregroundStyle(Theme.mist)
                Toggle("Ses", isOn: $environment.settings.soundEnabled)
                Toggle("Haptik", isOn: $environment.settings.hapticsEnabled)
                Toggle("Renk körlüğü", isOn: $environment.settings.colorBlindMode)
                Toggle("Azaltılmış hareket", isOn: $environment.settings.reduceMotion)
                BloomButton("Devam", variant: .primary, action: onResume)
                BloomButton("Seviyeye baştan başla", variant: .secondary, action: onRestart)
                BloomButton("Patikaya dön", variant: .ghost, action: onExit)
            }
            .tint(Theme.pollen)
            .foregroundStyle(Theme.mist)
            .padding(.horizontal, Spacing.screenMargin)
            .padding(.bottom, Spacing.s6)
        }
        .onChange(of: environment.settings) { _, new in new.save() }
    }
}
#endif
