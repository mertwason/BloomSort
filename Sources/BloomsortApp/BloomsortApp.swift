#if canImport(SwiftUI)
import BloomsortDomain
import BloomsortServices
import SwiftUI
#if canImport(SwiftData)
import SwiftData
#endif

/// Uygulamanın sahnesi.
///
/// `@main` burada **değil**: bu bir kütüphane hedefi, giriş noktası Xcode
/// uygulama hedefindeki `BloomsortMain.swift`'te. Böylece aynı kod hem
/// uygulamada hem önizlemelerde kullanılabiliyor.
///
/// Yalnızca dikey (§0). Açılış perdesi 800 ms sonra kök görünüme geçer (§3.1).
public struct BloomsortScene: Scene {
    @State private var environment: AppEnvironment
    @State private var showsSplash = true

    public init(environment: AppEnvironment? = nil) {
        _environment = State(initialValue: environment ?? AppEnvironment(levels: LevelLoader.load()))
    }

    public var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()
                    .environment(environment)
                    .opacity(showsSplash ? 0 : 1)
                if showsSplash {
                    SplashView()
                        .transition(.opacity)
                }
            }
            .preferredColorScheme(.dark)
            .task {
                try? await Task.sleep(nanoseconds: 800_000_000)
                withAnimation(.easeInOut(duration: 0.3)) { showsSplash = false }
            }
        }
        #if canImport(SwiftData)
        .modelContainer(for: [PlayerProfile.self, CollectedPlate.self])
        #endif
    }
}

/// Açılış (§3.1): kapalı tomurcuk 400 ms'de açılır, altında "Bloomsort".
struct SplashView: View {
    @State private var opened = false

    var body: some View {
        ZStack {
            Theme.dusk.ignoresSafeArea()
            VStack(spacing: Spacing.s4) {
                Circle()
                    .fill(Theme.pollen)
                    .frame(width: opened ? 64 : 18, height: opened ? 64 : 18)
                    .opacity(opened ? 1 : 0.4)
                Text("Bloomsort")
                    .textStyle(Typography.displayL)
                    .foregroundStyle(Theme.mist)
                    .opacity(opened ? 1 : 0)
            }
        }
        .task {
            withAnimation(.easeOut(duration: 0.4)) { opened = true }
        }
        .accessibilityLabel("Bloomsort")
    }
}
#endif
