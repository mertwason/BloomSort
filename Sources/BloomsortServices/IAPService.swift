import Foundation

/// Satın alma sonucu.
public enum PurchaseOutcome: Sendable, Equatable {
    case purchased(StoreProduct)
    /// Oyuncu vazgeçti — ücret alınmadı.
    case cancelled
    /// Beklemede (aile onayı vb.).
    case pending
    /// Başarısız. Mesaj `docs/ui-spec.md` §6'daki metin.
    case failed(String)
}

/// Satın alma servisinin sözleşmesi.
///
/// "Satın almaları geri yükle" olmadan gönderim **kesin red** (lansman
/// checklist'i Faz 5), o yüzden protokolde zorunlu.
public protocol IAPServiceProtocol: AnyObject {
    /// "Reklamsız" hakkı var mı?
    var hasRemoveAds: Bool { get }
    /// Mağazada gösterilecek ürünler, fiyatlarıyla.
    func loadProducts() async -> [StoreProduct: String]
    func purchase(_ product: StoreProduct) async -> PurchaseOutcome
    /// Satın almaları geri yükler.
    @discardableResult
    func restorePurchases() async -> Bool
    /// `Transaction.updates` dinleyicisini başlatır.
    func startTransactionListener()
}

/// Kullanıcıya gösterilecek metinler (`docs/ui-spec.md` §6).
///
/// "Asla özür dileme, asla belirsiz olma."
public enum StoreMessage {
    public static let purchaseFailed = "Satın alma tamamlanmadı. Ücret alınmadı."
    public static let restoreEmpty = "Bu Apple Kimliği'nde geri yüklenecek satın alma yok."
    public static let offline = "Çevrimdışısın. Oynamaya devam edebilirsin; ilerlemen cihazında saklanıyor."
}

/// Testlerde ve önizlemelerde kullanılan sahte mağaza.
public final class FakeIAPService: IAPServiceProtocol, @unchecked Sendable {
    public private(set) var purchased: Set<StoreProduct> = []
    public var nextOutcome: PurchaseOutcome?
    public private(set) var restoreCallCount = 0
    public private(set) var listenerStarted = false

    public init() {}

    public var hasRemoveAds: Bool {
        purchased.contains { $0.grantsRemoveAds }
    }

    public func loadProducts() async -> [StoreProduct: String] {
        Dictionary(uniqueKeysWithValues: StoreProduct.allCases.map { ($0, "₺--") })
    }

    public func purchase(_ product: StoreProduct) async -> PurchaseOutcome {
        if let nextOutcome {
            self.nextOutcome = nil
            if case .purchased = nextOutcome { purchased.insert(product) }
            return nextOutcome
        }
        purchased.insert(product)
        return .purchased(product)
    }

    @discardableResult
    public func restorePurchases() async -> Bool {
        restoreCallCount += 1
        return !purchased.isEmpty
    }

    public func startTransactionListener() { listenerStarted = true }
}
