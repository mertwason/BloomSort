#if canImport(SwiftUI)
import BloomsortDesign
import BloomsortDomain
import BloomsortGame
import BloomsortServices
import Foundation
import SwiftUI

/// Oyun ekranının durumu.
///
/// Tahtayı domain tutuyor (`UndoStack`), sahne yalnızca gösteriyor.
/// Reklam, ses ve analitik kararları buradan geçiyor.
@Observable
@MainActor
public final class GameViewModel {
    public enum Phase: Equatable {
        case playing
        case paused
        case completed(stars: Int, moves: Int)
    }

    public let level: Level
    public private(set) var stack: UndoStack
    public private(set) var phase: Phase = .playing
    public private(set) var freeUndos: Int
    public private(set) var hintsRemaining: Int
    public private(set) var hintedMove: Move?
    public var toast: Toast?

    /// Ücretsiz geri al hakkı (§6.1 R2: bitince ödüllü video 3 hak verir).
    public static let freeUndosPerLevel = 3
    public static let rewardedUndoGrant = 3
    /// İpucu bankası (§6.1 R3).
    ///
    /// **Açık:** GDD "İpucu butonu, bankası boş" diyor ama bankanın kaç
    /// hakla başladığını hiçbir yerde vermiyor. 1 ile başlıyor; değer
    /// netleşince burası değişecek (bkz. README, açık sorular).
    public static let freeHintsPerLevel = 1

    private let environment: AppEnvironment
    private let startedAt = Date()
    private var undosUsed = 0
    private var hintsUsed = 0
    private var beesUsed = 0
    private var attempt: Int

    public init(level: Level, environment: AppEnvironment, attempt: Int = 1) {
        self.level = level
        self.environment = environment
        self.attempt = attempt
        self.stack = UndoStack(level.board)
        self.freeUndos = GameViewModel.freeUndosPerLevel
        self.hintsRemaining = GameViewModel.freeHintsPerLevel
        environment.analytics.log(.levelStart(levelID: level.id, attempt: attempt,
                                              beesOwned: environment.progress.bees,
                                              seed: level.seed))
    }

    public var state: GameState { stack.current }
    public var moveCount: Int { stack.current.moveCount }
    public var canUndo: Bool { stack.canUndo }
    /// Arı bütçesi göstergesi (§3.5, seviye 116+).
    public var showsMoveBudget: Bool { level.obstacleKinds.contains(.beeBudget) }
    public var moveBudget: Int { level.moveBudget }
    public var isOverBudget: Bool { moveCount > moveBudget }
    /// Albüm ilerlemesi: "Çayır · 11/12".
    public var albumLabel: String { Herbarium.progressLabel(forLevel: level.id) }

    // MARK: - Hamle

    /// Sahne bir hamle istedi. Yasalsa uygular ve sahneye animasyon için verir.
    public func requestMove(from source: Int, to destination: Int) -> (move: Move, result: GameState)? {
        guard case .playing = phase else { return nil }
        guard let move = state.move(from: source, to: destination) else {
            environment.play(.invalidMove)
            return nil
        }
        guard stack.apply(move) else { return nil }
        hintedMove = nil
        checkCompletion()
        return (move, stack.current)
    }

    public func undo() {
        guard stack.canUndo else { return }
        if freeUndos > 0 {
            freeUndos -= 1
            _ = stack.undo()
            undosUsed += 1
            environment.play(.button)
        } else {
            toast = Toast("Geri al hakkın bitti. Ödüllü videoyla 3 hak alabilirsin.")
        }
    }

    /// Ödüllü video sonrası geri al hakkı (§6.1 R2).
    public func grantRewardedUndos() {
        freeUndos += GameViewModel.rewardedUndoGrant
        environment.recordRewarded()
    }

    public func reset() {
        stack.reset()
        hintedMove = nil
        environment.play(.button)
    }

    /// Tahtaya arı salar: ekstra boş kap (§2.1).
    public func spendBee(capacity: Int) {
        guard environment.progress.bees > 0 else {
            toast = Toast("Arın kalmadı. Kovan'dan alabilir ya da video izleyebilirsin.")
            return
        }
        _ = environment.progress.spendBee()
        beesUsed += 1
        _ = stack.addBee(capacity: capacity)
        environment.analytics.log(.beeSpend(source: .reward, levelID: level.id))
        environment.play(.button)
    }

    /// İpucu: çözücüden optimal hamle (§6.1 R3).
    ///
    /// Çözücü derin tahtalarda saniyeler sürebiliyor, o yüzden arka planda
    /// koşuyor ve düğüm bütçesi oyun içi varsayılanda kalıyor.
    public func requestHint() async {
        guard hintsRemaining > 0 else {
            toast = Toast("İpucu hakkın bitti. Ödüllü videoyla bir tane daha alabilirsin.")
            return
        }
        hintsRemaining -= 1
        hintsUsed += 1
        let board = state
        let move = await Task.detached(priority: .userInitiated) {
            Solver.hint(board)
        }.value
        if let move {
            hintedMove = move
        } else {
            toast = Toast("Bu tahtada ipucu bulunamadı.")
        }
    }

    public func grantRewardedHint() {
        hintsRemaining += 1
        environment.recordRewarded()
    }

    // MARK: - Sıkışma ve bitiş

    /// Çıkmaz: otomatik geri al öner (§6).
    public var shouldSuggestUndo: Bool { stack.shouldSuggestUndo }

    public func acceptUndoSuggestion() {
        _ = stack.undo()
        toast = Toast("Bu tahta çıkmaza girdi. Son hamleni geri aldık.")
    }

    private func checkCompletion() {
        guard stack.current.isSolved else { return }
        let stars = level.stars(forMoves: moveCount)
        phase = .completed(stars: stars, moves: moveCount)
        environment.play(.levelComplete)
        environment.analytics.log(.levelComplete(
            levelID: level.id, moves: moveCount, optimalMoves: level.optimalMoves,
            stars: stars, durationMilliseconds: Int(Date().timeIntervalSince(startedAt) * 1000),
            undos: undosUsed, hints: hintsUsed, beesUsed: beesUsed))
    }

    public func abandon(lastAction: String) {
        guard case .playing = phase else { return }
        environment.analytics.log(.levelAbandon(
            levelID: level.id, moves: moveCount,
            durationMilliseconds: Int(Date().timeIntervalSince(startedAt) * 1000),
            lastAction: lastAction))
    }

    public func pause() { phase = .paused }
    public func resume() { phase = .playing }
}
#endif
