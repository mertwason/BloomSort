# BLOOMSORT — UI/UX Spesifikasyonu

**Referans cihaz:** iPhone 16 · 393 × 852 pt · @3x
**Güvenli alan:** üst 59 pt (Dynamic Island), alt 34 pt (home indicator)
**Yön:** yalnızca dikey (portrait)
**Bu doküman, Claude Design / Figma teslimi için hazırlanmıştır. Her değer nihaidir; "yaklaşık" yoktur.**

---

## 1. Tasarım Tokenları

### 1.1 Renk — çekirdek

| Token | Hex | RGB | Kullanım |
|---|---|---|---|
| `--dusk` | `#101E24` | 16,30,36 | Uygulama zemini |
| `--dusk-deep` | `#0A1418` | 10,20,24 | Modal arka planı, tahta zemini |
| `--moss` | `#1D3A36` | 29,58,54 | Yüzey / kart / panel |
| `--moss-hi` | `#274A45` | 39,74,69 | Yüzey (basılı / vurgulu) |
| `--mist` | `#E8EDE6` | 232,237,230 | Birincil metin |
| `--mist-dim` | `#9AAAA4` | 154,170,164 | İkincil metin, pasif ikon |
| `--pollen` | `#F5C24B` | 245,194,75 | **Hero aksan** — birincil CTA, arı, ilerleme |
| `--pollen-deep` | `#C99A2E` | 201,154,46 | Pollen basılı hâli, gölge |
| `--erguvan` | `#A971E8` | 169,113,232 | Premium / mevsim / nadir |
| `--dew` | `#6FD8C4` | 111,216,196 | Başarı, onay, çiy |
| `--ember` | `#E86A5C` | 232,106,92 | Uyarı, yıkıcı eylem, hata |

**Kontrast doğrulaması (WCAG AA):**
`--mist` / `--dusk` = 14,3:1 ✓ · `--mist-dim` / `--dusk` = 7,0:1 ✓ · `--dusk` / `--pollen` = 10,3:1 ✓ · `--mist` / `--moss` = 10,3:1 ✓

> **Düzeltme (27 Ağustos 2026).** Bu satırdaki dört oran taslakta 13,9 / 6,4 /
> 11,2 / 9,7 yazıyordu; hex değerlerinden hesaplanınca tutmuyorlar. Dördü de
> AA'yı rahatça geçtiği için tasarım değişmedi, yalnızca sayılar düzeltildi.
> Oranlar artık `DesignTests` tarafından her koşuda hex'lerden yeniden
> hesaplanıp doğrulanıyor, yani bir daha kayamazlar.

### 1.2 Renk — polen (oynanış)

| # | Ad | Hex | Sembol (renk körlüğü modu) |
|---|---|---|---|
| 1 | Sarı | `#F5C24B` | ● |
| 2 | Mercan | `#E86A5C` | ▲ |
| 3 | Erguvan | `#A971E8` | ■ |
| 4 | Çiy | `#6FD8C4` | ◆ |
| 5 | Gök | `#7BB5F0` | ★ |
| 6 | Pembe | `#F2A0C8` | ✚ |
| 7 | Filiz | `#9BD466` | ⬟ |
| 8 | Kayısı | `#E8925C` | ▼ |
| 9 | Lavanta | `#CDC3FF` | ○ |
| 10 | Buz | `#55E1FF` | ✖ |
| 11 | Zeytin | `#AAA569` | ◗ |
| 12 | Şeftali | `#FFB4AA` | ✱ |

> **Ek dört renk (27 Ağustos 2026).** Palet 8 renk tanımlıyordu ama §4.2'nin
> zorluk tablosu 12 renge çıkıyor. Eksik dördü ölçümle seçildi: hepsi paletin
> kendi L\*/C\* zarfında, `--dusk-deep` zeminine kontrastı ≥ 7,4 ve **diğer
> bütün renklerden CIEDE2000 farkı ≥ 16** — paletin mevcut en yakın çifti
> (Mercan ↔ Kayısı) 15,7 olduğu için bu, ayırt edilebilirlik tabanını
> düşürmüyor, yükseltiyor. `DesignTests` her koşuda doğruluyor.
>
> Semboller renk körlüğü modunda çizilir; ⬟ (beşgen) ile yeni ◗ (yarım daire)
> ve ✱ (yıldızcık) 10 pt'de en yakın çift, oyunlanabilirlik testinde bakılmalı.

Sembol, tane merkezine `--dusk-deep` renkte, 10 pt, %70 opaklıkta çizilir. **Yalnızca renk körlüğü modu açıkken.**

### 1.3 Tipografi

| Rol | Aile | Kullanım |
|---|---|---|
| **Display** | **Fraunces** (variable: `opsz`, `wght`, `SOFT`, `WONK`) | Logo, seviye numarası, levha adı, bölüm başlığı. **Kısıtlı kullanım** — ekranda en fazla 2 yerde. |
| **UI / gövde** | **SF Pro Rounded** (sistem) | Diğer her şey |
| **Sayısal** | SF Pro Rounded, `monospacedDigit` | Sayaçlar, para birimi, süre |

