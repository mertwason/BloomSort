#if canImport(SwiftUI)
import BloomsortDesign
import BloomsortDomain
import BloomsortServices
import SwiftUI

/// Herbaryum (`docs/ui-spec.md` §3.8) — 3 sütun, 103 × 138 levha kartları.
public struct HerbariumView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var selectedAlbum = 0

    public init() {}

    private var albumCount: Int {
        guard let last = environment.levels.last else { return 1 }
        return Herbarium.albumIndex(forLevel: last.id) + 1
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                albumTabs
                if environment.progress.collectedPlates == 0 {
                    EmptyStateView(message: "Henüz levha yok. İlk seviyeyi bitir, ilki preslensin.",
                                   actionTitle: "Patika'ya git") {}
                } else {
                    plateGrid
                }
            }
            .background(Theme.dusk)
            .navigationTitle("Herbaryum")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Text("\(environment.progress.collectedPlates) / \(environment.levels.count)")
                        .textStyle(Typography.caption)
                        .foregroundStyle(Theme.mistDim)
                }
            }
        }
    }

    private var albumTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.s2) {
                ForEach(0..<albumCount, id: \.self) { index in
                    Button {
                        selectedAlbum = index
                    } label: {
                        Text(Herbarium.albumName(index))
                            .textStyle(Typography.caption)
                            .padding(.horizontal, Spacing.s3)
                            .frame(height: 40)
                            .background(selectedAlbum == index ? Theme.mossHigh : Theme.moss,
                                        in: Capsule())
                            .foregroundStyle(selectedAlbum == index ? Theme.mist : Theme.mistDim)
                    }
                }
            }
            .padding(.horizontal, Spacing.screenMargin)
        }
        .frame(height: 40)
    }

    private var plateGrid: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.s3),
                                     count: 3),
                      spacing: Spacing.s3) {
                ForEach(albumLevels, id: \.self) { levelID in
                    plateCard(levelID)
                }
            }
            .padding(Spacing.screenMargin)
        }
    }

    private var albumLevels: [Int] {
        let start = selectedAlbum * Herbarium.platesPerAlbum + 1
        let end = min(start + Herbarium.platesPerAlbum - 1, environment.levels.count)
        guard start <= end else { return [] }
        return Array(start...end)
    }

    private func plateCard(_ levelID: Int) -> some View {
        let unlocked = environment.progress.isCompleted(levelID)
        return VStack(spacing: Spacing.s2) {
            if unlocked {
                Circle()
                    .fill(Theme.pollenColor(levelID % 12))
                    .frame(width: 86, height: 86)
                Text(environment.naming.name(forLevel: levelID))
                    .textStyle(Typography.caption)
                    .italic()
                    .foregroundStyle(Theme.plateInk)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            } else {
                Text("?").textStyle(Typography.displayM).foregroundStyle(Theme.mistDim)
                Text("\(levelID)").textStyle(Typography.micro).foregroundStyle(Theme.mistDim)
            }
        }
        .frame(width: 103, height: 138)
        .background(unlocked ? Theme.platePaper : Color(Palette.moss.opacity(0.4)),
                    in: RoundedRectangle(cornerRadius: Radius.small))
        .accessibilityLabel(unlocked
            ? "\(environment.naming.name(forLevel: levelID)), seviye \(levelID)"
            : "Kilitli levha, seviye \(levelID)")
    }
}

/// Bahçem (§3.9) — MVP'de yalnızca boş durum ve albüm ödülü sayacı.
public struct GardenView: View {
    @Environment(AppEnvironment.self) private var environment
    public init() {}

    private var plantCount: Int {
        environment.progress.completedLevels / Herbarium.platesPerAlbum
    }

