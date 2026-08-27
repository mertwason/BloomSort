import BloomsortApp
import SwiftUI

/// Uygulamanın giriş noktası.
///
/// Bütün ekranlar `BloomsortApp` kütüphanesinde; burada yalnızca `@main`
/// duruyor ki aynı kod önizlemelerde ve testlerde de kullanılabilsin.
@main
struct BloomsortMain: App {
    var body: some Scene {
        BloomsortScene()
    }
}