Fraunces ayarı: `WONK 1`, `SOFT 40` — organik, yaprak eğrisine yakın; `opsz` boyutla otomatik.

**Ölçek:**

| Stil | Boyut / Satır | Ağırlık | Harf aralığı | Aile |
|---|---|---|---|---|
| `display-xl` | 44 / 48 | 600 | −0,8 | Fraunces |
| `display-l` | 32 / 38 | 600 | −0,5 | Fraunces |
| `display-m` | 24 / 30 | 600 | −0,3 | Fraunces |
| `title` | 20 / 26 | 700 | −0,2 | SF Rounded |
| `body` | 17 / 24 | 500 | 0 | SF Rounded |
| `body-strong` | 17 / 24 | 700 | 0 | SF Rounded |
| `caption` | 14 / 20 | 500 | +0,1 | SF Rounded |
| `micro` | 11 / 14 | 700 | +0,6 (UPPERCASE) | SF Rounded |
| `numeric-l` | 28 / 32 | 700 | 0 | SF Rounded mono |

Dynamic Type: `body`, `caption` ölçeklenir (`.large` → `.accessibility3`). `display-*` en fazla %130 ölçeklenir (düzen bozulmasın).

### 1.4 Aralık (4 pt tabanlı)

`space-1` 4 · `space-2` 8 · `space-3` 12 · `space-4` 16 · `space-5` 24 · `space-6` 32 · `space-7` 48 · `space-8` 64

**Ekran kenar boşluğu:** 20 pt sol/sağ (sabit).

### 1.5 Köşe yarıçapı

`radius-s` 10 · `radius-m` 16 · `radius-l` 24 · `radius-xl` 32 · `radius-pill` 999
Kaplar (vessel) yarıçapı: alt 20, üst 8 (organik vazo silueti).

### 1.6 Gölge ve ışıma

```
--shadow-card:  0 8px 24px rgba(6,12,14,0.45)
--shadow-cta:   0 6px 16px rgba(201,154,46,0.35)
--glow-pollen:  0 0 20px rgba(245,194,75,0.55)    /* seçili polen */
--glow-bloom:   0 0 44px rgba(245,194,75,0.75)    /* çiçek açma anı */
--inner-vessel: inset 0 2px 6px rgba(0,0,0,0.35)
```

### 1.7 Hareket

| Token | Süre | Eğri | Kullanım |
|---|---|---|---|
| `motion-tap` | 90 ms | `easeOut` | Buton basma |
| `motion-micro` | 180 ms | `easeInOut` | Polen düşüşü, seçim |
| `motion-bee` | 340-520 ms | `easeInEaseOut` (Bézier) | Arı uçuşu |
| `motion-bloom` | 420 ms | `spring(response .42, damping .68)` | Çiçek açma |
| `motion-plate` | 620 ms | `spring(response .55, damping .80)` | Levha presi |
| `motion-sheet` | 320 ms | `spring(response .38, damping .86)` | Sheet giriş/çıkış |
| `motion-screen` | 280 ms | `easeInOut` | Ekran geçişi |

**Azaltılmış hareket (Reduce Motion) açıkken:** tüm süreler ×0,4; yay animasyonları `easeOut`a düşer; parçacıklar kapanır; çiçek açma tek kareli çapraz geçiş olur. Sistem ayarı otomatik okunur, ayrıca oyun içinde bağımsız anahtar vardır.

### 1.8 Haptik haritası

| Olay | Haptik |
|---|---|
| Kap seçimi | `.soft` (impact, 0,4) |
| Polen yerleşti | `.light` (impact, 0,6) |
| Geçersiz hamle | `.warning` (notification) |
| Çiçek açtı | `.medium` (impact, 0,8) |
| Seviye tamam | `.success` (notification) |
| Levha preslendi | `.rigid` (impact, 1,0) |
| Buton | `.selection` |

---

## 2. Bileşen Kütüphanesi

### 2.1 Buton

| Varyant | Yükseklik | Dolgu | Zemin | Metin | Yarıçap |
|---|---|---|---|---|---|
| **Primary** | 56 | 24 yatay | `--pollen` | `--dusk`, `body-strong` | `radius-pill` |
| **Secondary** | 56 | 24 | `--moss`, 1,5 pt `--moss-hi` kenarlık | `--mist` | `radius-pill` |
| **Ghost** | 48 | 20 | şeffaf | `--mist-dim` | `radius-pill` |
| **Destructive** | 56 | 24 | şeffaf, 1,5 pt `--ember` kenarlık | `--ember` | `radius-pill` |
| **Icon** | 44 × 44 | — | `--moss` %70 | `--mist`, SF Symbol 20 pt | daire |
| **Rewarded** | 56 | 24 | `--moss`, 1,5 pt `--pollen` kenarlık | `--pollen` + ▶ ikon 18 pt | `radius-pill` |

