#if canImport(SwiftUI)
import BloomsortDesign
import BloomsortDomain
import BloomsortServices
import SwiftUI

/// Kök görünüm — 4 sekmeli TabView (`docs/ui-spec.md` §3.0).
public struct RootView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var tab: AppTab = .path

    public init() {}

    public var body: some View {
        TabView(selection: $tab) {
            ForEach(AppTab.allCases) { item in
                tabContent(item)
                    .tabItem {
                        Label(item.title, systemImage: item.systemImage)
                    }
                    .tag(item)
            }
        }
        .tint(Theme.pollen)
        .background(Theme.dusk)
        .task { await startSession() }
    }

    @ViewBuilder
    private func tabContent(_ item: AppTab) -> some View {
        VStack(spacing: 0) {
            switch item {
            case .path: PathView()
            case .herbarium: HerbariumView()
            case .garden: GardenView()
            case .hive: HiveView()
            }
            // Banner yalnızca meta ekranlarda; boş alan bırakılmıyor —
            // reklam yoksa şerit hiç çizilmiyor (Faz 4.2).
            if environment.ads.shouldShowBanner(on: item.adSurface) {
                BannerSlot(surface: item.adSurface)
            }
        }
        .background(Theme.dusk)
    }

    private func startSession() async {
        environment.beginSession()
        // Rıza: her açılışta bilgi tazelenir, gerekiyorsa form gösterilir.
        await environment.consent.requestConsentInfoUpdate()
        environment.store.startTransactionListener()
        if environment.settings.soundEnabled { environment.audio.startAmbience() }
    }
}

/// Adaptive banner yuvası (§2.10). Reklam gelmezse yüksekliği sıfır.
struct BannerSlot: View {
    @Environment(AppEnvironment.self) private var environment
    let surface: AdSurface

    var body: some View {
        // Gerçek banner görünümü Xcode projesinde GADBannerView ile bağlanır;
        // burada yalnızca yer ayrılıyor ve reklam yoksa hiç çizilmiyor.
        Color.clear.frame(height: 0)
            .accessibilityHidden(true)
    }
}

