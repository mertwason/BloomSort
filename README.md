# Bloomsort

Alacakaranlıkta geçen polen sıralama bulmacası. Oyuncu arılara polen taşıtarak
çiçek kaplarını tek renge indirir; dolan kap çiçek açar ve tahtadan ayrılır.

- Ürün ve tasarım: [`docs/gdd.md`](docs/gdd.md)
- Arayüz spesifikasyonu: [`docs/ui-spec.md`](docs/ui-spec.md)
- Lansman checklist'i: [`docs/launch-checklist.md`](docs/launch-checklist.md)
- Claude Code çalışma kuralları: [`CLAUDE.md`](CLAUDE.md)

---

## Katmanlar

```
Sources/
  BloomsortDomain/    saf Swift · GameState, Move, Solver, LevelGenerator, engeller
  BloomsortDesign/    saf Swift · palet, tipografi, hareket, tahta yerleşimi, erişilebilirlik metinleri
  BloomsortGame/      SpriteKit · BoardScene, VesselNode, BeadNode, BeeNode, BloomFX
  BloomsortApp/       SwiftUI · Patika, oyun ekranı, Herbaryum, Kovan, Ayarlar, SwiftData
  BloomsortServices/  AdService, IAP, analitik, ses, haptik, rıza, ekonomi, ilerleme
Tools/levelgen/       CLI · seviye üretimi, doğrulama, ölçüm
App/                  Xcode uygulama hedefi · Info.plist, privacy manifest, yerelleştirme
Resources/levels.json 200 doğrulanmış seviye
```

Bağımlılık yönü tek yönlü: `App → Game → Domain`, `App → Services`, `Game → Design`.
Domain hiçbir şeye bağımlı değil.

| Katman | Durum | Nerede derleniyor |
|---|---|---|
| `BloomsortDomain` | ✅ testli | Linux + macOS + iOS |
| `BloomsortDesign` | ✅ testli | Linux + macOS + iOS |
| `BloomsortServices` (kural motorları) | ✅ testli | Linux + macOS + iOS |
| `BloomsortServices` (StoreKit / AdMob / UMP köprüleri) | ✅ yazıldı | yalnızca Apple, SDK varsa |
| `BloomsortGame` (SpriteKit) | ✅ yazıldı, **derlenmedi** | yalnızca Apple |
| `BloomsortApp` (SwiftUI) | ✅ yazıldı, **derlenmedi** | yalnızca Apple |

**Derlenmedi ne demek:** bu oturum Linux'ta koştu; SpriteKit ve SwiftUI orada
yok. O katmanlardaki platformdan bağımsız her şey `BloomsortDesign`'a çıkarıldı
ve test edildi — arı uçuş geometrisi ve süresi, animasyon kuyruğu, tahta
yerleşimi, VoiceOver metinleri, palet kontrastı. Geriye kalan çatı kodu bir
Mac'te ilk derlemede düzeltme isteyebilir; CI'daki `ios` işi bunun için var
(ilk yeşil koşuya kadar `continue-on-error` ile işaretli).

## Kullanım

```bash
swift build -c release
swift test

# 200 seviye üret (depodaki paketi birebir yeniden üretir)
swift run -c release levelgen --count 200 --level-budget 1800 --out Resources/levels.json

# Yarıda kesilen üretimi kaldığı yerden sürdür
swift run -c release levelgen --count 200 --resume --out Resources/levels.json

# Paketi baştan sona doğrula (CI bunu koşuyor)
swift run -c release levelgen --verify Resources/levels.json

# Çözücü ölçümü · bir bandın ulaşılabilir zorluğu · ret nedenleri
swift run -c release levelgen --benchmark 20 --depth 40
swift run -c release levelgen --probe 117 --diagnose-count 5
swift run -c release levelgen --diagnose 47 --diagnose-count 6
```

iOS uygulaması (Mac gerekir):

```bash
cd App && xcodegen generate && open Bloomsort.xcodeproj
```

## Çözücünün sınırı — bilinmesi gereken

GDD §8.3 "12 renk / 15 kap için tipik çözüm < 40 ms" diyor. Ölçüm bunu
doğrulamıyor ve bu, zorluk eğrisini doğrudan değiştirdiği için burada duruyor.

Maliyet hem `M*` hem **renk sayısı** ile üstel büyüyor — ve ikincisi baskın:

| Tahta | `M*` | Tipik süre |
|---|---|---|
| 4 renk / 6 kap | ~10 | < 1 ms |
| 7 renk / 9 kap | ~22 | 0,1–3 sn |
| 9 renk / 12 kap | ~22 | 5–30 sn |
| 11 renk / 14 kap | ~22 | 20–60 sn |
| 11 renk / 14 kap | ~25 | çoğu tahtada düğüm bütçesi aşılıyor |
| 12 renk / 15 kap | ~29 | ~180 sn |
| 12 renk / 15 kap | 35+ | çözülemiyor |

Sonuç ters yönlü: **renk sayısı arttıkça doğrulanabilir `M*` düşüyor.**
§4.2'nin "renk de artsın, hamle sayısı da artsın" kurgusu kesin optimal
doğrulamayla bir arada mümkün değil.