**Durumlar:** normal · basılı (`scale 0.96`, 90 ms, arka plan %12 koyulaşır) · pasif (%38 opaklık, dokunma yok) · yükleniyor (metin yerine 3 noktalı polen animasyonu)
**Minimum dokunma alanı: 44 × 44 pt** (görsel daha küçük olsa bile).

### 2.2 Kap (Vessel) — oynanışın atomu

```
     ╭─────────╮   ← ağız, radius 8, genişlik = W
     │ ▢ ▢ ▢ ▢ │   ← polen yuvaları, aşağıdan yukarı dolar
     │         │
     ╰─────────╯   ← taban, radius 20
```

| Kapasite | Genişlik W | Yükseklik H | Yuva çapı |
|---|---|---|---|
| 3 | 62 | 108 | 40 |
| 4 | 62 | 134 | 40 |
| 5 | 66 | 162 | 42 |
| 6 | 66 | 188 | 42 |

- Zemin: `--moss` %55 opaklık + `--inner-vessel`
- Kenarlık: 2 pt `--moss-hi`
- Yuva boşluğu: `--dusk-deep` %40, çap − 8
- Polen tanesi: daire, çap = yuva çapı − 6, ilgili polen rengi, üstte 30° açılı %18 beyaz highlight

**Durumlar:**

| Durum | Görünüm |
|---|---|
| Boş | Kenarlık %60 opaklık, içeride kesikli 1 pt daire ipucu |
| Kısmi | Normal |
| Seçili (kaynak) | Kap `translateY(−4)`, kenarlık `--pollen` 2,5 pt, üst polen `translateY(−8)` + `--glow-pollen` |
| Geçersiz hedef | 6 pt yatay titreme, 3 döngü, 240 ms, kenarlık 1 kare `--ember` |
| Tek renkle dolu (bloom öncesi) | Kenarlık `--pollen`, iç ışıma 200 ms nabız |
| Kilitli (kapalı tomurcuk) | %45 opaklık, üstte kapalı tomurcuk silueti + kalan sayaç rozeti |
| Çiy donmuş | İlgili polen üzerinde `--dew` %35 buzlu katman + ◇ ikon |

### 2.3 Arı (Bee)

18 × 14 pt. 5 parça: gövde (`--pollen`), 2 şerit (`--dusk`), 2 kanat (`--mist` %55, 60 ms döngüde 12° salınım).
Uçuş sırasında arkasında 5 noktalı iz: çap 3 → 1, opaklık %40 → 0, 60 ms gecikmeli.

### 2.4 Üst HUD (oyun ekranı)

Yükseklik 52 pt, y = güvenli alan üstü + 8.

```
┌──────────────────────────────────────────────────────┐
│ ⓧ        Seviye 47              🐝 3      ↩ 3        │
│ 44×44   display-m, ortalanmış   pill      pill       │
└──────────────────────────────────────────────────────┘
```

- Sol: kapat/duraklat, Icon buton
- Orta: `display-m`, `--mist`; altında `caption` `--mist-dim` ile albüm adı ("Çayır · 11/12")
- Sağ: iki pill. Her biri yükseklik 32, dolgu 12 yatay, `--moss` %70, `radius-pill`. İkon 16 pt + `numeric-l` küçültülmüş (17 pt, 700).
  - Arı pill'i **0** iken: zemin `--moss`, metin `--pollen`, sağında küçük ▶ rozeti (rewarded olduğunu gösterir)

### 2.5 Levha şeridi (oyun ekranı, HUD altı)

Yükseklik 44 pt. Seviyedeki her renk için 1 yuva. Boşken kesikli daire silueti; o renk çiçek açınca yuvaya minik çiçek uçar ve yerleşir (520 ms). Şerit, oyuncuya "ne kadar kaldı"yı **sayı olmadan** anlatır.

### 2.6 Alt eylem çubuğu (oyun ekranı)

y = 852 − 34 (safe) − 76. Yükseklik 60. 4 eylem, eşit aralıklı:

| İkon (SF Symbol) | Etiket | Eylem |
|---|---|---|
| `arrow.uturn.backward` | Geri al | Son hamleyi geri alır. Sayaç 0 ise Rewarded varyantına döner. |
| `lightbulb` | İpucu | Çözücüden optimal hamleyi 1,2 sn vurgular. |
| `arrow.clockwise` | Sıfırla | Onay sheet'i açar. |
| `plus.circle` (arı ikonlu) | Arı | Tahtaya boş kap ekler. 0 ise Rewarded. |

İkon 24 pt `--mist`, altında `micro` etiket `--mist-dim`. Dokunma alanı 64 × 60.

### 2.7 Sheet

Alt sayfa. Zemin `--moss`, üst yarıçap `radius-xl`, üstte 36 × 4 pt `--mist-dim` %40 tutamak. Arka plan `--dusk-deep` %70 + 20 pt blur. Sürükleyerek kapatılabilir. Giriş: `motion-sheet`.

### 2.8 Toast

Genişlik ekran − 40, yükseklik 52, `--moss-hi`, `radius-m`, `--shadow-card`. Üstten 12 pt aşağı iner, 2,4 sn kalır, yukarı çıkar. En fazla 1 tane aynı anda.

