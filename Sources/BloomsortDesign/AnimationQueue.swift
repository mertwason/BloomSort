/// Eşzamanlı animasyon kuyruğu.
///
/// `CLAUDE.md` ve `docs/ui-spec.md` §3.5: tahtada aynı anda **en fazla 3 arı**
/// animasyonu olabilir, fazlası kuyruğa alınır. Kuyruk mantığı SpriteKit'ten
/// ayrı tutuldu ki sırayla çalıştığı test edilebilsin.
public struct AnimationQueue<Job>: Sendable where Job: Sendable {
    public let concurrencyLimit: Int
    public private(set) var running: Int = 0
    private var waiting: [Job] = []

    public init(concurrencyLimit: Int = 3) {
        precondition(concurrencyLimit > 0, "Eşzamanlılık sınırı pozitif olmalı")
        self.concurrencyLimit = concurrencyLimit
    }

    public var queued: Int { waiting.count }
    public var isIdle: Bool { running == 0 && waiting.isEmpty }

    /// İşi kabul eder. Hemen başlatılacaksa `Job`'u döner, değilse `nil`
    /// (kuyruğa alındı).
    public mutating func submit(_ job: Job) -> Job? {
        guard running < concurrencyLimit else {
            waiting.append(job)
            return nil
        }
        running += 1
        return job
    }

    /// Çalışan bir iş bitti. Kuyruktan başlatılabilecek işi döner.
    public mutating func finish() -> Job? {
        precondition(running > 0, "Çalışmayan iş bitirilemez")
        running -= 1
        guard running < concurrencyLimit, !waiting.isEmpty else { return nil }
        running += 1
        return waiting.removeFirst()
    }

    public mutating func cancelAll() {
        waiting.removeAll()
    }
}
