#if canImport(StoreKit)
import Foundation
import StoreKit

/// StoreKit 2 satın alma servisi (`docs/gdd.md` §8.4).
///
/// Sunucu doğrulaması MVP'de yok; `Transaction.updates` dinleniyor ve
/// "Reklamsız" durumu `currentEntitlements` üzerinden okunuyor.
@available(iOS 15.0, macOS 12.0, *)
public final class StoreKitIAPService: IAPServiceProtocol, @unchecked Sendable {
    public private(set) var hasRemoveAds = false
    /// Tüketilebilir satın alma tamamlandığında çağrılır (arı paketleri).
    public var onConsumableGranted: ((StoreProduct) -> Void)?
    /// "Reklamsız" durumu değiştiğinde çağrılır.
    public var onEntitlementsChanged: ((Bool) -> Void)?

    private var products: [String: Product] = [:]
    private var updatesTask: Task<Void, Never>?

    public init() {}

    deinit { updatesTask?.cancel() }

    public func loadProducts() async -> [StoreProduct: String] {
        let identifiers = StoreProduct.allCases.map(\.rawValue)
        guard let loaded = try? await Product.products(for: identifiers) else { return [:] }
        products = Dictionary(uniqueKeysWithValues: loaded.map { ($0.id, $0) })
        var prices: [StoreProduct: String] = [:]
        for product in loaded {
            guard let known = StoreProduct(rawValue: product.id) else { continue }
            prices[known] = product.displayPrice
        }
        await refreshEntitlements()
        return prices
    }

    public func purchase(_ product: StoreProduct) async -> PurchaseOutcome {
        guard let storeProduct = products[product.rawValue] else {
            return .failed(StoreMessage.purchaseFailed)
        }
        do {
            switch try await storeProduct.purchase() {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    return .failed(StoreMessage.purchaseFailed)
                }
                await handle(transaction)
                await transaction.finish()
                return .purchased(product)
            case .userCancelled:
                return .cancelled
            case .pending:
                return .pending
            @unknown default:
                return .failed(StoreMessage.purchaseFailed)
            }
        } catch {
            return .failed(StoreMessage.purchaseFailed)
        }
    }

    @discardableResult
    public func restorePurchases() async -> Bool {
        try? await AppStore.sync()
        await refreshEntitlements()
        return hasRemoveAds
    }

    public func startTransactionListener() {
        updatesTask?.cancel()
        updatesTask = Task.detached { [weak self] in
            for await update in Transaction.updates {
                guard case .verified(let transaction) = update else { continue }
                await self?.handle(transaction)
                await transaction.finish()
            }
        }
    }

    private func handle(_ transaction: Transaction) async {
        guard let product = StoreProduct(rawValue: transaction.productID) else { return }
        if product.isConsumable {
            onConsumableGranted?(product)
        } else {
            await refreshEntitlements()
        }
    }

    private func refreshEntitlements() async {
        var entitled = false
        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let transaction) = entitlement,
                  let product = StoreProduct(rawValue: transaction.productID) else { continue }
            if product.grantsRemoveAds { entitled = true }
        }
        if entitled != hasRemoveAds {
            hasRemoveAds = entitled
            onEntitlementsChanged?(entitled)
        }
    }
}
#endif