### 2.9 Levha kartı (Herbaryum)

103 × 138 pt (3 sütun, 20 pt kenar, 12 pt boşluk). Kâğıt zemini `#EDE8DC` — **koleksiyonun tek açık renkli yüzeyi.** Bu kasıtlı: oynanış canlı ve karanlık, arşiv presli ve kâğıt. İki dünyanın kontrastı ürünün imzasıdır.

- Üstte parametrik çiçek görseli (86 × 86)
- Altında `caption` Fraunces italik, `#3A3A32`, tür adı
- Sağ üstte yıldız rozetleri (3 × 8 pt)
- **Kilitli:** kâğıt `#2A2E2A` %40, ortada `?` ve seviye numarası

### 2.10 Reklam yuvası bileşenleri

| Bileşen | Boyut | Konum |
|---|---|---|
| Adaptive banner | 393 × 50-60 | Sekme çubuğunun **hemen üstünde**, yalnızca Herbaryum / Bahçem / Kovan / Ayarlar |
| Rewarded ön-diyalog | Sheet, yükseklik 280 | Ödül ikonu 56 pt + `title` + `caption` + Primary "İzle" + Ghost "Vazgeç" |
| Interstitial | Tam ekran, SDK yönetir | Uygulama, kendi geçiş perdesini 200 ms önce gösterir (ani sıçrama olmasın) |

**Ön-diyalog metni örneği (R1):** başlık "Bir arı daha?" · gövde "Tahtaya boş bir kap ekler." · buton "Reklamı izle" / "Şimdi değil"

---

## 3. Ekran Ekran Tasarım

### 3.0 Navigasyon haritası

```
Açılış (0,8 sn)
   └─ [ilk açılış?] ─evet─→ Onboarding (seviye 1-3 içinde, ayrı ekran yok)
                     └hayır─→ Kök
Kök = TabView (4 sekme, alt çubuk 83 pt)
   ├── 🌱 Patika  ──→ Seviye kartı (sheet) ──→ Oyun ekranı
   │                                              ├─ Duraklat (sheet)
   │                                              └─ Seviye tamam (tam ekran)
   │                                                    └─ [interstitial?] ─→ sıradaki seviye
   ├── 📖 Herbaryum ──→ Albüm ──→ Levha detayı (tam ekran) ──→ Paylaş
   ├── 🪴 Bahçem   ──→ Düzenleme modu
   └── 🍯 Kovan    ──→ IAP satın alma akışı
Global: Ayarlar (Patika sağ üst dişli) · Mevsim (Patika üst şerit) · Günün Çiçeği (Patika rozeti)
```

---

### 3.1 Açılış (Splash)

Zemin `--dusk`. Ortada kapalı bir tomurcuk silueti; 400 ms'de `--pollen` rengiyle açılır ve "Bloomsort" kelimesi `display-l` Fraunces ile altında belirir (`opacity 0→1`, 300 ms). Toplam 800 ms, ardından çapraz geçiş.
Ses: tek yumuşak çan notası (kapatılabilir).

---

### 3.2 Onboarding — ayrı ekran yok

Öğretici, **seviye 1-3'ün içinde** yaşar. Metin bloğu yoktur; sadece işaret ve kısıt vardır.

| Seviye | Öğretilen | Yöntem |
|---|---|---|
| 1 | Dokun-dokun hamlesi | Yalnızca 2 renk, 3 kap. Doğru kaynak nabız atar, diğer kaplar %35 opaklıkta. Elle çizilmiş bir parmak ikonu kaynağa 1 kez dokunur. Oyuncu dokunana kadar bekler. |
| 2 | Toplu taşıma | Üst üste 3 aynı renk kurgulanır. Oyuncu tek hamlede 3'ünü taşıyınca toast: "Üst üste aynı renkler birlikte gider." |
| 3 | Boş kap ve çiçek açma | İlk çiçek açma tam ekran yavaşlatılır (×0,6), levha şeridine yerleşmesi vurgulanır. |
| 4 | Geri al | Alt çubukta yalnızca Geri al aktif, diğerleri 500 ms sonra belirir. |
| 8 | Arı | İlk kez arı gerektirecek şekilde kurgulanmış tahta; Kovan butonu nabız atar. **İlk arı ücretsiz verilir, reklam istenmez.** |

**Kural: onboarding'de reklam yok, IAP yok, ATT yok.** İlk 5 seviye tamamen temiz.

---

### 3.3 Patika (Ana ekran)

Dikey kaydırılan bir çayır patikası. Kamera son oynanan seviyeye otomatik konumlanır.