**Karar:** `M*` bantları düşürüldü ve 41. seviyeden sonrası düz (19-22).
Zorluk renk sayısı, boş kap sayısı ve kapasite çeşitliliğiyle artmaya devam
ediyor. Gerekçe GDD §4.2'deki nota işlendi.

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

## Seviye paketi

`Resources/levels.json` — 200 seviye. Tahta diskte durmuyor; her seviye `seed`
+ ters hamle sayısından birebir yeniden kuruluyor, yani aynı seed her cihazda
aynı tahtayı veriyor. Engeller kayıtta açıkça duruyor.

Paketin tamamı `levelgen --verify` ile doğrulandı: her seviye seed'den yeniden
kuruldu, kesin optimal çözücüyle çözüldü, kayıtlı `M*` ile karşılaştırıldı ve
çözüm yolu baştan sona oynanarak tahtanın bittiği görüldü. CI bunu her push'ta
koşuyor.

## Verilmiş kararlar

Hepsi ilgili dokümana not olarak da işlendi.

- **Çiçek açma bir sunum olayı.** Kap tahtada kalır, gerekirse bozulabilir.
  §2.5'in "kap tahtadan ayrılır" ifadesi geri dönülmez okunursa karışık
  kapasitede seviye kazanılamaz hâle gelebiliyordu; bu da "kaybetme yok" ile
  çelişiyordu. Kazanma koşulu: her kap ya boş ya tek renkle **dolu**.
- **`M*` bantları düşürüldü, 41. seviyeden sonrası düz.** Ölçüm gereği.
- **Yıldız eşiği:** 3★ yalnızca tam optimal çözümde, 2★ için `M* × 1,25`,
  üstü 1★.
- **Arı bütçesi = 2★ eşiği.** Ayrı bir sayı uydurmak yerine; bütçeyi aşmak tam
  olarak 1★'a düşmek demek.
- **Palet 12 renge çıktı.** Eksik dört renk ölçümle seçildi: paletin kendi
  L\*/C\* zarfında, zemine kontrastı ≥ 7,4 ve diğer bütün renklerden CIEDE2000
  farkı ≥ 16 (paletin mevcut en yakın çifti 15,7).
- **Engel kuralları** birebir okunarak yazıldı; ayrıntı GDD §4.2 notunda.
- **Ses:** D majör pentatonik. §7.3'ün "1. tane D, 5. tane A" tarifi beş notada
  yarım ses gerektiriyor ve o dizi pentatonik olmuyor; A dördüncü tanede
  geliyor.

## Yolda çıkan ve düzeltilen spec hataları

- §1.1'deki dört kontrast oranı hex değerlerinden hesaplananla tutmuyordu
  (13,9 / 6,4 / 11,2 / 9,7 → 14,3 / 7,0 / 10,3 / 10,3). Tasarım değişmedi,
  dördü de AA'yı geçiyor. Oranlar artık her testte hex'lerden yeniden
  hesaplanıyor.
- §3.5'in yerleşimi en yoğun tahtada sığmıyordu: 3 satır × 188 pt = 564 pt,
  tahta alanı 449 pt. Genişlik ölçekleniyor ama yükseklik ölçeklenmiyordu.
  `BoardLayout` düzgün bir ölçek katsayısı uyguluyor, taşma ve çakışma testli.
- §3.7'deki "34/32 hamle → 3★" mock'u yeni yıldız eşiğiyle 2★ olurdu; 32/32
  yapıldı.
- §4.1 "çözülebilirlik matematiksel garanti" diyor; bu ancak her ters hamle tam
  olarak bir ileri hamlenin tersiyse doğru ve o kadar dar bir tanımla yürüyüş
  birkaç adımda tıkanıyor. Garanti yerine her seviyenin çözücüyle doğrulanması
  konuldu.

## Hâlâ açık

Bunlar dokümanlarda yok, uydurulmadı.

1. **Herbaryum biyom adları.** §5.1 sekiz biyom sayıyor ("Çayır, Orman Altı,
   Kıyı, Bozkır, Yayla, Bahçe, Sulak, Kayalık…") ama 200 seviye 17 albüm
   ediyor. Dokuz ad eksik; isimsiz albümler "Bölge 9" gibi görünüyor ve kodda
   işaretli.
2. **İpucu bankası boyutu.** §6.1 R3 "bankası boş" diyor ama bankanın kaç
   hakla başladığını vermiyor. Şimdilik 1.
3. **Mevsim yolu, Bahçem etkileşimli mod, Günün Çiçeği, seri onarımı.** §5.3
   ve §5.4'te tarif edilmiş ama §9.2 bunları v1.1'e erteliyor; ekonomi ve
   analitik tarafı hazır, ekranları yok.
4. **AdMob App ID, ad unit ID'leri, SKAdNetwork listesi, Firebase yapılandırma
   dosyası.** Hesap işleri; `App/Info.plist` içindeki yer tutucu kasten
   geçersiz ve bir test bunu bekliyor.

## Yapılmayanlar (v1.1)

Bahçem tam etkileşimli mod · Mevsim yolu · CloudKit · Native reklam · Mevsim
geçişi IAP · Temalar · Sonsuz Çayır · iPad özel düzen · Widget · Game Center ·
sosyal özellikler.
