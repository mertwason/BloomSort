/// Renk paleti — `docs/ui-spec.md` §1.1 ve §1.2.
public enum Palette {

    // MARK: - Çekirdek (§1.1)

    public static let dusk      = RGB(hex: "#101E24")   // uygulama zemini
    public static let duskDeep  = RGB(hex: "#0A1418")   // modal, tahta zemini
    public static let moss      = RGB(hex: "#1D3A36")   // yüzey / kart / panel
    public static let mossHigh  = RGB(hex: "#274A45")   // basılı / vurgulu yüzey
    public static let mist      = RGB(hex: "#E8EDE6")   // birincil metin
    public static let mistDim   = RGB(hex: "#9AAAA4")   // ikincil metin
    public static let pollen    = RGB(hex: "#F5C24B")   // hero aksan
    public static let pollenDeep = RGB(hex: "#C99A2E")  // basılı hâl, gölge
    public static let erguvan   = RGB(hex: "#A971E8")   // premium / mevsim
    public static let dew       = RGB(hex: "#6FD8C4")   // başarı / onay
    public static let ember     = RGB(hex: "#E86A5C")   // uyarı / yıkıcı eylem

    /// Herbaryum levhasının kâğıdı — koleksiyonun tek açık yüzeyi (§2.9).
    public static let platePaper = RGB(hex: "#EDE8DC")
    public static let plateInk    = RGB(hex: "#3A3A32")

    // MARK: - Polen renkleri (§1.2)

    /// Bir polen renginin sunum karşılığı.
    public struct Pollen: Hashable, Sendable {
        /// Domain'deki `PollenColor.index` ile aynı sıra.
        public let index: Int
        public let name: String
        public let color: RGB
        /// Renk körlüğü modunda tanenin merkezine çizilen sembol.
        public let symbol: String
    }

    /// 12 polen rengi.
    ///
    /// İlk 8'i `docs/ui-spec.md` §1.2'den birebir. Son 4'ü sonradan eklendi:
    /// §4.2'nin zorluk tablosu 12 renge çıkıyor ama palet 8 renk tanımlıyordu.
    /// Yeni renkler tahminle değil ölçümle seçildi — hepsi paletin kendi
    /// L*/C* zarfında, `--dusk-deep` zeminine kontrastı ≥ 7 ve diğer bütün
    /// renklerden CIEDE2000 farkı ≥ 16, ki paletin mevcut en yakın çifti
    /// (Mercan ↔ Kayısı) 15,7. `DesignTests` bunu her koşuda doğruluyor.
    public static let pollens: [Pollen] = [
        Pollen(index: 0,  name: "Sarı",     color: RGB(hex: "#F5C24B"), symbol: "●"),
        Pollen(index: 1,  name: "Mercan",   color: RGB(hex: "#E86A5C"), symbol: "▲"),
        Pollen(index: 2,  name: "Erguvan",  color: RGB(hex: "#A971E8"), symbol: "■"),
        Pollen(index: 3,  name: "Çiy",      color: RGB(hex: "#6FD8C4"), symbol: "◆"),
        Pollen(index: 4,  name: "Gök",      color: RGB(hex: "#7BB5F0"), symbol: "★"),
        Pollen(index: 5,  name: "Pembe",    color: RGB(hex: "#F2A0C8"), symbol: "✚"),
        Pollen(index: 6,  name: "Filiz",    color: RGB(hex: "#9BD466"), symbol: "⬟"),
        Pollen(index: 7,  name: "Kayısı",   color: RGB(hex: "#E8925C"), symbol: "▼"),
        Pollen(index: 8,  name: "Lavanta",  color: RGB(hex: "#CDC3FF"), symbol: "○"),
        Pollen(index: 9,  name: "Buz",      color: RGB(hex: "#55E1FF"), symbol: "✖"),
        Pollen(index: 10, name: "Zeytin",   color: RGB(hex: "#AAA569"), symbol: "◗"),
        Pollen(index: 11, name: "Şeftali",  color: RGB(hex: "#FFB4AA"), symbol: "✱"),
    ]

    public static func pollen(_ index: Int) -> Pollen {
        precondition(pollens.indices.contains(index), "Tanımsız polen rengi: \(index)")
        return pollens[index]
    }

    /// Renk körlüğü sembolü, tane merkezine `--dusk-deep` renkte %70 opaklıkta,
    /// 10 pt (§1.2). Yalnızca renk körlüğü modu açıkken çizilir.
    public static let symbolColor = duskDeep.opacity(0.7)
    public static let symbolPointSize = 10.0
}