```
┌─────────────────────────────────────┐  y=0
│ ░░░░░░ durum çubuğu ░░░░░░░░░░░░░░ │  59
├─────────────────────────────────────┤
│ 🌾 1.240   🐝 5            ⚙        │  ← üst bar 44 pt
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ MEVSİM · SONBAHAR    12/40  ▸  │ │  ← mevsim şeridi 64 pt, --moss
│ │ ▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░ │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ 🌼 Günün Çiçeği      23:14 ▸   │ │  ← yalnızca alınmadıysa, 56 pt
│ └─────────────────────────────────┘ │
│                                     │
│              ( 49 )                 │  ← kilitli tomurcuk, --mist-dim
│           ╱                         │
│      ( 48 )                         │
│           ╲                         │
│              (( 47 ))               │  ← MEVCUT: 76 pt, --pollen,
│           ╱                         │     nabız 1,8 sn döngü, glow
│      ( 46 ) ★★★                     │  ← tamamlanan: 56 pt, --dew
│           ╲                         │     altında yıldızlar
│              ( 45 ) ★★☆             │
│                                     │
│   ── ALBÜM: ÇAYIR ───────  11/12    │  ← her 12 seviyede ayraç
│                                     │
├─────────────────────────────────────┤
│  🌱      📖       🪴       🍯       │  ← sekme çubuğu 83 pt
│ Patika Herbaryum Bahçem  Kovan      │
└─────────────────────────────────────┘  y=852
```

**Detaylar:**
- Patika çizgisi: 3 pt, `--moss-hi`, kesikli (6/8), zikzak S eğrisi, x ekseninde ±64 pt salınım
- Düğüm dikey aralığı: 96 pt
- Arka plan: 3 katman paralaks silüet (ot, çalı, ağaç), kaydırma hızının 0,3× / 0,6× / 0,85×'i. 12 saniyede bir sağdan sola geçen ateşböceği parçacığı.
- **Sekme çubuğu:** `--dusk` %92 + blur, üstte 0,5 pt `--moss-hi` çizgi. Aktif ikon `--pollen`, pasif `--mist-dim`. Etiket `micro`.
- **Reklam:** Patika'da banner **yok**.

**Boş/özel durumlar:**
- İlk açılış: mevsim ve Günün Çiçeği şeritleri gizli, sadece seviye 1 görünür, "Başla" Primary butonu ekranın ortasında.
- Tüm seviyeler bitti: patikanın sonunda "Sonsuz Çayır" kartı.

---

### 3.4 Seviye kartı (sheet, yükseklik 380)

```
┌─────────────────────────────────────┐
│              ▬▬▬▬                   │  tutamak
│                                     │
│         ╭───────────────╮           │
│         │   [levha      │           │  ← 120×120, kilitliyse siluet
│         │    silueti]   │           │
│         ╰───────────────╯           │
│                                     │
│           Seviye 47                 │  display-l Fraunces
│      Papaver noctis · Çayır         │  caption --mist-dim
│                                     │
│    ★ ★ ☆      En iyi: 34 hamle      │  --pollen / --mist-dim
│                                     │
│  ┌───────────────────────────────┐  │
│  │           Oyna                │  │  Primary 56
│  └───────────────────────────────┘  │
│           Levhayı gör                │  Ghost (yalnızca tamamlandıysa)
└─────────────────────────────────────┘
```
İlk kez oynanan seviyede sheet **atlanır**, doğrudan oyun ekranına geçilir (sürtünme azaltma). Sheet yalnızca tamamlanmış seviyeye geri dönülünce açılır.

---

### 3.5 Oyun ekranı ⭐ (çekirdek)

```
┌─────────────────────────────────────┐  y=0
│ ░░░░░░ durum çubuğu ░░░░░░░░░░░░░ │  59
├─────────────────────────────────────┤
│ ⓧ         Seviye 47      🐝3   ↩3  │  HUD 52 → y=67..119
│            Çayır · 11/12            │
├─────────────────────────────────────┤
│   ○   ○   ●   ○   ○   ○   ○         │  levha şeridi 44 → y=127..171
├─────────────────────────────────────┤
│                                     │
│      ┌──┐  ┌──┐  ┌──┐  ┌──┐         │
│      │▓▓│  │▓▓│  │  │  │▓▓│         │  TAHTA ALANI
│      │▓▓│  │▓▓│  │  │  │▓▓│         │  y=187..636
│      └──┘  └──┘  └──┘  └──┘         │  (449 pt yükseklik)
│                                     │
│      ┌──┐  ┌──┐  ┌──┐  ┌──┐         │
│      │▓▓│  │▓▓│  │▓▓│  │  │         │
│      └──┘  └──┘  └──┘  └──┘         │
│                                     │
│           🐝  ⋯⋯⋯⋯⋯⋯               │  ← uçan arı, tahtanın üstünde
├─────────────────────────────────────┤
│   ↩       💡       ↻       ➕        │  eylem çubuğu 60 → y=676..736
│ Geri al  İpucu  Sıfırla   Arı       │
├─────────────────────────────────────┤
│         (banner YOK)                │
└─────────────────────────────────────┘  y=852 (alt safe 34)
```

