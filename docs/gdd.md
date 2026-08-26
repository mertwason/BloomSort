# BLOOMSORT — Oyun Tasarım Dokümanı (GDD)

**Çalışma adı:** Polen · **Mağaza adı adayı:** Bloomsort
**Platform:** iPhone (iOS 17+), dikey · **Teknoloji:** SwiftUI + SpriteKit
**Ekip:** 1 kişi + Claude · **MVP:** 6 hafta
**Doküman tarihi:** 26 Ağustos 2026 · **Sürüm:** 1.0

---

## 0. Karar Zinciri (bu tasarım neye dayanıyor)

### 0.1 Online trendlerde ilk 3 (Ağustos 2026)

| # | Trend | Kanıt | Oyuna dönüşebilirliği |
|---|---|---|---|
| **1** | **Cozy / sakinlik / "sessiz kaçış"** | Cozy oyun kategorisi kültürel ve ticari olarak büyüyor; oyuncular pazar raporlarından önce yorumlarda "stressiz oynayabildiğim bir oyun" diye talep ediyor. Cottagecore ve doğa esinli dünyalar 2026'da hâlâ yükselişte. Casual oyuncuların çoğunluğu oyunu rahatlamak için seçiyor. | **Çok yüksek.** Tema, his, palet, ses, zorluk eğrisi — hepsi tek bir yönde hizalanabiliyor. Uzun ömürlü (moda değil, davranış değişimi). |
| 2 | **Nostalji** (2010'lar realite TV, çocukluk fotoğrafı geçişleri, "ebeveynimle aynı yaştayken") | TikTok/Instagram'da Ağustos 2026'nın en büyük formatları nostalji tabanlı. | Orta. Format bağımlı, 3-6 ayda tükenir, 500 seviyelik içeriğe ölçeklenmez, telif riski yüksek. |
| 3 | **Otantiklik / "AI slop" karşıtlığı** (düşük prodüksiyon, el yapımı, insan izi) | Hootsuite 2026 raporu ve platform verileri: cilalı marka içeriği düşüşte, tek çekim/ham içerik yükselişte. | Düşük (tema olarak). Bu bir **konumlandırma** trendi, tema değil. → Pazarlama stratejisine dahil edildi, temaya değil. |

**Seçim: #1 — Cozy / doğa / sessiz kaçış.** Tek başına hem temayı, hem tonu, hem de mağaza görselinin dilini belirliyor. Trend #3 tema olarak değil, **UA yaratıcı stratejisi** olarak kullanılıyor (cilalı 3D render yerine, tek çekim "el telefondan oynuyor" formatı).

### 0.2 Mekanik seçimi: yükselişteki alt tür = **Sort (sıralama) bulmaca**

| Alt tür | 2026 durumu | Karar |
|---|---|---|
| Match-3 | Yoğun doygun, 5+ yaşındaki devlerin tekelinde | ✗ |
| Blast | Pazar payı kaybediyor, Sort'un altına düştü | ✗ |
| Merge | Plato, winner-takes-all | ✗ |
| **Sort** | **2026 başında Pixel Flow ile Blast'ı geçip IAP gelirinde 3. büyük bulmaca alt türü oldu. Reklam geliri katılınca eşiği daha önce aşmıştı.** | **✓ Seçildi** |
| Screw / Block | Yükselişte ama fizik/3D yükü solo ekip için ağır | ✗ |

**Hybrid-casual bağlamı:** IAP geliri büyüyen tek casual segment (+%20 → $4,2 milyar), büyüme hybrid-casual bulmacada yoğunlaşmış. Sensor Tower: hybrid-casual lifestyle & puzzle geliri %59 IAP / %41 reklam.

**Neden taklit değil:** Sektörün kendi teşhisi şu — bir sonraki atılım tamamen yeni bir mekanikten değil, **bilinen öğelerin daha akıllı birleşiminden** gelecek. Bu oyunun birleşimi:

> **Su sıralama çekirdeği** (kanıtlanmış, bilişsel olarak affedici)
> **+ taşıyıcı ajan** (arı — hamle anında değil, zaman içinde çözülür → Pixel Flow'un "tahta canlı kalır" hissi, ama sakin)
> **+ kap kapasitesi çeşitliliği** (zorluk kadranı, prosedürel üretim için ideal)
> **+ tamamlanan kabın tahtadan çiçek açarak ayrılması** (tahta dinamik, alan açılıyor)
> **+ her seviyenin bir botanik levhaya dönüşmesi** (Pixel Flow'un "eser açığa çıkıyor" dersi, doğa temasına uygulanmış)

### 0.3 Rakip boşluğu

| Oyun | Duygusal sözleşme | Zayıf noktası | Bizim açığımız |
|---|---|---|---|
| Magic Sort (Grand Games) | Konfor | Agresif reklam yükü konforu bozuyor; ARPDAU zirveden düştü | Reklamı **oyun tahtasından tamamen çıkarmak** |
| Knit Out (Take-Two) | Yetkinlik | Bilişsel yük yüksek, "sakin" değil | Sıfır ceza, sıfır zaman baskısı |
| Pixel Flow | Yoğunluk | Gürültülü, hızlı, akşam oynanmaz | Akşam/wind-down anını sahiplenmek |
| Magic Sand Sort | Fizik hissi | Meta ilerleme yok → D30 zayıf | Herbaryum + Bahçe meta katmanı |

**Konumlandırma cümlesi:** *Günün sonunda, ışığı kısıp oynadığın sıralama oyunu.*

---

## 1. Vizyon

Bloomsort, akşam saatlerinde telefonu eline alan, kafasını boşaltmak isteyen 25-45 yaş casual bulmaca oyuncusu için tasarlanmış, alacakaranlıkta geçen bir polen sıralama oyunudur. Oyuncu, arılara polen taşıtarak çiçek kaplarını tek renge indirir; her dolan kap çiçek açar ve tahtadan ayrılır. Seviye bitince açılan çiçekler bir **botanik levhaya** dönüşür ve oyuncunun Herbaryum'una preslenir. Zaman yok, can yok, kaybetme yok, ceza yok. Tek gerilim kaynağı, oyuncunun kendi çözüm arayışıdır — ve o gerilim çözüldüğünde ekran çiçek açar.

**Üç kelime:** Alacakaranlık. Sabır. Açılış.

---

## 2. Çekirdek Mekanik

### 2.1 Nesneler

| Nesne | Tanım | Kural |
|---|---|---|
| **Kap (vessel)** | Çiçek kabı. LIFO yığın. | Kapasite C ∈ {3,4,5,6}. Boş, kısmi veya dolu. |
| **Polen (bead)** | Renkli polen tanesi. | K renk. Her rengin toplam adedi = o rengi tutacak kabın kapasitesi. |
| **Arı (bee)** | Taşıyıcı + ekstra boş kap kaynağı. | Sarf edilebilir. Tahtaya geçici boş kap ekler. |

### 2.2 Girdi (jestler)

| Jest | Sonuç |
|---|---|
| Kaba **tek dokunuş** (seçili değilken) | Kaynak seçilir. Üstteki polen 8pt yükselir, kap 4pt yukarı zıplar, hafif haptik (`.soft`). |
| Başka bir kaba **tek dokunuş** | Hamle yasalsa uygulanır, değilse kap 6pt yatay titrer + `.warning` haptik. |
| Aynı kaba **tekrar dokunuş** | Seçim iptal. |
| Kaynaktan hedefe **sürükleme** | Aynı hamle (dokunma alternatifi, keşfedilebilirlik için). |
| Tahtada **iki parmak dokunuş** | Geri al. |
| Kaba **uzun basma (0.4s)** | Kap içeriğini büyütülmüş gösterir (erişilebilirlik + kalabalık tahtalar). |

### 2.3 Hamle kuralı

Kaynak `S` → Hedef `D` yasaldır ⟺
1. `S` boş değil, **ve**
2. `D` dolu değil, **ve**
3. `D` boş **veya** `top(D).renk == top(S).renk`

**Toplu taşıma:** `top(S)` üzerindeki ardışık aynı renkli `m` tanenin `min(m, boşluk(D))` kadarı **tek hamlede** taşınır. Arı `m` kez gidip gelir (görsel), sayaçta **1 hamle** yazar.

### 2.4 Kazanma

Her kap ya **boş** ya da **tek renkle dolu**. Kaybetme durumu yoktur; sıkışan oyuncu için Geri Al / Sıfırla / İpucu / +Arı her zaman erişilebilir.

### 2.5 Çiçek açma (bloom)

Bir kap tek renkle dolduğu **an**:
1. 120ms bekleme (oyuncu görsün)
2. Petaller açılır — 6 yaprak, 420ms, `spring(response: .42, damping: .68)`
3. Polen tozu parçacığı patlar (`SKEmitterNode`, 24 parçacık, 700ms)
4. Kap tahtadan yükselir ve üstteki **levha şeridine** uçar (520ms)
5. Kap yerini boşaltır → **tahtada alan açılır** (bu, ilerledikçe nefes aldıran dinamik)
6. Pentatonik notada ses: yığın derinliğine göre yükselen nota (bkz. §7.3)

### 2.6 Fizik / animasyon notları

- Arı uçuşu: kaynak → hedef arası **kuadratik Bézier**, kontrol noktası orta noktanın 40pt üstünde, süre `0.34s + 0.04s × mesafe/100`, `easeInEaseOut`. Arkasında 5 noktalı sönümlenen iz.
- Polen düşüşü: `SKAction.move` + `.easeIn`, 180ms, ardından 60ms 6% squash.
- Kaplar `SKShapeNode` — parametrik bezier. Elle çizilmiş asset yok.
- 60 fps hedefi; tahtada aynı anda en fazla 3 arı animasyonu, fazlası kuyruğa alınır.

---

## 3. Core Loop ve Oturum Tasarımı

### 3.1 Döngü

```
Patika'da sıradaki tomurcuk → seviye (35-90 sn) → çiçekler açılır →
levha preslenir (Herbaryum +1) → tohum + yıldız ödülü →
[her ~4 seviyede bir albüm ilerleme geri bildirimi] → sıradaki tomurcuk
```

- **Mikro döngü (35-90 sn):** hamle → polen yerleşir → kap dolar → çiçek açar
- **Orta döngü (4-6 dk / oturum):** 8-14 seviye → 1 albüm sayfası ilerlemesi
- **Makro döngü (gün):** Günün Çiçeği + seri + mevsim yolu görevleri
- **Uzun döngü (28 gün / mevsim):** mevsim yolu tamamlama → bahçeye kalıcı bitki

### 3.2 İdeal oturum (4,5 dk)

| Sn | Olay |
|---|---|
| 0-3 | Uygulama açılır, Patika son konumda, sıradaki tomurcuk nabız atıyor |
| 3-8 | Günün Çiçeği rozeti varsa 1 kez gösterilir (kapatılabilir, ısrarcı değil) |
| 8-95 | Seviye 1 |
| 95-105 | Levha presi + ödül |
| 105-115 | Interstitial (kurallar §6.2'ye uyuyorsa) |
| ... | 8-14 seviye tekrar |
| Son | Albüm sayfası dolar → cam fanus animasyonu → doğal duruş noktası |

**Günlük dönüş sebepleri (üç bağımsız kanca):**
1. **Günün Çiçeği** — 24 saat, o güne özel levha, kaçarsan bir daha o levha gelmez (FOMO ama nazik: yıl sonunda "kayıp günler" telafi paketi)
2. **Seri (streak)** — 3/7/14/30 günde artan tohum çarpanı; kaçırınca 1 kez ücretsiz onarım + rewarded ile ikinci onarım
3. **Bahçe büyümesi** — dikilen bitkiler gerçek zamanda büyür; 12/24/48 saatte görsel evre değiştirir

---

## 4. Seviye ve İçerik Sistemi

### 4.1 Prosedürel üretim — ters hamle yöntemi

Üretim **çözülmüş durumdan geriye** çalışır; bu, çözülebilirliği matematiksel olarak garanti eder.

```
girdi: K (renk), E (boş kap), Cmix (kapasite dağılımı), R (karıştırma derinliği), seed
1. Çözülmüş durum kur: K kap, her biri tek renkle dolu + E boş kap
2. R kez: rastgele yasal TERS hamle uygula
   (ters hamle = dolu bir kabın üstünden j tane alıp,
    yasal olacak şekilde başka bir kaba koymak)
3. Aynı duruma dönülmüşse (hash) veya renk sayısı düşmüşse adımı at
4. IDA* çözücü çalıştır → M* (minimum hamle)
5. KABUL koşulları:
   - çözülebilir (garanti, ama doğrula)
   - M* ∈ [Mmin(seviye), Mmax(seviye)]
   - ilk 3 hamlede "otomatik" çözülen kap sayısı ≤ 1  (bayat tahta filtresi)
   - dallanma faktörü ≥ 2,2  (tek yol yok → nefes payı var)
6. Reddedilirse seed++ ve 1'e dön
çıktı: {id, seed, K, E, Cmix, obstacles, M*}  ≈ 80 bayt/seviye
```

**500 seviye = ~40 KB JSON.** Üretim ve doğrulama çevrimdışı (Swift CLI target), oyun sadece seed'i çözüp tahtayı kurar. Aynı seed her cihazda **aynı tahtayı** verir → tam determinizm, her oyuncuda aynı deneyim, adil yıldız karşılaştırması.

### 4.2 Zorluk eğrisi

| Seviye | Renk K | Boş kap E | Kapasite | Yeni mekanik | Hedef M* | Hedef süre |
|---|---|---|---|---|---|---|
| 1-3 | 2 | 2 | 4 | *Öğretici (rehberli)* | 3-6 | 20 sn |
| 4-10 | 3-4 | 2 | 4 | — | 8-14 | 35 sn |
| 11-25 | 5-7 | 2 | 4 | 8. seviyede 2. boş kap açıklanır | 16-26 | 50 sn |
| 26-40 | 6-8 | 2 | **3/4/5/6 karışık** | **Kapasite çeşitliliği** | 22-34 | 65 sn |
| 41-60 | 7-9 | 2 | karışık | **Kapalı tomurcuk** — kap kilitli, X polen başka yere yerleşince açılır | 26-40 | 75 sn |
| 61-85 | 8-10 | 2-3 | karışık | **Çiy damlası** — bir polen donmuş; üstüne 2 hamle yapılınca çözülür | 30-46 | 85 sn |
| 86-115 | 8-10 | 2-3 | karışık | **Rüzgâr** — 5 hamlede bir iki kabın üstü yer değiştirir; **3 hamle önceden gösterilir** | 34-52 | 95 sn |
| 116-150 | 9-11 | 3 | karışık | **Arı bütçesi** — yumuşak hamle limiti; aşmak seviyeyi kaybettirmez, sadece yıldızı düşürür | 38-58 | 100 sn |
| 151-500+ | 9-12 | 2-4 | karışık | Her 15 seviyede engel kombinasyonu rotasyonu | 40-70 | 90-120 sn |

**Kritik tasarım kuralı:** Rüzgâr rastgele **değildir**. Hangi iki kabın, kaçıncı hamlede yer değiştireceği üst barda bir rüzgâr göstergesiyle 3 hamle önceden bildirilir. Sürpriz ceza, "kontrol hissi" sözleşmesini bozar — ve bu sözleşme bozulduğunda ARPDAU düşer (Magic Sort vakası).

**Zorluk zikzağı:** Her 5 seviyede bir kasıtlı **kolay seviye** (M* hedef bandın %60'ı). Sürekli tırmanış yorar; nefes alma seviyeleri D7'yi korur.

### 4.3 500+ seviyeye ölçeklenme

- **Lansman:** 200 doğrulanmış seviye (~2 hafta oyun)
- **+2 hafta:** üretici %100 otomatik olduğu için 300 seviye daha eklemek 1 saatlik iş (üret → doğrula → JSON'a yaz)
- **Levha çeşitliliği:** 12 parametrik çiçek türü × 8 renk paleti × 6 dizilim = 576 görsel olarak ayırt edilebilir levha, sıfır elle çizim
- **İçerik tükenirse:** "Sonsuz Çayır" modu — aynı üreticiden canlı seviye, levha ödülü yok, sadece tohum

---

## 5. Retention Sistemleri

### 5.1 Herbaryum (ana koleksiyon)

- Her tamamlanan seviye → **1 botanik levha**
- 12 levha = 1 **albüm** ; albüm = biyom: Çayır, Orman Altı, Kıyı, Bozkır, Yayla, Bahçe, Sulak, Kayalık...
- Levha detayı: büyük görsel, tür adı (üretilen Latince-benzeri ad, ör. *Papaver noctis*), "keşif tarihi", hamle sayısı, yıldız
- **Paylaş** butonu → 1080×1920 levha kartı (organik UA kanalı; trend #3 ile hizalı: cilasız, kişisel)
- Albüm tamamlanınca → **cam fanus** trofesi + bir bahçe bitkisi + bir tema parçası

### 5.2 Bahçem

- Tamamlanan her albüm bahçeye kalıcı bir bitki diker
- Bitkiler **gerçek zamanda** büyür (fide → gelişmiş → çiçekli), 12/24/48 saatlik evreler
- Kozmetik yerleştirme: saksı, fener, taş, kelebek, kuş, çeşme — tohumla veya IAP ile
- Mevsim değişince bahçenin ışığı ve paleti gerçek takvime göre kayar

### 5.3 Seri (streak) ve Günün Çiçeği

- Günde 1 seviye = seri devam. 3/7/14/30 gün → tohum çarpanı ×1,2 / ×1,5 / ×2 / ×3
- Kaçırınca: 1 ücretsiz onarım/ay + rewarded video ile 1 onarım daha
- Günün Çiçeği: o güne özel tek levha, 24 saat

### 5.4 Mevsim (28 gün)

- Yıldız toplayarak ilerleyen 40 basamaklı yol
- **Ücretsiz şerit:** tohum, arı, 1 kozmetik, 2 özel levha
- **Mevsim Geçişi (₺179,99):** 8 kozmetik, arı damlası, 6 özel levha — **oyun avantajı yok, sadece kozmetik ve kolaylık**
- Gerçek mevsimlere bağlı: İlkbahar/Yaz/Sonbahar/Kış levhaları sadece o mevsimde → yıllık dönüş kancası

### 5.5 Hedefler

| Metrik | Skill temel verisi | Güncel veri (2026) | **Bu oyunun hedefi** |
|---|---|---|---|
| D1 | %40+ | %30-35 tipik, lider iOS %35-40 | **%38-42** |
| D7 | %7-8 (üst çeyrek) | %15+ (hybrid-casual lider) | **%10-12** |
| D30 | puzzle medyanı %5,35 | — | **%6-7** |
| Oturum/gün | — | — | 2,4 |
| Oturum süresi | — | — | 4,5 dk |
| CPI (iOS) | ~$2,50 | — | **≤ $1,90** (cozy nişi, düşük rekabet anahtar kelimeleri) |
| LTV | ≥ 1,5 × CPI | — | **≥ $3,20** |

---

## 6. Monetizasyon

**İlke:** Reklam **asla oyun tahtasına dokunmaz.** Sakinlik vaadi ürünün kendisidir; onu satarsak ürünü satmış oluruz. Bütün reklam yükü, oyuncunun zaten "bir seviye bitti" duraklamasında olduğu anlara yerleşir.

### 6.1 Rewarded video (birincil — hedef 4-6 gösterim/DAU)

| # | Yerleşim | Tetik | Ödül | Beklenen gösterim/DAU |
|---|---|---|---|---|
| R1 | **+1 Arı** | Oyuncu Kovan butonuna basar, arısı yok | 1 arı (ekstra boş kap) | 1,4 |
| R2 | **+3 Geri Al** | Ücretsiz 3 geri al bitti | 3 geri al | 0,8 |
| R3 | **İpucu** | İpucu butonu, bankası boş | Çözücüden 1 optimal hamle | 0,7 |
| R4 | **Ödülü ikiye katla** | Seviye bitiş ekranı | Tohum ×2 | 1,1 |
| R5 | **Seri onarımı** | Seri kırıldı ekranı | Seri geri yüklenir | 0,2 |
| R6 | **Günün Çiçeği ikinci hak** | Günün Çiçeği bitti | O günün levhasını tekrar oyna | 0,3 |
| R7 | **Mevsim hızlandırma** | Mevsim yolu, günde 1 kez | +15 yıldız kredisi | 0,4 |

**Kurallar:** Rewarded her zaman **isteğe bağlıdır ve iptal edilebilir.** Reklam yüklenemezse ödül **yine de verilir** (ilk 3 başarısızlık/gün) — oyuncu asla teknik bir hatanın cezasını çekmez.

### 6.2 Interstitial (hedef 3-4/DAU)

Sadece **seviye bitiş → sonraki seviye** geçişinde. Kurallar (hepsi aynı anda sağlanmalı):

1. Seviye ≥ 8 (ilk oturum korunur)
2. Son interstitial'dan bu yana ≥ **90 saniye**
3. Son 45 saniyede rewarded izlenmemiş
4. Arka arkaya iki seviyede gösterilmez
5. 1★ ile biten seviyeden sonra gösterilmez (oyuncu zaten hayal kırıklığında)
6. Saatte en fazla **6**
7. Oturumun ilk 3 dakikasında en fazla 1
8. "Reklamsız" satın almışsa: hiç

### 6.3 App Open

Sadece soğuk başlatmada, 4 saatte en fazla 1, **D0'da hiç** (ilk gün açılış reklamı D1 retention'ı kırar).

### 6.4 Banner

Adaptive anchored. **Sadece** Herbaryum, Bahçem, Kovan ve Ayarlar ekranlarında. Patika ve oyun tahtasında **asla**.

### 6.5 Native (Faz 2)

Herbaryum ızgarasında her 24 levhada bir "sponsorlu sayfa" kartı — levha kartıyla aynı çerçevede, açıkça etiketli.

### 6.6 Mediation ve teknik

- **AdMob** birincil, mediation ile: AppLovin, Unity Ads, Meta Audience Network, Liftoff/Vungle, Mintegral, Pangle
- Bidding + waterfall hibrit; her ad unit için ayrı floor
- **Google UMP** ile GDPR/TCF v2.2 rızası, uygulama ilk açılışında
- **ATT** izni **5. seviye sonunda** (açılışta değil — kabul oranı ~2× artar), öncesinde neden gerektiğini anlatan özel bir ekran
- Yaş derecesi 4+, ancak çocuklara yönelik değil → `tagForChildDirectedTreatment` **ayarlanmaz**, `maxAdContentRating = G`
- Reklam yükleme: her unit için **ön yükleme (preload)**, gösterimden önce hazır değilse **atla** — asla bekleme ekranı gösterme

### 6.7 IAP

| Ürün | Fiyat (TRY / USD) | İçerik |
|---|---|---|
| **Reklamsız** | ₺249,99 / $4,99 | Interstitial + app open + banner kapanır. Rewarded teklifleri **tek dokunuşla ücretsiz verilir** (reklam izlemeden). |
| Arı ×10 | ₺49,99 / $0,99 | |
| Arı ×60 | ₺199,99 / $3,99 | +%20 bonus etiketi |
| Arı ×200 | ₺499,99 / $9,99 | +%60 bonus etiketi |
| Mevsim Geçişi | ₺179,99 / $3,99 | 28 gün, kozmetik + arı damlası |
| Bahçe teması | ₺99,99-₺299,99 | Kozmetik palet + saksı seti |
| **Başlangıç paketi** (D2, 48 saat) | ₺299,99 / $6,99 | Reklamsız + 30 arı + 1 tema (%55 indirim etiketi) |

**Pay-to-win yok.** Arı satın alınabilir ama arı sadece ekstra boş kap = kolaylık; hiçbir seviye arı olmadan çözülemez değildir (üretici bunu garanti eder).

### 6.8 Gelir hedefleri

| Aşama | ARPDAU | Reklam/IAP | Not |
|---|---|---|---|
| Soft launch | $0,05-0,07 | 80/20 | Reklam ağırlıklı, IAP henüz tune edilmemiş |
| Global lansman | $0,09-0,12 | 65/35 | Başlangıç paketi + mevsim devrede |
| Olgun (6. ay) | $0,12-0,16 | 55/45 | Sektör hybrid-casual puzzle ortalaması %59 IAP |

---

## 7. Sanat ve Ses Yönü

### 7.1 Yön: **Alacakaranlık Çayırı**

Cozy oyunların çoğu parlak gündüz pasteline gidiyor. Bu oyun **akşama** yerleşiyor — çünkü hedef an akşam. Koyu zeminde ışıyan polen, App Store ekran görüntüsünde de akış içinde de rakiplerden anında ayrışıyor ve gece oynayan gözü yormuyor.

### 7.2 Palet

| Token | Hex | Kullanım |
|---|---|---|
| `dusk` | `#101E24` | Ana zemin |
| `moss` | `#1D3A36` | Yüzey / kart / panel |
| `mist` | `#E8EDE6` | Birincil metin |
| `pollen` | `#F5C24B` | **Hero aksan** — birincil CTA, arı, polen ışıması |
| `erguvan` | `#A971E8` | İkincil aksan — nadir/premium/mevsim |
| `dew` | `#6FD8C4` | Başarı, su, çiy |

**Polen renkleri (8, sıralama için):** `#F5C24B` sarı · `#E86A5C` mercan · `#A971E8` erguvan · `#6FD8C4` çiy · `#7BB5F0` gök · `#F2A0C8` pembe · `#9BD466` filiz · `#E8925C` kayısı
Her renk **ayrıca bir sembolle** kodlanır (renk körlüğü modu): ● ▲ ■ ◆ ★ ✚ ⬟ ▼

### 7.3 Ses ve ASMR

- **Ortam:** çayır rüzgârı + uzak cırcır böceği + hafif arı uğultusu, 90 sn döngü, kesintisiz
- **İmza:** her polen yerleşince **pentatonik bir nota** çalar; nota, kabın **yığın derinliğine** göre yükselir (1. tane = D, 5. tane = A). Sonuç: oyuncu sıraladıkça tahta müzik çalar. Aynı renk üst üste gelince arpej oluşur.
- Çiçek açma: yumuşak yaprak hışırtısı + tek çan notası
- Levha presi: kâğıt bastırma + ahşap tık
- Arı: uçuş süresince pitch'i mesafeyle değişen düşük uğultu
- Tüm sesler kapatılabilir; **haptik ayrı ayrı** kapatılabilir

### 7.4 Asset üretim planı (elle çizim: sıfır)

| Asset | Üretim yöntemi |
|---|---|
| Çiçek kapları | `SKShapeNode` + parametrik bezier (yaprak sayısı, eğrilik, jitter seed) |
| Polen taneleri | Daire + iç gölge + gaussian glow shader |
| Arı | 5 parçalı vektör, kanat `SKAction` ile 60ms döngü |
| Botanik levhalar | Aynı parametrik çiçek motoru, farklı diziliş + kâğıf dokusu shader |
| Parçacıklar | `SKEmitterNode` (polen tozu, yaprak, ışık) |
| UI ikonları | **SF Symbols** |
| Arka plan | Prosedürel gradyan + 3 katmanlı paralaks silüet + `SKShader` gürültü |
| Bahçe bitkileri | Parametrik L-system, büyüme evresi = tek parametre |
| Sesler | Freesound (CC0) + Logic/GarageBand'de generatif pad |
| Mağaza görselleri | Oyun içi ekran kaydı + AI destekli kompozit |

**Toplam elle üretilecek asset: 0 sprite.** Bu, solo+AI ekibin en kritik kaldıracıdır.

---

## 8. Teknik Mimari

### 8.1 Katmanlar

```
┌──────────────────────────────────────────────┐
│  SwiftUI (kabuk)                             │
│  RootView · TabView · Sheet'ler · Mağaza     │
│  Herbaryum · Bahçem · Ayarlar · Mevsim       │
├──────────────────────────────────────────────┤
│  SpriteKit (yalnızca oyun tahtası)           │
│  BoardScene · VesselNode · BeadNode          │
│  BeeNode · BloomFX · SKEmitter               │
├──────────────────────────────────────────────┤
│  Domain (saf Swift, UI'dan bağımsız)         │
│  GameState (struct) · Move · applyMove()     │
│  Solver (IDA*) · LevelGenerator · Difficulty │
├──────────────────────────────────────────────┤
│  Servisler                                   │
│  AdService · IAPService · Analytics          │
│  AudioEngine · HapticEngine · RemoteConfig   │
├──────────────────────────────────────────────┤
│  Kalıcılık: SwiftData (profil, koleksiyon,   │
│  bahçe) · UserDefaults (ayarlar)             │
│  levels.json (bundle)                        │
└──────────────────────────────────────────────┘
```

### 8.2 Veri modeli (çekirdek)

```swift
struct GameState: Equatable, Hashable {
    var vessels: [Vessel]          // her biri [Bead] + capacity + lock
    var beesUsed: Int
    var moveCount: Int
    var history: [Move]            // geri al için

    var isSolved: Bool { vessels.allSatisfy { $0.isEmptyOrMono } }
    func legalMoves() -> [Move]
    func applying(_ m: Move) -> GameState   // saf, mutasyonsuz
}
```

`GameState`'in **değer tipi ve saf** olması üç şeyi bedava veriyor: geri al (eski state'i tut), çözücü (aynı fonksiyonu arama ağacında kullan), birim testi (UI olmadan 10.000 seviye doğrula).

### 8.3 Çözücü

IDA* + admissible heuristic: `h = (tek renk olmayan kap sayısı) + (kesintiye uğramış renk blokları)`. Transposition table (`Set<GameState.hashValue>`). 12 renk / 15 kap için tipik çözüm < 40 ms.
Kullanım: (a) üretim doğrulama, (b) `M*` → yıldız eşiği, (c) İpucu.

### 8.4 Servisler

| Servis | Seçim | Not |
|---|---|---|
| Reklam | Google Mobile Ads SDK + UMP | Mediation adaptörleri Faz 1'de: AppLovin, Unity |
| IAP | StoreKit 2 | `Transaction.updates` dinleyicisi, sunucu doğrulama yok (MVP) |
| Analitik | Firebase Analytics (ücretsiz) + AdMob bağlantısı | |
| Uzak yapılandırma | Firebase Remote Config | Reklam sıklığı, zorluk çarpanı, A/B |
| Crash | Firebase Crashlytics | |
| Bulut kayıt | CloudKit | **MVP'de yok**, v1.1 |

### 8.5 Analitik olay şeması (çekirdek)

```
level_start      {level_id, attempt, bees_owned, seed}
level_complete   {level_id, moves, optimal_moves, stars, duration_ms, undos, hints, bees_used}
level_abandon    {level_id, moves, duration_ms, last_action}
bee_spend        {source: rewarded|iap|reward|season, level_id}
ad_impression    {unit, placement_id, level_id, ecpm_bucket}
ad_reward_grant  {placement_id, fallback: bool}
iap_purchase     {product_id, price_local, currency}
plate_collect    {plate_id, album_id, album_pct}
album_complete   {album_id, days_since_install}
streak_change    {value, direction}
season_tier_up   {tier, is_pass_holder}
```

**En kritik iki metrik:** `level_abandon` oranı (zorluk eğrisi teşhisi) ve `moves / optimal_moves` dağılımı (seviyenin gerçekten ne kadar zor olduğu).

---

## 9. MVP Kapsamı

### 9.1 Hafta hafta

| Hafta | Çıktı | Bitiş kriteri |
|---|---|---|
| **1** | Domain katmanı: `GameState`, `applyMove`, IDA* çözücü, ters hamle üreticisi. Tamamen headless. | 200 seviye üretilip doğrulanıyor, 40 birim test yeşil, ortalama çözüm süresi < 50 ms |
| **2** | SpriteKit tahta: kaplar, polen, seçim, arı uçuşu, çiçek açma, geri al/sıfırla | Baştan sona 10 seviye oynanabiliyor, 60 fps |
| **3** | Meta: Patika, seviye kartı, seviye bitiş, Herbaryum, SwiftData kayıt | Uygulama kapanıp açılınca ilerleme korunuyor |
| **4** | Monetizasyon: AdMob + UMP + ATT, rewarded R1-R4, interstitial kuralları, StoreKit 2, Firebase | Test reklamları 4 yerleşimde çalışıyor, satın alma ve geri yükleme çalışıyor |
| **5** | Cila: ses motoru + pentatonik nota sistemi, haptik, onboarding, parçacıklar, erişilebilirlik, boş/hata durumları | 5 kişilik oyunlanabilirlik testi, "sakin mi?" sorusuna 5/5 evet |
| **6** | İçerik + çıkış: 200 seviye, 17 albüm, ASO paketi, TestFlight, soft launch (TR, PL, PH, CA) | App Store'da canlı, 3 UA yaratıcısı test ediliyor |

### 9.2 MVP'ye giren / girmeyen

| ✅ MVP'de var | ❌ v1.1+ |
|---|---|
| Çekirdek sıralama + arı + çiçek açma | Bahçem (tam etkileşimli) |
| 200 seviye, 4 engel tipi | Mevsim yolu |
| Herbaryum + levha paylaşımı | Bulut kayıt (CloudKit) |
| Rewarded R1-R4, interstitial, app open, banner | Native reklam |
| Reklamsız + arı paketleri IAP | Mevsim geçişi, temalar |
| Seri + Günün Çiçeği | Sonsuz Çayır modu |
| Renk körlüğü, azaltılmış hareket, VoiceOver | iPad, Widget, Apple Watch |

### 9.3 Claude'a verilecek ilk 5 görev

1. **"Domain paketini yaz."** `GameState`, `Vessel`, `Bead`, `Move`, `applyMove`, `legalMoves`, `isSolved`. Saf Swift, hiçbir UIKit/SpriteKit importu yok. Yanına 25 birim test: toplu taşıma, dolu kaba hamle, boş kaba hamle, kazanma tespiti.
2. **"IDA* çözücüyü yaz."** Yukarıdaki heuristic ile. `solve(_ state: GameState, limit: Int) -> [Move]?`. 12 renkli rastgele 100 durumda ortalama süreyi ölç ve raporla.
3. **"Ters hamle üreticisini yaz."** §4.1'deki 6 adımlı algoritma, kabul filtreleriyle. Bir CLI target olsun: `swift run levelgen --count 200 --out levels.json`.
4. **"`BoardScene`'i yaz."** SpriteKit. Kaplar parametrik `SKShapeNode`, dokunma ile seçim, arı Bézier uçuşu, polen düşüşü, çiçek açma sekansı. `GameState`'i sadece okur, mutasyonu domain'e delege eder.
5. **"`AdService`'i yaz."** Protokol tabanlı (`AdServiceProtocol`) ki testte sahte implementasyon kullanılabilsin. §6.2'deki 8 interstitial kuralını tek bir `canShowInterstitial(context:) -> Bool` fonksiyonunda topla, her kural için birim test yaz.

---

## 10. App Store

### 10.1 İsim adayları

1. **Bloomsort: Cozy Sort Puzzle** ← birincil (hem "bloom" hem yükselen "sort" anahtar kelimesi)
2. **Nightbloom: Pollen Sort**
3. **Petal Path: Calm Sort Puzzle**

> ⚠️ İlk hafta işi: her üçü için USPTO + EUIPO + TÜRKPATENT ve App Store isim çakışması kontrolü.

### 10.2 Alt başlık (30 karakter)

`Sırala, çiçek aç, sakinleş` / EN: `Sort pollen. Bloom. Breathe.`

### 10.3 Anahtar kelimeler (100 karakter, EN)

```
sort,pollen,flower,cozy,calm,relax,zen,puzzle,bloom,garden,botanical,sleep,unwind,color,brain
```

### 10.4 Açıklama taslağı (ilk 3 satır — kesme noktası öncesi)

> Gün bitti. Işığı kıs.
> Polenleri arılarla taşı, her kabı tek renge indir, çiçekler açsın.
> Süre yok. Can yok. Kaybetmek yok.

Devamı: Herbaryum (500+ levha), Bahçem, gerçek mevsimler, sessiz mod, renk körlüğü desteği.

### 10.5 Ekran görüntüsü konseptleri (5)

| # | Görsel | Üst metin |
|---|---|---|
| 1 | Alacakaranlık tahtası, bir kap tam çiçek açma anında, parçacıklar havada | "Sırala. Çiçek açsın." |
| 2 | Yan yana: karışık tahta → çözülmüş tahta | "Süre yok. Kaybetmek yok." |
| 3 | Herbaryum ızgarası, 40+ levha, biri büyütülmüş | "500'den fazla botanik levha" |
| 4 | Bahçem, mevsim geçişi (aynı bahçe yaz/kış) | "Bahçen seninle birlikte büyür" |
| 5 | Telefonu yatakta tutan el, ekran ışığı yüzde | "Uyumadan önceki 5 dakika" |

**Uygulama önizleme videosu (15 sn):** tek çekim, kesme yok, gerçek oynanış, bir çiçek açma ve bir levha presi. Cilalı 3D render **kullanma** — trend #3 (otantiklik) gereği ham oynanış daha iyi dönüşüyor.

---

## 11. Riskler

| # | Risk | Olasılık | Etki | Azaltma |
|---|---|---|---|---|
| **1** | **Sort doygunluğa gidiyor.** Grand Games, Take-Two ve Pixel Flow'un yayıncısı UA'da solo bütçenin 100 katını harcıyor. | Yüksek | Kritik | Head-to-head UA savaşına girme. Organik + ASO + niş anahtar kelime ("cozy sort", "sleep puzzle") + paylaşılabilir levha kartlarıyla büyü. Ölçek hedefi mütevazı: 30-60K DAU. |
| 2 | **Sakinlik vaadi ile reklam yükü çelişir.** Magic Sort'un ARPDAU'sunun zirveden düşmesinin sebebi tam olarak bu. | Orta | Yüksek | Reklamı tahtadan tamamen çıkardık; interstitial 8 kurala bağlı; Remote Config ile sıklık A/B'lenebilir. İlk 100 kullanıcı yorumunda "reklam" kelimesi sıklığını haftalık izle. |
| 3 | **Çiçek açma anı, piksel sanat kadar "scroll durdurucu" olmayabilir.** Pixel Flow'un görsel ödülü nostalji taşıyor; çiçek jenerik görünme riski taşıyor. | Orta | Yüksek | **Bu, 1. hafta test edilecek en riskli varsayım.** Bkz. §11.1. |
| 4 | Kaybetme durumu yok → aciliyet yok → monetizasyon baskısı zayıf | Orta | Orta | Baskıyı "kayıp"tan değil "koleksiyon"dan üret: Günün Çiçeği, mevsim levhaları, albüm boşlukları. |
| 5 | İsim çakışması / marka | Orta | Orta | 1. hafta hukuki kontrol, 3 isim adayı hazır. |
| 6 | Prosedürel seviyeler "elle tasarlanmış" hissi vermeyebilir | Düşük | Orta | Kabul filtreleri (dallanma faktörü, bayat tahta filtresi) + her 5 seviyede kasıtlı nefes seviyesi + ilk 25 seviye elle ayarlanmış seed'ler. |

### 11.1 İlk hafta test edilecek en riskli varsayım

> **"Alacakaranlıkta açan bir çiçek, akışta parmağı durdurur."**

**Test:** Kod yazmadan önce. 3 adet 6 saniyelik video yaratıcısı üret (SpriteKit prototipiyle veya AI görsel üretimiyle):
- A: sadece çiçek açma anı, yakın çekim
- B: tahta çözülüyor → tüm çiçekler arka arkaya açılıyor
- C: levhanın Herbaryum'a preslenmesi

$300 bütçe, Meta + TikTok, tek bir "yakında" açılış sayfasına.

**Karar eşiği:**
- CTR ≥ %1,2 ve tahmini CPI ≤ $2,20 → **devam**
- CTR %0,8-1,2 → görsel yönü revize et, tekrar test
- CTR < %0,8 → **temayı değiştir, mekaniği koru** (sıralama motoru tema-bağımsız yazıldığı için bu ucuz bir pivot)

Bu testin maliyeti $300 ve 4 gün; 6 haftalık geliştirmenin maliyeti bunun 50 katı. Test önce yapılır.

---

## Ek A — Ekonomi dengesi (başlangıç değerleri, Remote Config'den ayarlanabilir)

| Kalem | Değer |
|---|---|
| Seviye ödülü (3★ / 2★ / 1★) | 15 / 10 / 6 tohum |
| Albüm tamamlama | 250 tohum + 5 arı + 1 bahçe bitkisi |
| Günün Çiçeği | 40 tohum + 2 arı |
| Seri çarpanı | 3g ×1,2 · 7g ×1,5 · 14g ×2 · 30g ×3 |
| Başlangıç arısı | 5 |
| Kozmetik fiyatı (tohum) | 400-1.800 |
| Ücretsiz oyuncunun günlük tohum kazancı | ~180 |
| Bir kozmetiğe ücretsiz erişim süresi | ~4-9 gün (satın alma cazip ama zorunlu değil) |

## Ek B — Yerelleştirme (lansman dilleri)

TR, EN, DE, FR, ES, PT-BR, JA, KO, RU, AR.
Oyun tahtasında **hiç metin yok** → yerelleştirme yükü sadece menülerde, ~340 string. Türlerin Latince-benzeri adları çevrilmez (evrensel).
