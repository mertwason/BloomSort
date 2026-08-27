# Bloomsort

Alacakaranlıkta geçen polen sıralama bulmacası. Oyuncu arılara polen taşıtarak
çiçek kaplarını tek renge indirir; dolan kap çiçek açar ve tahtadan ayrılır.

- Ürün ve tasarım: [`docs/gdd.md`](docs/gdd.md)
- Arayüz spesifikasyonu: [`docs/ui-spec.md`](docs/ui-spec.md)
- Lansman checklist'i: [`docs/launch-checklist.md`](docs/launch-checklist.md)
- Claude Code çalışma kuralları: [`CLAUDE.md`](CLAUDE.md)

---

## Bu depoda şu an ne var

Bu paket **platformdan bağımsız** katmanları içeriyor; hepsi Linux ve macOS'ta
derlenip test edilebiliyor, Xcode gerektirmiyor.

| Katman | Durum |
|---|---|
| `BloomsortDomain` — `GameState`, `Vessel`, `Bead`, `Move`, `applying`, `legalMoves`, `isSolved`, geri al | ✅ |
| `BloomsortDomain` — IDA* çözücü (`Solver`) | ✅ *sınırlarıyla, aşağıya bak* |
| `BloomsortDomain` — ters hamle seviye üreticisi + kabul filtreleri | ✅ |
| `Tools/levelgen` — üretim, doğrulama ve ölçüm CLI'ı | ✅ |
| `BloomsortServices` — interstitial 8 kuralı, banner yerleşimi, ödül telafisi, App Open kuralları | ✅ |
| `BloomsortGame` — SpriteKit `BoardScene` | ⬜ Xcode gerektiriyor |
| `BloomsortApp` — SwiftUI kabuk, SwiftData, Herbaryum | ⬜ Xcode gerektiriyor |
| `AdMobAdService`, StoreKit 2, Firebase | ⬜ SDK + Xcode gerektiriyor |

SpriteKit ve SwiftUI katmanları bu SwiftPM paketinde **yok**: SpriteKit Linux'ta
derlenmiyor ve bu depoda henüz bir Xcode projesi yok. Kural motorları buraya
konuldu ki gerçek SDK'lar gelmeden önce test edilebilsinler.

## Kullanım

```bash
swift build -c release
swift test

# 200 seviye üret
swift run -c release levelgen --count 200 --out Resources/levels.json

# Var olan paketi baştan sona doğrula (CI bunu koşuyor)
swift run -c release levelgen --verify Resources/levels.json

# Çözücü ölçümü
swift run -c release levelgen --benchmark 20 --depth 40

# Bir seviyenin ret nedenlerini gör
swift run -c release levelgen --diagnose 27
```

## Çözücünün sınırı — bilinmesi gereken

GDD §8.3 "12 renk / 15 kap için tipik çözüm < 40 ms" diyor. Ölçüm bunu
doğrulamıyor ve bu, zorluk eğrisini doğrudan değiştirdiği için burada duruyor.

`Solver` **kesin optimal** `M*` hesaplıyor (IDA*, kabul edilebilir heuristik,
transposition table, düğüm bütçesi). Kesin optimal arama tahta zorlaştıkça
üstel büyüyor:

| Tahta | `M*` | Tipik süre |
|---|---|---|
| 4 renk / 6 kap | ~10 | < 1 ms |
| 8 renk / 10 kap | ~20 | 10–100 ms |
| 12 renk / 15 kap | 26 | ~60 sn |
| 12 renk / 15 kap | 29 | ~180 sn |
| 12 renk / 15 kap | 35+ | düğüm bütçesi içinde çözülemiyor |

**Karar:** `docs/gdd.md` §4.2'nin `M*` bantları 11. seviyeden itibaren yeniden
ölçeklendi, tavan 26. Eğrinin şekli korundu; zorluk renk sayısı, boş kap sayısı
ve kapasite çeşitliliğiyle artmaya devam ediyor. Gerekçe GDD §4.2'deki nota
işlendi.

Denenip **elenen** üç kısayol, üçü de `SolverTests` tarafından yakalandı ve
koda girmedi:

- *"Bir kabı çiçek açtıran hamle varsa yalnızca onu dene."* Bazı tahtalarda
  çözümü tamamen kesiyor.
- *"Çiçek açmış kaptan hamle üretme."* Karışık kapasitede bir renk kendi
  adedinden küçük bir kabı doldurabiliyor; o kabın sonradan bozulması
  gerekebiliyor.
- *Heuristiğe "dağılmış renk sayısı" terimi eklemek.* Kabul edilebilir değil:
  aynı renk iki ayrı kabı tam doldurarak da bitebiliyor, yani hedefte bu terim
  sıfır olmak zorunda değil. IDA*'ı optimalden uzun çözümlere itiyordu.

## Verilmiş kararlar

- **Çiçek açma bir sunum olayı.** Kap tahtada kalır, gerekirse bozulabilir.
  §2.5'in "kap tahtadan ayrılır" ifadesi geri dönülmez okunursa karışık
  kapasitede seviye kazanılamaz hâle gelebiliyordu; bu da "kaybetme durumu
  yoktur" ile çelişiyordu. Kazanma koşulu: her kap ya boş ya tek renkle
  **dolu**. (Bkz. GDD §2.5 karar notu.)
- **`M*` tavanı 26.** Yukarıdaki ölçüm gereği; eğrinin şekli korunarak bütün
  bantlar yeniden ölçeklendi.

## Hâlâ açık, uydurulmadı

1. **Yıldız eşikleri.** GDD §8.3 "`M*` → yıldız eşiği" diyor ama 2★ ve 1★ için
   hamle çarpanını vermiyor. `Level.stars(forMoves:)` bu yüzden yazılmadı.
2. **Palette 8 renk var (§7.2 ve UI §1.2), zorluk tablosu 12 renge kadar
   çıkıyor (§4.2).** Eksik 4 renk ve renk körlüğü sembolleri belirlenmeli.
3. **Karıştırma derinliği `R`.** §4.1 girdi olarak istiyor ama değer vermiyor.
   Üretici sabit almak yerine `M*` hedef banda oturana kadar yürüyor.

## Henüz yapılmayanlar

- Engeller: kapalı tomurcuk (seviye 41+), çiy damlası (61+), rüzgâr (86+),
  arı bütçesi (116+). Üretici bu bantların renk/kapasite parametrelerini
  uyguluyor ama engelleri koymuyor.
- `BoardScene` ve bütün sunum katmanı.
- Gerçek AdMob/UMP/StoreKit/Firebase entegrasyonları.