**Tahta yerleşim algoritması:**
```
kapSayısı n, maks satır kapasitesi:
  n ≤ 8   → 2 satır × 4
  n ≤ 12  → 3 satır × 4
  n ≤ 15  → 3 satır × 5   (kap genişliği %88'e ölçeklenir)
  n ≤ 18  → 3 satır × 6   (kap genişliği %74'e ölçeklenir)
yatay boşluk = (393 − 40 − Σgenişlik) / (sütun − 1), min 12
dikey boşluk = (449 − Σyükseklik) / (satır + 1), min 16
tahta dikeyde ortalanır
```
Kaplar farklı yükseklikte olduğunda **satır içinde tabanları hizalanır** (üstleri değil) — vazolar bir rafta durur gibi görünür.

> **Düzeltme (27 Ağustos 2026).** Yukarıdaki algoritma genişliği ölçekliyor ama
> yüksekliği ölçeklemiyor ve en yoğun tahtada sığmıyor: 3 satır × 188 pt
> (6 kapasiteli kap) = 564 pt, tahta alanı ise 449 pt — "dikey boşluk" formülü
> negatif çıkıyor. Uygulama tek bir **düzgün ölçek katsayısı** hesaplıyor ve
> hem yüksekliği hem genişliği ona bağlıyor; katsayı 1'i aşmadığı için sığan
> tahtalar spec ölçüleriyle çiziliyor. Yerleşim `BloomsortDesign.BoardLayout`
> içinde, taşma ve çakışma testleri `BoardLayoutTests`'te.

**Zemin:** `--dusk-deep`'ten `--dusk`'a dikey gradyan + `SKShader` ile çok hafif film grain (opaklık %3). Tahta alanının arkasında %6 opaklıkta dev bir yaprak damarı deseni.

**Arı uçuşu (§2.3):** tahtanın z-katmanında en üstte. Aynı anda maks 3, fazlası kuyrukta.

**Rüzgâr göstergesi** (seviye 86+): HUD'un altında 28 pt yüksekliğinde şerit. "3 hamle sonra ⇄" + etkilenecek iki kap `--erguvan` kenarlıkla işaretlenir. Sayaç azaldıkça kenarlık kalınlaşır.

**Arı bütçesi göstergesi** (seviye 116+): Levha şeridinin sağında `12/16` — aşılırsa kırmızıya döner ama **oyun devam eder**, sadece yıldız düşer.

---

### 3.6 Duraklat (sheet, 320 pt)

Başlık `display-m` "Ara" · Satırlar: Ses (toggle), Haptik (toggle), Renk körlüğü (toggle), Azaltılmış hareket (toggle) · Butonlar: Primary "Devam", Secondary "Seviyeye baştan başla", Ghost "Patikaya dön".
Sheet açıkken oyun tahtası 8 pt blur + %40 karartma. Ortam sesi %30'a düşer, kesilmez.

---

### 3.7 Seviye tamam (tam ekran)

**Sekans (toplam 2,6 sn, dokunulunca atlanır):**

| t (ms) | Olay |
|---|---|
| 0 | Son çiçek açar, tahta 300 ms'de %0 opaklığa solar |
| 300 | Levha şeridindeki çiçekler ekran ortasına toplanır, birleşir |
| 900 | **Levha presi:** kâğıt yukarıdan iner, 620 ms `motion-plate`, `--rigid` haptik, kâğıt bastırma sesi |
| 1520 | Yıldızlar tek tek belirir (180 ms arayla), her biri `.light` haptik |
| 2060 | Tohum sayacı yukarı sayar (600 ms, `numeric-l`) |
| 2660 | Butonlar alttan kayar |

```
┌─────────────────────────────────────┐
│                                     │
│         ╭───────────────╮           │
│         │               │           │  Levha 200×260
│         │  [levha]      │           │  kâğıt #EDE8DC
│         │               │           │  hafif rotasyon −1,5°
│         ╰───────────────╯           │
│                                     │
│        Papaver noctis               │  display-m Fraunces
│         ★  ★  ★                     │  32 pt --pollen
│                                     │
│      🌾 +15    32/32 hamle          │  numeric-l
│                                     │
│      ÇAYIR ▓▓▓▓▓▓▓▓▓▓▓░ 11/12       │  albüm ilerleme, 6 pt
│                                     │
│  ┌───────────────────────────────┐  │
│  │  ▶  Ödülü ikiye katla         │  │  Rewarded buton (R4)
│  └───────────────────────────────┘  │
│  ┌───────────────────────────────┐  │
│  │        Sıradaki seviye        │  │  Primary
│  └───────────────────────────────┘  │
│          Herbaryum'a bak             │  Ghost
└─────────────────────────────────────┘
```

> **Yıldız eşiği notu (27 Ağustos 2026).** Bu karede 3★ gösterildiği için hamle
> sayısı optimalle eşitlendi. Karar: **3★ yalnızca tam optimal çözümde**, 2★
> için tolerans `M* × 1,25`, üstü 1★ (bkz. `docs/gdd.md` §8.3). Önceki taslakta
> yazan 34/32 bu eşiklerle 2★ olurdu.

**Interstitial mantığı:** "Sıradaki seviye"ye basılınca §6.2'deki 8 kural değerlendirilir. Gösterilecekse: 200 ms `--dusk` perde → interstitial → kapanınca doğrudan yeni tahta. **Reklam öncesi hiçbir metin veya sayaç gösterilmez.**