    public var body: some View {
        NavigationStack {
            Group {
                if plantCount == 0 {
                    EmptyStateView(message: "Bir albüm tamamla, bahçene ilk bitkin dikilsin.",
                                   actionTitle: "Herbaryum'a git") {}
                } else {
                    VStack(spacing: Spacing.s4) {
                        Text("\(plantCount) bitki")
                            .textStyle(Typography.displayM)
                            .foregroundStyle(Theme.mist)
                        Text("Bahçem'in etkileşimli modu v1.1'de.")
                            .textStyle(Typography.caption)
                            .foregroundStyle(Theme.mistDim)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.dusk)
            .navigationTitle("Bahçem")
        }
    }
}

/// Kovan / Mağaza (§3.10).
public struct HiveView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var prices: [StoreProduct: String] = [:]
    @State private var toast: Toast?
    @State private var busy: StoreProduct?

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.s4) {
                    removeAdsCard
                    ForEach([StoreProduct.bees10, .bees60, .bees200], id: \.self) { product in
                        productRow(product)
                    }
                    // "Satın almaları geri yükle" olmadan gönderim kesin red.
                    BloomButton("Satın almaları geri yükle", variant: .ghost) {
                        Task { await restore() }
                    }
                }
                .padding(Spacing.screenMargin)
            }
            .background(Theme.dusk)
            .navigationTitle("Kovan")
        }
        .toast($toast)
        .task { prices = await environment.store.loadProducts() }
    }

    private var removeAdsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text("Reklamsız").textStyle(Typography.title).foregroundStyle(Theme.mist)
            Text("Interstitial ve banner reklamlar kapanır. Ödüllü videoların verdiği her şey tek dokunuşla ücretsiz gelir.")
                .textStyle(Typography.caption)
                .foregroundStyle(Theme.mistDim)
            if environment.progress.hasRemoveAds {
                Text("Satın alındı").textStyle(Typography.caption).foregroundStyle(Theme.dew)
            } else {
                BloomButton(prices[.removeAds] ?? "—", variant: .primary,
                            isLoading: busy == .removeAds) {
                    Task { await buy(.removeAds) }
                }
            }
        }
        .padding(Spacing.s4)
        .frame(minHeight: 132)
        .background(Theme.moss, in: RoundedRectangle(cornerRadius: Radius.large))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.large)
                .strokeBorder(Theme.pollen, lineWidth: 2)
        }
    }

    private func productRow(_ product: StoreProduct) -> some View {
        HStack {
            Label("\(product.beeGrant) arı", systemImage: "ant.fill")
                .textStyle(Typography.body)
                .foregroundStyle(Theme.mist)
            Spacer()
            BloomButton(prices[product] ?? "—", variant: .secondary, isLoading: busy == product) {
                Task { await buy(product) }
            }
            .frame(width: 120)
        }
        .padding(Spacing.s3)
        .background(Theme.moss, in: RoundedRectangle(cornerRadius: Radius.medium))
    }

    private func buy(_ product: StoreProduct) async {
        busy = product
        defer { busy = nil }
        switch await environment.store.purchase(product) {
        case .purchased(let bought):
            if bought.grantsRemoveAds { environment.progress.setRemoveAds(true) }
            if bought.beeGrant > 0 { environment.progress.grantBees(bought.beeGrant) }
            environment.analytics.log(.iapPurchase(productID: bought.rawValue,
                                                   priceLocal: 0, currency: "TRY"))
        case .cancelled:
            break
        case .pending:
            toast = Toast("Satın alma onay bekliyor.")
        case .failed(let message):
            toast = Toast(message, isError: true)
        }
    }

    private func restore() async {
        let restored = await environment.store.restorePurchases()
        if restored {
            environment.progress.setRemoveAds(environment.store.hasRemoveAds)
            toast = Toast("Satın almaların geri yüklendi.")
        } else {
            toast = Toast(StoreMessage.restoreEmpty)
        }
    }
}

/// Ayarlar (§3.12).
public struct SettingsView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.dismiss) private var dismiss
    @State private var confirmingReset = false

    public init() {}

    public var body: some View {
        @Bindable var environment = environment
        NavigationStack {
            Form {
                Section("Oyun") {
                    Toggle("Ses", isOn: $environment.settings.soundEnabled)
                    Toggle("Müzik", isOn: $environment.settings.musicEnabled)
                    Toggle("Haptik", isOn: $environment.settings.hapticsEnabled)
                    Toggle("Azaltılmış hareket", isOn: $environment.settings.reduceMotion)
                    Toggle("Renk körlüğü modu", isOn: $environment.settings.colorBlindMode)
                }
                Section("Hesap") {
                    Button("Satın almaları geri yükle") {
                        Task { _ = await environment.store.restorePurchases() }
                    }
                    Button("İlerlemeyi sıfırla", role: .destructive) { confirmingReset = true }
                }
                Section("Gizlilik") {
                    Button("Reklam tercihlerini yönet") {
                        Task { await environment.consent.presentPrivacyOptions() }
                    }
                    Link("Gizlilik politikası", destination: URL(string: "https://bloomsort.app/gizlilik")!)
                    Link("Kullanım koşulları", destination: URL(string: "https://bloomsort.app/kosullar")!)
                }
                Section("Hakkında") {
                    LabeledContent("Sürüm", value: Bundle.main
                        .object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—")
                    Link("İletişim", destination: URL(string: "mailto:support@bloomsort.app")!)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.dusk)
            .tint(Theme.pollen)
            .navigationTitle("Ayarlar")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
            .alert("İlerlemeyi sıfırla", isPresented: $confirmingReset) {
                Button("Vazgeç", role: .cancel) {}
                Button("Sıfırla", role: .destructive) {
                    environment.progress = Progress()
                }
            } message: {
                Text("Bütün seviyeler, levhalar ve tohumlar silinir. Geri alınamaz.")
            }
        }
        .onChange(of: environment.settings) { _, new in new.save() }
    }
}
#endif
