#if canImport(SwiftUI) && canImport(SpriteKit)
import BloomsortDesign
import BloomsortDomain
import BloomsortGame
import BloomsortServices
import SpriteKit
import SwiftUI

/// Oyun ekranı (`docs/ui-spec.md` §3.5).
///
/// **Bu ekranda hiçbir reklam yüzeyi yok** — banner da, interstitial de
/// (§4, `CLAUDE.md`). Interstitial yalnızca seviye bitiş → sonraki geçişinde.
public struct GameView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.dismiss) private var dismiss
    @State private var model: GameViewModel
    @State private var scene: BoardScene?
    @State private var showsPause = false
    @State private var magnifiedVessel: Int?

    let onFinished: (Int, Int) -> Void

    public init(level: Level, environment: AppEnvironment,
                onFinished: @escaping (Int, Int) -> Void) {
        _model = State(initialValue: GameViewModel(level: level, environment: environment))
        self.onFinished = onFinished
    }

    public var body: some View {
        ZStack {
            Theme.duskDeep.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                plateStrip
                board
                windIndicator
                actionBar
            }
        }
        .toast(Binding(get: { model.toast }, set: { model.toast = $0 }))
        .sheet(isPresented: $showsPause) {
            PauseSheet(onResume: { showsPause = false; model.resume() },
                       onRestart: { showsPause = false; model.reset() },
                       onExit: { showsPause = false; leave() })
                .presentationDetents([.height(320)])
        }
        .fullScreenCover(isPresented: Binding(
            get: { if case .completed = model.phase { return true }; return false },
            set: { _ in })) {
            if case let .completed(stars, moves) = model.phase {
                LevelCompleteView(level: model.level, stars: stars, moves: moves,
                                  onNext: { onFinished(stars, moves) })
            }
        }
        .onChange(of: model.shouldSuggestUndo) { _, suggest in
            // Çıkmazda otomatik geri al öner (§6) — oyuncu kaybetmiş olmaz.
            if suggest { model.acceptUndoSuggestion() }
        }
        .onDisappear { model.abandon(lastAction: "exit") }
    }

    // MARK: - HUD (§2.4)

    private var header: some View {
        HStack {
            Button {
                model.pause()
                showsPause = true
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 20))
                    .foregroundStyle(Theme.mist)
                    .frame(width: Layout.minimumTapTarget, height: Layout.minimumTapTarget)
                    .background(Theme.moss.opacity(0.7), in: Circle())
            }
            .accessibilityLabel("Ara ver")

            Spacer()
            VStack(spacing: 2) {
                Text("Seviye \(model.level.id)")
                    .textStyle(Typography.displayM)
                    .foregroundStyle(Theme.mist)
                Text(model.albumLabel)
                    .textStyle(Typography.caption)
                    .foregroundStyle(Theme.mistDim)
            }
            Spacer()

            HStack(spacing: Spacing.s2) {
                CounterPill(systemImage: "ant.fill", value: environment.progress.bees)
                    .accessibilityLabel("\(environment.progress.bees) arı")
                CounterPill(systemImage: "arrow.uturn.backward", value: model.freeUndos)
                    .accessibilityLabel("\(model.freeUndos) geri al hakkı")
            }
        }
        .padding(.horizontal, Spacing.screenMargin)
        .frame(height: 52)
        .padding(.top, Spacing.s2)
    }

    /// Levha şeridi (§2.5): seviyedeki her renk için bir yuva; sayı olmadan
    /// "ne kadar kaldı"yı anlatır.
    private var plateStrip: some View {
        HStack(spacing: Spacing.s2) {
            ForEach(0..<model.level.colors, id: \.self) { color in
                Circle()
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .foregroundStyle(Theme.mistDim.opacity(0.5))
                    .frame(width: 20, height: 20)
                    .overlay {
                        if bloomedColors.contains(color) {
                            Circle().fill(Theme.pollenColor(color))
                        }
                    }
            }
            if model.showsMoveBudget {
                Spacer()
                Text("\(model.moveCount)/\(model.moveBudget)")
                    .textStyle(Typography.caption)
                    .foregroundStyle(model.isOverBudget ? Theme.ember : Theme.mistDim)
                    .accessibilityLabel("Arı bütçesi \(model.moveCount) bölü \(model.moveBudget)")
            }
        }
        .frame(height: 44)
        .padding(.horizontal, Spacing.screenMargin)
    }

    private var bloomedColors: Set<Int> {
        Set(model.state.vessels.filter(\.isBloomed).compactMap { $0.top?.color.index })
    }

    private var board: some View {
        GeometryReader { proxy in
            SpriteView(scene: makeScene(size: proxy.size), options: [.allowsTransparency])
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Oyun tahtası")
        }
    }

    private func makeScene(size: CGSize) -> BoardScene {
        if let scene, scene.size == size { return scene }
        let created = BoardScene(state: model.state, size: size,
                                 presentation: environment.presentation)
        created.boardDelegate = BoardBridge(model: model, environment: environment)
        DispatchQueue.main.async { self.scene = created }
        return created
    }

    /// Rüzgâr göstergesi (§3.5, seviye 86+): 3 hamle önceden bildirir.
    @ViewBuilder private var windIndicator: some View {
        if let announced = model.state.announcedWind {
            HStack(spacing: Spacing.s2) {
                Image(systemName: "wind")
                Text("\(announced.movesAway) hamle sonra ⇄")
                    .textStyle(Typography.caption)
            }
            .foregroundStyle(Theme.erguvan)
            .frame(height: 28)
            .accessibilityLabel(BoardAccessibility.windAnnouncement(
                movesAway: announced.movesAway,
                first: announced.pair.first, second: announced.pair.second))
        }
    }

    /// Alt eylem çubuğu (§2.6). Dokunma alanı 64 × 60.
    private var actionBar: some View {
        HStack(spacing: 0) {
            actionButton(icon: "arrow.uturn.backward", label: "Geri al",
                         rewarded: model.freeUndos == 0) { model.undo() }
            actionButton(icon: "lightbulb", label: "İpucu",
                         rewarded: model.hintsRemaining == 0) {
                Task { await model.requestHint() }
            }
            actionButton(icon: "arrow.clockwise", label: "Sıfırla") { model.reset() }
            actionButton(icon: "plus.circle", label: "Arı",
                         rewarded: environment.progress.bees == 0) {
                model.spendBee(capacity: 4)
            }
        }
        .frame(height: 60)
        .padding(.bottom, Spacing.s5)
    }

    private func actionButton(icon: String, label: String, rewarded: Bool = false,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: Spacing.s1) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundStyle(Theme.mist)
                    if rewarded {
                        Image(systemName: "play.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(Theme.pollen)
                            .offset(x: 10, y: -4)
                    }
                }
                Text(label.uppercased())
                    .textStyle(Typography.micro)
                    .foregroundStyle(Theme.mistDim)
            }
            .frame(width: 64, height: 60)
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel(label)
    }

    private func leave() {
        model.abandon(lastAction: "quit")
        dismiss()
    }
}