**Albüm tamamlandıysa** (12/12): "Sıradaki seviye" yerine önce cam fanus animasyonu (1,8 sn) + tam ekran kutlama + "Bahçene bir bitki eklendi" toast'ı.

---

### 3.8 Herbaryum

```
┌─────────────────────────────────────┐
│ ‹  Herbaryum            134 / 500   │  üst bar 56
├─────────────────────────────────────┤
│ [Çayır] [Orman] [Kıyı] [Bozkır] ... │  yatay albüm sekmeleri 40 pt
├─────────────────────────────────────┤
│  ┌───┐ ┌───┐ ┌───┐                  │
│  │🌸 │ │🌼 │ │🌺 │                  │  3 sütun, 103×138
│  └───┘ └───┘ └───┘                  │  boşluk 12
│  ┌───┐ ┌───┐ ┌───┐                  │
│  │🌷 │ │ ? │ │ ? │                  │  kilitli: koyu + seviye no
│  └───┘ └───┘ └───┘                  │
│              ⋮                       │
├─────────────────────────────────────┤
│ ░░░░░ adaptive banner 50 ░░░░░░░░░ │  ← banner BURADA olur
├─────────────────────────────────────┤
│  🌱      📖       🪴       🍯       │
└─────────────────────────────────────┘
```

**Levha detayı (tam ekran):** Zemin `--dusk-deep`. Levha 300 × 400, hafif eğik, cihaz eğimiyle ±3° paralaks (CoreMotion). Altında tür adı `display-m` Fraunces, keşif tarihi `caption`, hamle/yıldız. Butonlar: Primary "Paylaş", Ghost "Tekrar oyna".
**Paylaş çıktısı:** 1080 × 1920, levha + `--dusk` zemin + altta küçük "Bloomsort" imzası. Watermark küçük ve zarif — utangaç değil, saldırgan da değil.

---

### 3.9 Bahçem

Tam ekran diorama, yatay kaydırılabilir (2,5 ekran genişliğinde). Işık ve palet gerçek saate ve mevsime göre kayar (sabah/öğlen/akşam/gece × 4 mevsim = 16 kombinasyon, tek gradyan tablosundan).
Sağ altta `plus.circle` FAB (56 pt, `--pollen`) → **Düzenleme modu**: alttan 180 pt yüksekliğinde kozmetik rafı açılır, öğeler sürüklenip bırakılır; ızgara yok, serbest yerleştirme, `--dew` renkli hizalama kılavuzu.
Boş durum: "Bir albüm tamamla, bahçene ilk bitkin dikilsin." + Ghost "Herbaryum'a git".

---

### 3.10 Kovan (Mağaza)

Sıra: 1) Aktif teklif (varsa) 2) Reklamsız 3) Arı paketleri 4) Mevsim Geçişi 5) Temalar 6) Satın almaları geri yükle (Ghost).

**Reklamsız kartı** (yükseklik 132, `--moss`, 2 pt `--pollen` kenarlık):
başlık "Reklamsız" `title` · gövde `caption`: "Interstitial ve banner reklamlar kapanır. Ödüllü videoların verdiği her şey tek dokunuşla ücretsiz gelir." · sağda fiyat Primary buton.

**Başlangıç paketi** (yalnızca D2, 48 saat): `--erguvan` kenarlık, sağ üstte geri sayım pill'i, "%55 indirim" rozeti. **En fazla 1 kez gösterilir, kapatılınca bir daha gelmez.**

Satın alma başarısız: toast `--ember` — "Satın alma tamamlanmadı. Ücret alınmadı." + Ghost "Tekrar dene". **Asla özür dileme, asla belirsiz olma.**

---

### 3.11 Mevsim yolu

Yatay kaydırılan 40 basamak. İki şerit: üst = Ücretsiz (`--moss`), alt = Geçiş (`--erguvan`, kilitliyse %40 opaklık + asma kilit). Mevcut basamak `--pollen` kenarlıklı ve merkezde. Üstte "Sonbahar · 14 gün kaldı" + yıldız sayacı.

---

### 3.12 Ayarlar

Gruplar: **Oyun** (Ses, Müzik, Haptik, Azaltılmış hareket, Renk körlüğü modu) · **Hesap** (Satın almaları geri yükle, İlerlemeyi sıfırla — Destructive + çift onay) · **Gizlilik** (Reklam tercihlerini yönet → UMP formu, Gizlilik politikası, Kullanım koşulları) · **Hakkında** (Sürüm, İletişim, Değerlendir).

---

## 4. Reklam Yerleşim Haritası (ekran bazında)

| Ekran | Banner | Interstitial | Rewarded | App Open |
|---|---|---|---|---|
| Açılış | — | — | — | ✓ (4 saatte 1, D0 hariç) |
| Onboarding (Sv 1-5) | — | — | — | — |
| Patika | ✗ | — | — | — |
| Oyun ekranı | **✗ asla** | — | R1, R2, R3 (alt çubuktan) | — |
| Seviye tamam | ✗ | ✓ (8 kural) | R4 | — |
| Herbaryum | ✓ | — | — | — |
| Bahçem | ✓ | — | — | — |
| Kovan | ✓ | — | — | — |
| Ayarlar | ✓ | — | — | — |
| Seri kırıldı | — | — | R5 | — |
| Günün Çiçeği | — | — | R6 | — |
| Mevsim | ✓ | — | R7 | — |

