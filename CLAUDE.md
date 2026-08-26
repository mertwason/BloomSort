# CLAUDE.md — Bloomsort

Bu dosya repo kökünde durur ve Claude Code her oturumda okur. Kısa tut, güncel tut.

---

## Proje

Bloomsort, iPhone için alacakaranlıkta geçen bir polen sıralama bulmacası. Oyuncu arılara polen taşıtarak çiçek kaplarını tek renge indirir; dolan kap çiçek açar ve tahtadan ayrılır. Seviye bitince açılan çiçekler bir botanik levhaya dönüşüp Herbaryum'a preslenir.

**His:** sakin, akşam, ceza yok, süre yok, kaybetmek yok.
**Tam spesifikasyon:** `docs/gdd.md` ve `docs/ui-spec.md`. Çelişki varsa bu dosya değil, onlar geçerli.

---

## Teknik kısıtlar — pazarlığa kapalı

- **SwiftUI + SpriteKit.** Unity, Unreal, React Native, Flutter yok.
- **Xcode 26+, iOS 26 SDK ile derle, deployment target iOS 17.0.**
- **Elle çizilmiş sprite yok.** Tüm görseller `SKShapeNode` / bezier / shader / SF Symbols ile runtime'da üretilir. Bir asset dosyası eklemek istiyorsan önce sor.
- **Domain katmanı saf Swift.** `GameState`, `Move`, `applyMove`, `Solver`, `LevelGenerator` içinde hiçbir UIKit/SwiftUI/SpriteKit importu olamaz. Bu, çözücünün ve testlerin çalışmasının ön koşulu.
- **`GameState` değer tipidir ve mutasyonsuzdur.** `applying(_:) -> GameState` döner. Geri al = eski state'i sakla.
- **Üçüncü taraf bağımlılık:** yalnızca Google Mobile Ads SDK, UMP, Firebase. Başka paket eklemeden önce sor.

---

## Mimari

```
Sources/
  BloomsortDomain/      saf Swift · GameState, Move, Solver, LevelGenerator
  BloomsortGame/        SpriteKit · BoardScene, VesselNode, BeadNode, BeeNode, BloomFX
  BloomsortApp/         SwiftUI · RootView, PathView, HerbariumView, ShopView, Settings
  BloomsortServices/    AdService, IAPService, Analytics, AudioEngine, HapticEngine
Tools/
  levelgen/             CLI target · seviye üretimi ve doğrulama
Tests/
  DomainTests/          motor + çözücü + üretici testleri
  ServicesTests/        reklam kuralları testleri
Resources/
  levels.json           üretilmiş, doğrulanmış seviyeler
```

Bağımlılık yönü tek yönlü: `App → Game → Domain`, `App → Services`. Domain hiçbir şeye bağımlı değil.

---

## Oyun kuralları (referans)

Hamle `S → D` yasaldır ⟺ `S` boş değil **ve** `D` dolu değil **ve** (`D` boş **veya** `top(D).renk == top(S).renk`).
Taşınan miktar: `min(top(S) üzerindeki aynı renk run uzunluğu, D'deki boşluk)` — tek hamle sayılır.
Kazanma: her kap ya boş ya tek renkle dolu.
Kaybetme durumu **yoktur**. Sıkışma tespit edilirse otomatik geri al öner.

---

## Çalışma tarzı

- **Testi önce yaz.** Domain'de test edilmemiş fonksiyon merge edilmez.
- **Küçük commit.** Bir commit bir şey yapar. Mesaj Türkçe, emir kipi: "çözücüye transposition table ekle".
- **Bir seferde tek katman.** Domain işi yaparken UI'a dokunma.
- **Yapamıyorsan söyle.** Bir yaklaşım tutmuyorsa üstünü örtme, dur ve nedenini yaz. Yarım çalışan kod, çalışmayan koddan pahalı.
- **Sayıları uydurma.** Zorluk eşikleri, reklam sıklıkları, ekonomi değerleri `docs/gdd.md`'de yazılı. Orada yoksa sor.
- **Placeholder bırakma.** `// TODO: implement` yerine ya yaz ya da o görevi açık bırak ve raporla.

