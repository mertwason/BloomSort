# BLOOMSORT — Uçtan Uca Lansman Checklist'i

**Hedef:** App Store'da canlı, reklamlar ve satın almalar çalışır durumda.
**Tarih:** 26 Ağustos 2026 · **Gerçekçi süre:** 8-9 hafta (6 hafta geliştirme + paralel hesap işleri + review)

---

## 0. Kim Neyi Yapar

| Görev | Ben (bu sohbet) | Claude Code (Mac'te) | Yalnızca sen |
|---|---|---|---|
| Spesifikasyon, GDD, UI spec, ekonomi tabloları | ✅ | | |
| Claude Code prompt paketi, `CLAUDE.md` | ✅ | | |
| ASO metinleri, review notları, gizlilik politikası taslağı | ✅ | | |
| Swift kodu, testler, `Info.plist`, privacy manifest | | ✅ | |
| `xcodebuild`, arşiv, TestFlight yükleme | | ✅ (senin API key'inle) | |
| Seviye üretimi ve doğrulama | | ✅ | |
| **Apple Developer hesabı, D-U-N-S, sözleşmeler** | ❌ | ❌ | ✅ |
| **AdMob hesabı, ödeme/vergi bilgileri** | ❌ | ❌ | ✅ |
| **Banka/vergi formları, EU trader status** | ❌ | ❌ | ✅ |
| **Şifre, kart, kimlik bilgisi girme** | ❌ | ❌ | ✅ |
| **"Submit for Review" tıklaması** | ❌ | ❌ | ✅ |

**Neden ben yapamıyorum:** Bu sohbette macOS, Xcode, kod imzalama veya App Store Connect erişimi yok. Buradan çıkacak her şey web prototipi olur, gönderilebilir bir `.ipa` olmaz. Hesap açma, sözleşme kabulü ve kimlik/ödeme bilgisi girme işlerini de ilke olarak yapmıyorum — o adımları senin yapman gerekiyor.

**Donanım ön koşulu:** Xcode 26 çalıştırabilen bir Mac. Apple Silicon önerilir, ~40 GB boş disk.

---

## FAZ 0 — HESAPLAR VE HUKUK ⛔ *En uzun kuyruk. Bugün başlat.*

> Bunlar geliştirmeyle **paralel** yürür ama biri eksikse gönderim yapılamaz. D-U-N-S bekleme süresi projeyi tek başına 3 hafta geciktirebilir.

- [ ] **Karar: bireysel mi şirket mi hesap?**
  Şirket (Mokka Teknoloji) → mağazada şirket adı görünür, kurumsal duruş; ama D-U-N-S gerekir.
  Bireysel → 1 günde açılır, mağazada senin adın görünür.
- [ ] **D-U-N-S numarası al** (şirket hesabıysa) — ücretsiz, Dun & Bradstreet üzerinden. **1-3 hafta.** ⛔ *Blocker*
- [ ] Apple Developer Program üyeliği ($99/yıl) — kayıt + kimlik doğrulama
- [ ] App Store Connect: **Paid Apps Agreement** kabulü ⛔ *IAP bu olmadan çalışmaz*
- [ ] Banka hesabı bilgileri girildi (şirket adına, TR IBAN)
- [ ] Vergi formları tamamlandı (W-8BEN-E / TR vergi kimliği) — *bu senin uzmanlık alanın, ben yorum yapmayacağım*
- [ ] **EU trader status** doldurulup doğrulandı ⛔ *DSA gereği; trader status verilmeyen uygulamalar AB App Store'undan kaldırılıyor*
- [ ] Güncellenmiş **yaş derecelendirme sorularına** yanıt verildi (Ocak 2026'dan beri zorunlu)
- [ ] AdMob hesabı açıldı, ödeme profili ve vergi bilgileri girildi
- [ ] **Marka kontrolü:** "Bloomsort" için TÜRKPATENT + EUIPO + USPTO + App Store isim araması ⛔ *3 isim adayı hazır, biri temiz çıkana kadar kod adı kullan*
- [ ] Alan adı alındı (`bloomsort.app` vb.) — gizlilik politikası ve `app-ads.txt` için gerekli
- [ ] Gizlilik politikası + kullanım koşulları sayfası yayında (canlı URL şart)
- [ ] Destek e-postası çalışıyor (`support@...`)

---

## FAZ 1 — GELİŞTİRME ORTAMI

- [ ] **Xcode 26 veya üzeri** kurulu ⛔ *28 Nisan 2026'dan beri App Store Connect'e yüklenen tüm uygulamalar Xcode 26 ve iOS 26 SDK ile derlenmiş olmalı*
- [ ] Deployment target: **iOS 17.0** (SDK 26 ile derle, hedefi düşük tut — cihaz kapsamı genişler)
- [ ] **Liquid Glass kontrolü:** iOS 26 SDK ile derlenen uygulamalar native kontrollerde varsayılan olarak yeni görünümü alır. Tasarımımız özel çizim olduğu için tahtayı etkilemez ama sheet/buton/tab bar'ı görsel olarak test et; istemiyorsan açıkça opt-out yap.
- [ ] Git deposu kuruldu, `CLAUDE.md` repo köküne konuldu
- [ ] Claude Code kuruldu ve depoda çalışıyor
- [ ] Fiziksel test cihazı: en az 1 güncel iPhone + 1 eski iPhone (simülatör yetmez; reviewer gerçek cihazda test eder)

---

## FAZ 2 — ÇEKİRDEK (Hafta 1-2, Claude Code)

- [ ] `GameState`, `Vessel`, `Bead`, `Move`, `applyMove`, `legalMoves`, `isSolved` — saf Swift, UI importu yok
- [ ] 25+ birim test yeşil (toplu taşıma, dolu kap, boş kap, kazanma tespiti, geri al)
- [ ] IDA* çözücü — 12 renk / 15 kap için < 50 ms
- [ ] Ters hamle seviye üreticisi + kabul filtreleri
- [ ] `swift run levelgen --count 200 --out levels.json` çalışıyor
- [ ] **200 seviyenin tamamı çözülebilirlik testinden geçti** (otomatik, CI'da)
- [ ] `BoardScene` (SpriteKit): kaplar, seçim, arı Bézier uçuşu, polen düşüşü, çiçek açma
- [ ] 60 fps doğrulandı (Instruments, eski cihazda)

---

## FAZ 3 — META VE ARAYÜZ (Hafta 3)

- [ ] Patika, seviye kartı, seviye bitiş, Herbaryum, Ayarlar
- [ ] SwiftData şeması + kayıt/yükleme; uygulama kapanıp açılınca ilerleme korunuyor
- [ ] Onboarding seviye 1-8 içinde (ayrı ekran yok, metin bloğu yok)
- [ ] Tüm boş/hata durumları ekranda (UI spec §6)
- [ ] Erişilebilirlik: VoiceOver etiketleri, renk körlüğü modu, azaltılmış hareket, Dynamic Type
- [ ] Dokunma hedefleri ≥ 44×44 pt doğrulandı

---

## FAZ 4 — REKLAM ENTEGRASYONU (Hafta 4) 🔴 *En çok hata buradan çıkıyor*

### 4.1 AdMob tarafı
- [ ] AdMob'da **iOS uygulaması** oluşturuldu → **App ID** alındı (`ca-app-pub-XXX~YYY`)
- [ ] Ad unit'ler oluşturuldu ve isimlendirildi:
  - [ ] `rewarded_bee` (R1)
  - [ ] `rewarded_undo` (R2)
  - [ ] `rewarded_hint` (R3)
  - [ ] `rewarded_double` (R4)
  - [ ] `rewarded_streak` (R5)
  - [ ] `interstitial_level_end`
  - [ ] `app_open`
  - [ ] `banner_meta`
- [ ] **`app-ads.txt`** alan adının köküne yüklendi (`https://bloomsort.app/app-ads.txt`) ve AdMob'da doğrulandı ⛔ *Bu yoksa envanterin büyük kısmı satılamaz*
- [ ] App Store listeleme URL'si AdMob uygulamasına bağlandı (mağazada yayınlandıktan sonra)
- [ ] Mediation ağları: AppLovin + Unity Ads (Faz 1). Her biri için ayrı hesap + adaptör + SKAdNetwork ID'leri.

### 4.2 Uygulama tarafı
- [ ] Google Mobile Ads SDK (SPM ile, güncel sürüm) eklendi
- [ ] `Info.plist` → `GADApplicationIdentifier` = **gerçek App ID**
- [ ] `Info.plist` → **`SKAdNetworkItems`**: Google (`cstr6suwn9.skadnetwork`) + Google'ın yayımladığı üçüncü taraf alıcı listesi + mediation ağlarının kendi ID'leri ⛔ *Eksikse reklam veren senin uygulamanı ölçemez, eCPM düşer*
- [ ] `Info.plist` → `NSUserTrackingUsageDescription` — Türkçe ve İngilizce, dürüst metin
- [ ] **UMP SDK** entegre: her açılışta `requestConsentInfoUpdate`, `loadAndPresentIfRequired`, reklam istemeden önce `canRequestAds` kontrolü
- [ ] **ATT izni 5. seviye sonunda** isteniyor (açılışta değil), öncesinde neden ekranı
- [ ] Ayarlarda "Reklam tercihlerini yönet" → UMP privacy options entry point çalışıyor
- [ ] `AdService` protokol tabanlı yazıldı (testte sahte implementasyon)
- [ ] **8 interstitial kuralı** tek fonksiyonda toplandı, **her kural için ayrı birim test** var
- [ ] Ödüllü reklam yüklenemezse ödül yine de veriliyor (günde 3 kez) — oyuncu teknik hatanın cezasını çekmiyor
- [ ] Reklam ön yükleme (preload) var, gösterimden önce hazır değilse **atlanıyor**, bekleme ekranı yok
- [ ] Oyun tahtasında hiçbir reklam yüzeyi yok (kod düzeyinde doğrula)
- [ ] **Gönderimden önce test ad unit ID'leri gerçekleriyle değiştirildi** ⛔ *Test reklamıyla gönderim = red*
- [ ] Boş banner alanı bırakılmıyor (reklam yoksa alan tamamen kapanıyor)

### 4.3 Bilmen gereken tuzak
Yeni uygulamalarda AdMob ilk günlerde **"ad serving limited"** durumuna alabilir. Bu normaldir; `app-ads.txt` doğrulaması, mağaza bağlantısı ve bir miktar organik trafik sonrası açılır. Lansman gününde eCPM'i değerlendirme — ilk 7-10 gün veri gürültülüdür.

---

## FAZ 5 — SATIN ALMA (Hafta 4)

- [ ] App Store Connect'te ürünler oluşturuldu:
  - [ ] `com.mokka.bloomsort.removeads` — Non-Consumable — ₺249,99
  - [ ] `com.mokka.bloomsort.bees10` / `bees60` / `bees200` — Consumable
  - [ ] `com.mokka.bloomsort.season` — Auto-Renewable veya Non-Consumable (28 günlük → non-consumable önerilir, abonelik yükü ağır)
  - [ ] `com.mokka.bloomsort.starter` — Non-Consumable
- [ ] Her ürünün **görseli, açıklaması ve review notu** dolduruldu, durumu "Ready to Submit"
- [ ] **IAP'ler ilk sürümle birlikte gönderiliyor** ⛔ *Ayrı gönderilirse ilk sürümde çalışmazlar*
- [ ] StoreKit 2: `Transaction.updates` dinleyicisi, `currentEntitlements` ile "Reklamsız" durumu
- [ ] **Satın almaları geri yükle** butonu var ve çalışıyor ⛔ *Yoksa kesin red*
- [ ] Sandbox hesabıyla her ürün uçtan uca test edildi
- [ ] Satın alma iptali / başarısızlığı test edildi (kullanıcıya doğru mesaj, ücret alınmadı bilgisi)
- [ ] "Reklamsız" satın alan kullanıcıda: interstitial + banner + app open kapanıyor, ödüllü teklifler tek dokunuşla ücretsiz veriliyor

---

## FAZ 6 — GİZLİLİK VE UYUMLULUK 🔴 *2026'da en hızlı büyüyen red sebebi*

- [ ] **`PrivacyInfo.xcprivacy`** oluşturuldu (uygulamanın kendisi için)
- [ ] Required Reason API'leri beyan edildi: `UserDefaults` (CA92.1), dosya zaman damgası, sistem boot time — kullanılanlar
- [ ] Üçüncü taraf SDK'ların privacy manifest'leri mevcut ve güncel (GMA SDK 11.2.0+ destekliyor; sürümü kontrol et)
- [ ] Xcode'da **Privacy Report** üretildi ve okundu
- [ ] **App Privacy Labels** App Store Connect'te dolduruldu ve **gerçek veri akışıyla birebir uyuşuyor** ⛔ *Beyan ile gerçek arasındaki uyuşmazlık 2026'da giderek daha sık red sebebi*
  - Toplanan: Identifiers (IDFA — ATT onayı varsa), Usage Data, Diagnostics, Purchases
  - Her biri için "Used for Tracking" işareti doğru mu?
- [ ] Firebase Analytics ve Crashlytics veri toplama beyanı da etiketlerde
- [ ] Yaş derecesi: 4+ · `maxAdContentRating = G` · `tagForChildDirectedTreatment` **ayarlanmadı** (uygulama çocuklara yönelik değil, Kids Category'ye girmiyoruz)
- [ ] KVKK ve GDPR uyumlu gizlilik politikası yayında, uygulama içinden erişilebilir
- [ ] Hiçbir veri kullanıcı onayı olmadan üçüncü tarafa gitmiyor

---

## FAZ 7 — ANALİTİK (Hafta 4)

- [ ] Firebase projesi kuruldu, `GoogleService-Info.plist` eklendi
- [ ] Firebase ↔ AdMob bağlantısı yapıldı
- [ ] GDD §8.5'teki 10 olay şeması implement edildi ve DebugView'da doğrulandı
- [ ] Crashlytics çalışıyor, test crash gönderildi
- [ ] Remote Config parametreleri tanımlandı: interstitial cooldown, min level, saatlik cap, zorluk çarpanı
- [ ] Remote Config varsayılanları uygulamada gömülü (çevrimdışıda bozulmuyor)

---

## FAZ 8 — İÇERİK VE QA (Hafta 5-6)

- [ ] 200 seviye üretildi, doğrulandı, `levels.json` bundle'da
- [ ] Ses motoru + pentatonik nota sistemi çalışıyor
- [ ] Haptik haritası uygulandı, ayrı kapatılabiliyor
- [ ] Uygulama ikonu (1024×1024, alfa kanalı yok, köşe yuvarlatması yok)
- [ ] Tüm ikon boyutları asset catalog'da
- [ ] Launch screen
- [ ] Yerelleştirme: TR + EN (lansman), ~340 string
- [ ] **Cihaz testi:** güncel iPhone + eski iPhone + iPad (uygulama iPhone-only olsa bile iPad'de çalışmalı, reviewer iPad'de test edebilir)
- [ ] Instruments: bellek sızıntısı yok, CPU spike yok, pil tüketimi makul
- [ ] Uçak modunda test: çökme yok, oyun oynanabiliyor, doğru mesajlar
- [ ] Arka plan/ön plan geçişi: oyun durumu korunuyor
- [ ] Düşük pil modunda test
- [ ] 5 kişilik oyunlanabilirlik testi — "sakin hissettin mi?" sorusuna cevaplar

---

## FAZ 9 — APP STORE CONNECT LİSTELEME

- [ ] Bundle ID kaydedildi (`com.mokka.bloomsort`)
- [ ] Uygulama kaydı oluşturuldu, birincil dil TR veya EN
- [ ] İsim (30 karakter) · Alt başlık (30 karakter) · Anahtar kelimeler (100 karakter)
- [ ] Açıklama, Yenilikler, Promosyon metni
- [ ] Kategori: Games > Puzzle (ikincil: Games > Casual)
- [ ] **Ekran görüntüleri** — 6.9" ve 6.5" zorunlu setler, 5 adet (UI spec §10.5 konseptleri)
- [ ] Uygulama önizleme videosu (15-30 sn, gerçek oynanış, tek çekim)
- [ ] Destek URL'si + Pazarlama URL'si + Gizlilik politikası URL'si
- [ ] Fiyat: Ücretsiz · Ülkeler: soft launch için **TR, PL, PH, CA** ⛔ *Global'e açma*
- [ ] İçerik hakları beyanı (tüm içerik özgün, üçüncü taraf materyal yok)
- [ ] Yaş derecelendirme anketi (yeni sistem) dolduruldu
- [ ] Şifreli iletişim / ihracat uyumluluğu sorusu yanıtlandı (HTTPS standart kullanım → muafiyet)

---

## FAZ 10 — REVIEW GÖNDERİMİ 🔴 *4.3 riski en yüksek adım*

- [ ] Release scheme ile arşiv alındı, Organizer'da validate edildi
- [ ] Build App Store Connect'e yüklendi ve işlendi
- [ ] **TestFlight** iç test grubuyla en az 3 gün gerçek kullanım
- [ ] TestFlight'ta reklamlar ve satın almalar doğrulandı
- [ ] **App Review notları yazıldı** (aşağıdaki şablon) ⛔ *Sort bulmacaları 4.3 için yüksek riskli kategori*
- [ ] Demo hesabı gerekmez (giriş yok) — bunu notlarda belirt
- [ ] "Submit for Review" — **sen tıklıyorsun**

### 10.1 Guideline 4.3 riski — bunu ciddiye al

Apple, doygun kategorilerde "mevcut uygulamaların içeriğini ve işlevini tekrarlayan" uygulamaları 4.3(b) altında reddediyor; reviewer çoğu zaman ekran görüntülerini son dönem benzer gönderimlerle karşılaştırıp binary'yi uzun uzun test etmeden karar verebiliyor. Sort bulmaca 2026'da tam olarak böyle bir kategori. Dahası, **tekrarlanan 4.3 redleri geliştirici hesabının kapatılmasına kadar gidebiliyor.**

Azaltma:
- [ ] Görsel yön rakiplerden bariz farklı (alacakaranlık paleti, botanik levha arşivi — bu yüzden "parlak pastel cozy" yönünü seçmedik)
- [ ] Mekanik bükme somut ve gösterilebilir (arı taşıyıcı, değişken kapasite, çiçek açıp tahtadan ayrılma, levha koleksiyonu)
- [ ] Markalama özgün: isim, ikon, tipografi, ses kimliği
- [ ] **Tek uygulama gönder.** Reskin, varyant, "Bloomsort 2" yok. Aynı motordan ikinci bir tema çıkarmak istersen IAP olarak ekle, ayrı bundle olarak değil.
- [ ] Ekran görüntüleri jenerik sort ekranı gibi görünmüyor (ilk görsel çiçek açma anı olmalı, tüpler değil)
- [ ] Review notlarına **1 dakikalık oynanış videosu linki** ekle

### 10.2 App Review notları şablonu

```
Bloomsort is an original cozy puzzle game. No login is required;
all content is available from first launch.

WHAT MAKES THIS APP DISTINCT
Bloomsort uses a colour-sorting core, but the design and presentation
are original to this app:

1. Bee carriers — moves resolve over time as animated carriers transport
   pollen, rather than resolving instantly. This changes pacing and is
   central to the game's calm feel.
2. Variable vessel capacities (3-6) — the difficulty system is built on
   capacity variety, not colour count alone.
3. Bloom-and-leave — a completed vessel blooms and departs the board,
   so the board state changes shape as the level progresses.
4. Herbarium meta-layer — every completed level generates a unique
   procedural botanical plate that is collected into an in-app archive
   of 500+ plates across themed albums. This collection system is the
   core retention loop and is not present in comparable titles.
5. Original art direction — a dusk palette with procedurally generated
   vector flora. All artwork is generated at runtime by our own code.
   No stock, licensed or third-party assets are used.
6. Generative audio — each placement plays a pentatonic note whose pitch
   maps to stack depth, so play produces music.

All levels are procedurally generated by our own solver-validated
generator and are guaranteed solvable.

Gameplay video (1 min): [LINK]

MONETISATION
Ads are never shown during gameplay. Interstitials appear only between
levels, subject to frequency caps. Rewarded video is always optional.
Restore Purchases is available in Settings > Account.

CONTACT: support@bloomsort.app
```

---

## FAZ 11 — LANSMAN SONRASI (İlk 14 gün)

- [ ] Crashlytics günlük kontrol — crash-free users > %99,5
- [ ] `level_abandon` oranı seviye bazında incelendi → zorluk eğrisi düzeltmesi Remote Config'den
- [ ] `moves / optimal_moves` dağılımı → seviyeler gerçekten hedeflenen zorlukta mı
- [ ] D1 ölçüldü — hedef %38-42
- [ ] ARPDAU ölçüldü — soft launch hedefi $0,05-0,07
- [ ] İlk 100 yorumda **"reklam" kelimesinin sıklığı** izlendi 🔴 *Sakinlik vaadimizi bozuyor muyuz göstergesi*
- [ ] AdMob "ad serving limited" durumu çözüldü mü
- [ ] 3 UA yaratıcısı test edildi, CPI ölçüldü — hedef ≤ $1,90
- [ ] **Karar kapısı:** D1 ≥ %35 ve CPI ≤ $2,20 ise global açılış; değilse önce düzelt

---

## Kritik Yol Özeti

Bu üç şey gecikirse proje gecikir, kod ne kadar hızlı yazılırsa yazılsın:

1. **D-U-N-S + Apple Developer onayı** — 1-3 hafta, bugün başlat
2. **Marka temizliği** — isim netleşmeden ASO ve ikon çalışması boşa gider
3. **EU trader status** — atlanırsa AB pazarını lansman gününde kaybedersin

Kod tarafı 6 haftalık iş ve Claude Code'la sıkıştırılabilir. Bunlar sıkıştırılamaz.

---

## Bilerek Yapmadığımız Şeyler

Kapsam kayması bu projenin en gerçek riski. Aşağıdakiler **v1.1'e ertelendi** ve MVP'de tartışmaya kapalı:

Bahçem tam etkileşimli mod · Mevsim yolu · CloudKit bulut kayıt · Native reklam · Mevsim geçişi IAP · Temalar · Sonsuz Çayır modu · iPad özel düzen · Widget · Apple Watch · Game Center liderlik tablosu · Sosyal özellikler