---

## 5. Erişilebilirlik

| Alan | Uygulama |
|---|---|
| **VoiceOver** | Her kap: `"Kap 3. 4 kapasiteli. Üstte sarı polen. 2 dolu."` · Hamle sonrası duyuru: `"Sarı polen kap 3'ten kap 7'ye taşındı."` · Çiçek açma: `"Kap 5 çiçek açtı. 4 renk kaldı."` |
| **Renk körlüğü** | Ayarlardan açılır. 8 polen rengine sembol eklenir (§1.2). Ayrıca üç hazır palet: Deuteranopia, Protanopia, Tritanopia. |
| **Dynamic Type** | `body`/`caption` tam ölçeklenir. Oyun tahtası ölçeklenmez (düzen kritik) ama uzun basma büyütme sunar. |
| **Azaltılmış hareket** | §1.7. Sistemden okunur + bağımsız anahtar. |
| **Dokunma hedefi** | Her etkileşimli öğe ≥ 44 × 44 pt. |
| **Kontrast** | Tüm metin ≥ 4,5:1; büyük metin ≥ 3:1. Doğrulandı §1.1. |
| **Ses bağımsızlığı** | Hiçbir bilgi yalnızca sesle iletilmez. |
| **Sol elli mod** | Alt eylem çubuğu simetrik olduğu için gereksiz. |

---

## 6. Boş, Hata ve Kenar Durumları

| Durum | Ekran | Metin | Eylem |
|---|---|---|---|
| İnternet yok | Herhangi | "Çevrimdışısın. Oynamaya devam edebilirsin; ilerlemen cihazında saklanıyor." | Kapat |
| Rewarded reklam yüklenemedi | Ön-diyalog | "Şu an gösterilecek reklam yok. Ödülü yine de aldın." | Ödülü ver (günde 3 kez) |
| Rewarded 4+ başarısızlık | Ön-diyalog | "Şu an gösterilecek reklam yok. Birazdan tekrar dene." | Kapat |
| Satın alma başarısız | Kovan | "Satın alma tamamlanmadı. Ücret alınmadı." | Tekrar dene |
| Geri yükleme boş | Kovan | "Bu Apple Kimliği'nde geri yüklenecek satın alma yok." | Kapat |
| Herbaryum boş | Herbaryum | "Henüz levha yok. İlk seviyeyi bitir, ilki preslensin." | "Patika'ya git" |
| Bahçe boş | Bahçem | "Bir albüm tamamla, bahçene ilk bitkin dikilsin." | "Herbaryum'a git" |
| Seviye çözülemez hâle geldi | Oyun | *(oluşamaz — üretici garanti eder; yine de savunma amaçlı)* Toast: "Bu tahta çıkmaza girdi. Son hamleni geri alalım." | Otomatik geri al |
| Uygulama arka plana atıldı | Oyun | Durum anında kaydedilir, ortam sesi durur | Dönünce aynı tahta |
| Düşük pil / güç tasarrufu | Global | Parçacıklar %50 azalır, 30 fps'e düşülür | — |

---

## 7. Claude Design Teslim Listesi

Aşağıdaki her madde ayrı bir tasarım karesidir (393 × 852):

1. Açılış · 2. Onboarding Sv1 (işaret hâli) · 3. Patika (varsayılan) · 4. Patika (ilk açılış) · 5. Seviye kartı sheet · 6. **Oyun ekranı — 8 kap, seçim yok** · 7. **Oyun ekranı — kaynak seçili** · 8. **Oyun ekranı — arı uçuşta** · 9. **Oyun ekranı — çiçek açma anı** · 10. Oyun ekranı — 15 kap yoğun tahta · 11. Oyun ekranı — kilitli tomurcuk + çiy · 12. Oyun ekranı — rüzgâr göstergesi · 13. Duraklat sheet · 14. Seviye tamam (3★) · 15. Seviye tamam (albüm tamamlandı) · 16. Rewarded ön-diyalog · 17. Herbaryum ızgara · 18. Levha detayı · 19. Paylaş kartı (1080×1920) · 20. Bahçem (yaz/gece) · 21. Bahçem (kış/sabah) · 22. Bahçem düzenleme modu · 23. Kovan · 24. Başlangıç paketi teklifi · 25. Mevsim yolu · 26. Ayarlar · 27. Boş durumlar (3'lü) · 28. App Store ekran görüntüleri (5'li set)

**Ayrıca:** renk paleti kartı, tipografi ölçeği kartı, bileşen kütüphanesi kartı (buton/kap/pill/kart tüm durumlarıyla), ikon seti (SF Symbols eşleşme tablosu), hareket zaman çizelgesi (çiçek açma ve levha presi için kare kare).