/// Sahne ile view model arasındaki köprü.
@MainActor
final class BoardBridge: NSObject, BoardSceneDelegate {
    private let model: GameViewModel
    private let environment: AppEnvironment

    init(model: GameViewModel, environment: AppEnvironment) {
        self.model = model
        self.environment = environment
    }

    func boardScene(_ scene: BoardScene, didRequestMoveFrom source: Int, to destination: Int) {
        guard let outcome = model.requestMove(from: source, to: destination) else {
            scene.rejectMove(to: destination)
            return
        }
        scene.animate(move: outcome.move, resulting: outcome.result)
    }

    func boardSceneDidRequestUndo(_ scene: BoardScene) {
        model.undo()
        scene.present(state: model.state)
    }

    func boardScene(_ scene: BoardScene, didLongPressVessel index: Int) {
        // Büyütülmüş gösterim erişilebilirlik içindir (§2.2); VoiceOver'a da
        // aynı metni duyuruyoruz.
        let vessel = model.state.vessels[index]
        UIAccessibility.post(notification: .announcement,
                             argument: VesselNode.accessibilityLabel(for: vessel, index: index))
    }

    func boardScene(_ scene: BoardScene, didTrigger haptic: Haptic) {
        environment.play(HapticKind(rawValue: haptic.rawValue) ?? .button)
    }

    func boardScene(_ scene: BoardScene, didBloomVessel index: Int, color: PollenColor) {
        environment.playSound(.bloom)
        let remaining = model.state.vessels.filter { !$0.isEmpty && !$0.isBloomed }.count
        UIAccessibility.post(notification: .announcement,
                             argument: BoardAccessibility.bloomAnnouncement(
                                vessel: index, remainingColors: remaining))
    }

    func boardScene(_ scene: BoardScene, didLandBeadAtDepth depth: Int, color: PollenColor) {
        environment.playNote(depth: depth)
    }
}
#endif