/// Patika (§3.3) — dikey kaydırılan çayır patikası.
public struct PathView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var selectedLevel: Level?
    @State private var playingLevel: Level?
    @State private var showsSettings = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(environment.levels.reversed()) { level in
                            levelNode(level).id(level.id)
                            if Herbarium.completesAlbum(level: level.id) {
                                albumDivider(level.id)
                            }
                        }
                    }
                    .padding(.vertical, Spacing.s6)
                }
                .onAppear { proxy.scrollTo(environment.progress.currentLevel, anchor: .center) }
            }
            .background(Theme.dusk)
            .safeAreaInset(edge: .top) { topBar }
            .sheet(item: $selectedLevel) { level in
                LevelCardSheet(level: level) {
                    selectedLevel = nil
                    playingLevel = level
                }
                .presentationDetents([.height(380)])
            }
            .fullScreenCover(item: $playingLevel) { level in
                GameView(level: level, environment: environment) { stars, moves in
                    finish(level: level, stars: stars, moves: moves)
                }
            }
            .sheet(isPresented: $showsSettings) { SettingsView() }
        }
    }

    private var topBar: some View {
        HStack {
            Label("\(environment.progress.seeds)", systemImage: "leaf.fill")
                .foregroundStyle(Theme.pollen)
            Label("\(environment.progress.bees)", systemImage: "ant.fill")
                .foregroundStyle(Theme.mist)
            Spacer()
            Button { showsSettings = true } label: {
                Image(systemName: "gearshape")
                    .frame(width: Layout.minimumTapTarget, height: Layout.minimumTapTarget)
            }
            .foregroundStyle(Theme.mist)
            .accessibilityLabel("Ayarlar")
        }
        .textStyle(Typography.body)
        .padding(.horizontal, Spacing.screenMargin)
        .frame(height: 44)
        .background(Theme.dusk.opacity(0.92))
    }

    private func levelNode(_ level: Level) -> some View {
        let completed = environment.progress.isCompleted(level.id)
        let current = level.id == environment.progress.currentLevel
        let unlocked = environment.progress.isUnlocked(level.id)
        return Button {
            guard unlocked else { return }
            // İlk kez oynanan seviyede sheet atlanır (§3.4).
            if completed { selectedLevel = level } else { playingLevel = level }
        } label: {
            VStack(spacing: Spacing.s1) {
                ZStack {
                    Circle()
                        .fill(current ? Theme.pollen : (completed ? Theme.dew : Theme.mossHigh))
                        .frame(width: current ? 76 : 56, height: current ? 76 : 56)
                        .opacity(unlocked ? 1 : 0.4)
                    Text("\(level.id)")
                        .textStyle(Typography.title)
                        .foregroundStyle(current ? Theme.dusk : Theme.mist)
                }
                if completed {
                    HStack(spacing: 2) {
                        ForEach(0..<3, id: \.self) { index in
                            Image(systemName: index < (environment.progress.stars[level.id] ?? 0)
                                  ? "star.fill" : "star")
                                .font(.system(size: 10))
                                .foregroundStyle(Theme.pollen)
                        }
                    }
                }
            }
            // Patika zikzağı: x ekseninde ±64 pt salınım, düğüm aralığı 96 pt.
            .offset(x: level.id.isMultiple(of: 2) ? -64 : 64)
            .frame(height: 96)
        }
        .disabled(!unlocked)
        .accessibilityLabel(accessibilityLabel(level: level, completed: completed, unlocked: unlocked))
    }

    private func accessibilityLabel(level: Level, completed: Bool, unlocked: Bool) -> String {
        guard unlocked else { return "Seviye \(level.id), kilitli" }
        guard completed else { return "Seviye \(level.id), oynanabilir" }
        return "Seviye \(level.id), \(environment.progress.stars[level.id] ?? 0) yıldız"
    }

    private func albumDivider(_ level: Int) -> some View {
        let album = Herbarium.albumIndex(forLevel: level)
        return HStack {
            Rectangle().fill(Theme.mossHigh).frame(height: 1)
            Text("ALBÜM: \(Herbarium.albumName(album).uppercased())")
                .textStyle(Typography.micro)
                .foregroundStyle(Theme.mistDim)
            Rectangle().fill(Theme.mossHigh).frame(height: 1)
        }
        .padding(.horizontal, Spacing.screenMargin)
        .padding(.vertical, Spacing.s4)
    }

    private func finish(level: Level, stars: Int, moves: Int) {
        environment.progress.complete(level: level.id, stars: stars, moves: moves)
        environment.analytics.log(.plateCollect(
            plateID: level.id,
            albumID: Herbarium.albumIndex(forLevel: level.id),
            albumPercent: Double(Herbarium.plateIndexInAlbum(forLevel: level.id) + 1)
                / Double(Herbarium.platesPerAlbum)))
        playingLevel = nil
        Task { await maybeShowInterstitial(after: level, stars: stars) }
    }

    /// §6.2: interstitial yalnızca burada, 8 kural birden sağlanırsa.
    private func maybeShowInterstitial(after level: Level, stars: Int) async {
        let context = environment.interstitialContext(level: level.id, stars: stars)
        guard environment.ads.canShowInterstitial(context: context) else {
            environment.recordLevelWithoutInterstitial()
            return
        }
        if await environment.ads.showInterstitial() {
            environment.recordInterstitial()
            environment.analytics.log(.adImpression(unit: "interstitial_level_end",
                                                    placementID: "level_end",
                                                    levelID: level.id,
                                                    ecpmBucket: "unknown"))
        } else {
            environment.recordLevelWithoutInterstitial()
        }
    }
}

/// Seviye kartı sheet'i (§3.4). Yalnızca tamamlanmış seviyeye dönülünce açılır.
public struct LevelCardSheet: View {
    @Environment(AppEnvironment.self) private var environment
    let level: Level
    let onPlay: () -> Void

    public init(level: Level, onPlay: @escaping () -> Void) {
        self.level = level
        self.onPlay = onPlay
    }

    public var body: some View {
        SheetContainer {
            VStack(spacing: Spacing.s4) {
                RoundedRectangle(cornerRadius: Radius.medium)
                    .fill(Theme.platePaper)
                    .frame(width: 120, height: 120)
                Text("Seviye \(level.id)")
                    .textStyle(Typography.displayL)
                    .foregroundStyle(Theme.mist)
                Text("\(environment.naming.name(forLevel: level.id)) · \(Herbarium.albumName(Herbarium.albumIndex(forLevel: level.id)))")
                    .textStyle(Typography.caption)
                    .foregroundStyle(Theme.mistDim)
                HStack(spacing: Spacing.s4) {
                    HStack(spacing: 2) {
                        ForEach(0..<3, id: \.self) { index in
                            Image(systemName: index < (environment.progress.stars[level.id] ?? 0)
                                  ? "star.fill" : "star")
                                .foregroundStyle(Theme.pollen)
                        }
                    }
                    if let best = environment.progress.bestMoves[level.id] {
                        Text("En iyi: \(best) hamle")
                            .textStyle(Typography.caption)
                            .foregroundStyle(Theme.mistDim)
                    }
                }
                BloomButton("Oyna", variant: .primary, action: onPlay)
            }
            .padding(.horizontal, Spacing.screenMargin)
            .padding(.bottom, Spacing.s6)
        }
    }
}
#endif