---

## Reklam kuralları — koda gömülecek

Interstitial yalnızca "seviye bitti → sıradaki seviye" geçişinde ve şu 8 koşulun **hepsi** sağlanırsa:

1. seviye ≥ 8
2. son interstitial'dan ≥ 90 sn geçti
3. son 45 sn içinde rewarded izlenmedi
4. önceki seviyede gösterilmedi
5. seviye 1★ ile bitmedi
6. son 1 saatte < 6 gösterim
7. oturumun ilk 3 dakikasında < 1 gösterim
8. "Reklamsız" satın alınmamış

Bunlar tek bir `canShowInterstitial(context:) -> Bool` fonksiyonunda toplanır ve **her kural için ayrı bir birim test** yazılır.

**Oyun tahtasında hiçbir reklam yüzeyi olamaz.** Banner yalnızca Herbaryum, Bahçem, Kovan, Ayarlar ekranlarında.

Rewarded reklam yüklenemezse ödül **yine de verilir** (günde 3 kez). Oyuncu teknik hatanın cezasını çekmez.

---

## Erişilebilirlik — sonradan eklenmez, baştan yazılır

Her kap VoiceOver etiketi taşır: `"Kap 3. 4 kapasiteli. Üstte sarı polen. 2 dolu."`
Renk asla tek bilgi kaynağı değildir — renk körlüğü modunda her polen sembol taşır.
`UIAccessibility.isReduceMotionEnabled` okunur, ayrıca oyun içi bağımsız anahtar vardır.
Her etkileşimli öğe ≥ 44×44 pt.

---

## İlk 5 görev

1. **Domain paketi.** `GameState`, `Vessel`, `Bead`, `Move`, `applyMove`, `legalMoves`, `isSolved`. Saf Swift. Yanına 25 birim test: toplu taşıma, dolu kaba hamle, boş kaba hamle, kazanma tespiti, geri al zinciri.

2. **IDA* çözücü.** Heuristic: `(tek renk olmayan kap sayısı) + (kesintiye uğramış renk blokları)`. Transposition table. `solve(_:limit:) -> [Move]?`. 12 renkli 100 rastgele durumda ortalama süreyi ölç ve raporla; hedef < 50 ms.

3. **Seviye üreticisi.** Çözülmüş durumdan ters hamlelerle karıştır, çözücüyle doğrula, kabul filtrelerini uygula (`M*` bandı, bayat tahta filtresi, dallanma faktörü ≥ 2,2). `swift run levelgen --count 200 --out levels.json` çalışmalı. Üretilen her seviye için çözülebilirlik testi CI'da koşsun.

4. **`BoardScene`.** SpriteKit. Parametrik kaplar, dokunmayla seçim, arı Bézier uçuşu (kontrol noktası orta noktanın 40 pt üstünde), polen düşüşü, çiçek açma sekansı. Sahne `GameState`'i yalnızca okur; mutasyonu domain'e delege eder. Aynı anda en fazla 3 arı animasyonu, fazlası kuyrukta.

5. **`AdService`.** `AdServiceProtocol` arkasında. Yukarıdaki 8 kural + her biri için test. Gerçek SDK çağrıları ayrı bir `AdMobAdService` implementasyonunda; testlerde `FakeAdService`.

---

## Yapmadığımız şeyler (v1.1)

Bahçem etkileşimli mod · Mevsim yolu · CloudKit · Native reklam · Mevsim geçişi IAP · Temalar · Sonsuz Çayır · iPad özel düzen · Widget · Game Center · sosyal özellikler.

Bunlardan biri gerekli görünüyorsa **yazmadan önce sor.** Kapsam kayması bu projenin bir numaralı riski.
