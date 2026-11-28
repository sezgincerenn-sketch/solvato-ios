// Ekran görüntüsü testleri: her ekranı koyu ve açık temada açar, görüntüyü test sonucuna ekler.
// Codemagic bu görüntüleri cihaz adıyla birlikte derleme çıktısına koyar (scripts/native-ekranlar.py).
// Yeni ekran geldikçe buraya bir adım eklenir; web'deki aynı durumun görüntüsüyle yan yana karşılaştırılır.
import XCTest

final class ScreenshotTests: XCTestCase {
    @MainActor
    func testDesignSystem() {
        continueAfterFailure = false
        for (theme, tr) in [("dark", "koyu"), ("light", "acik")] {
            let app = try! launch(theme: theme, designSystem: true)
            let screen = app.descendants(matching: .any)["tasarim-sistemi"]
            XCTAssertTrue(screen.waitForExistence(timeout: 10), "tasarım sistemi ekranı açılmadı")
            // Simülatörün ilk açılış bildirimleri (ör. Apple Intelligence) kaybolsun
            if theme == "dark" { Thread.sleep(forTimeInterval: 8) }
            // Ekran uzun: her kısa kaydırmada bir görüntü (iPad'de son görüntüler tekrar edebilir)
            for shot in 1...12 {
                if shot > 1 { app.swipeUp(velocity: .slow) }
                snap("tasarim-\(shot)-\(tr)")
            }
            app.terminate()
        }
    }

    /// Pratik ekranı, web referans görüntüleriyle aynı adlar ve aynı veri (scripts/referans.mjs senaryoları)
    @MainActor
    func testPratik() throws {
        continueAfterFailure = false
        for name in ["pratik-yeni", "pratik", "pratik-ogretmen", "pratik-hedef-tamam", "pratik-alt"] {
            for (theme, tr) in [("dark", "koyu"), ("light", "acik")] {
                let app = try launch(theme: theme, scenario: name)
                XCTAssertTrue(app.buttons["Profil"].waitForExistence(timeout: 10), "\(name): Pratik açılmadı")
                if name == "pratik-alt" {
                    for _ in 0..<4 { app.swipeUp() }
                }
                Thread.sleep(forTimeInterval: 0.6)
                snap("\(name)-\(tr)")
                app.terminate()
            }
        }
    }

    /// İlk açılış tanıtımı (tanitim.md): web referans adları ve dokunuşlar; giriş, öğretmen sorusu, saat çarkı, geri oku
    /// ve öğretmen yolu (tanıtım biter, öğretmen kodu ekranı yalnız hazırlama bölümüyle; bağlantıyla kod girme bölümü)
    @MainActor
    func testTanitim() throws {
        continueAfterFailure = false
        let tries = ["Başlayalım", "Devam", "Do tuşu", "Devam", "Sol tuşu", "Devam"]
        let steps: [(String, [String])] = [
            ("tanitim-0-giris", []),
            ("tanitim-1-merhaba", ["Başlayalım"]),
            ("tanitim-2-deneme", ["Başlayalım", "Devam"]),
            ("tanitim-2-yanlis", ["Başlayalım", "Devam", "Re tuşu"]),
            ("tanitim-2-dogru", ["Başlayalım", "Devam", "Do tuşu"]),
            ("tanitim-3-ogretmen", tries),
        ]
        try runTanitim(steps)
    }

    /// Tanıtımın ikinci yarısı (10 dakikalık test sınırına sığsın diye ayrı): anahtar, geri, seviye, hatırlatma, hazır
    @MainActor
    func testTanitimDevam() throws {
        continueAfterFailure = false
        let base = ["Başlayalım", "Devam", "Do tuşu", "Devam", "Sol tuşu", "Devam", "Devam"]
        let steps: [(String, [String])] = [
            ("tanitim-4-anahtar", base),
            ("tanitim-4-geri", base + ["Geri"]),
            ("tanitim-5-seviye", base + ["Devam"]),
            ("tanitim-6-hatirlatma", base + ["Devam", "Devam"]),
            ("tanitim-6-saat", base + ["Devam", "Devam", "Hatırlatma saati"]),
            ("tanitim-7-hazir", base + ["Devam", "Devam", "Şimdi değil", "Devam"]),
        ]
        try runTanitim(steps)
    }

    /// Tanıtımdan öğretmen yolu (10 dakikalık test sınırına sığsın diye ayrı): öğretmen kodu ekranı hazırlama ve
    /// bağlantıyla kod girme bölümü
    @MainActor
    func testTanitimOgretmen() throws {
        continueAfterFailure = false
        let tries = ["Başlayalım", "Devam", "Do tuşu", "Devam", "Sol tuşu", "Devam"]
        try runTanitim([
            ("ogretmen-kodu-hazirla", tries + ["Ben öğretmenim", "Devam"]),
            ("ogretmen-kodu-gir", tries + ["Ben öğretmenim", "Devam", "Öğrenci misin?"]),
        ])
    }

    @MainActor
    private func runTanitim(_ steps: [(String, [String])]) throws {
        for (name, taps) in steps {
            for (theme, tr) in [("dark", "koyu"), ("light", "acik")] {
                // Bütün tanıtım senaryoları aynı: boş kayıt, tanıtım açık
                let app = try launch(theme: theme, scenario: "tanitim-1-merhaba")
                try must(app, app.buttons["Atla"], "\(name): tanıtım açılmadı", shot: "\(name)-hata-\(tr)")
                for label in taps {
                    let b = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", label)).firstMatch
                    try must(app, b, "\(name): \(label) yok", shot: "\(name)-hata-\(tr)", timeout: 3)
                    b.tap()
                    Thread.sleep(forTimeInterval: 0.35)
                }
                if name.hasPrefix("ogretmen-kodu") || name == "tanitim-6-saat" { Thread.sleep(forTimeInterval: 0.5) }
                snap("\(name)-\(tr)")
                app.terminate()
            }
        }
    }

    /// Ana sayfa ipuçları: ilk adım ve son adım (web "pratik-ipucu-1", "pratik-ipucu-5")
    @MainActor
    func testIpucu() throws {
        continueAfterFailure = false
        for (name, nexts) in [("pratik-ipucu-1", 0), ("pratik-ipucu-5", 4)] {
            for (theme, tr) in [("dark", "koyu"), ("light", "acik")] {
                let app = try launch(theme: theme, scenario: name)
                try must(app, app.buttons["Sıradaki"], "\(name): ipucu açılmadı", shot: "\(name)-hata-\(tr)")
                for _ in 0..<nexts {
                    app.buttons["Sıradaki"].tap()
                    Thread.sleep(forTimeInterval: 0.4)
                }
                Thread.sleep(forTimeInterval: 0.4)
                snap("\(name)-\(tr)")
                app.terminate()
            }
        }
    }

    /// Açılış animasyonu: başta, ortada (tuşlar) ve sonda (web referansı "acilis" son karesi)
    @MainActor
    func testAcilis() throws {
        for (theme, tr) in [("dark", "koyu"), ("light", "acik")] {
            let app = try launch(theme: theme, scenario: "acilis")
            Thread.sleep(forTimeInterval: 0.9)
            snap("acilis-orta-\(tr)")
            Thread.sleep(forTimeInterval: 0.8)
            snap("acilis-\(tr)")
            app.terminate()
        }
    }

    /// Soru turu: Pratik'ten konu kartına dokunup tur açılır (web referans senaryolarıyla aynı adlar ve adımlar)
    @MainActor
    func testSoru() throws {
        continueAfterFailure = false
        // (senaryo, dokunulacak konu, sonra yapılacak: ipucu / yanlis / dogru / cikis / boş)
        let steps: [(String, String, String)] = [
            ("soru-nota", "Sol Anahtarı", ""),
            ("soru-nota-ipucu", "Sol Anahtarı", "ipucu"),
            ("soru-nota-yanlis", "Sol Anahtarı", "yanlis"),
            ("soru-nota-dogru", "Sol Anahtarı", "dogru"),
            ("soru-nota-siklar", "Fa Anahtarı", ""),
            ("soru-diyez", "Diyez & Bemol", ""),
            ("soru-ritim", "Ritim & Ölçü", ""),
            ("soru-terim", "Müzik Terimleri", ""),
            ("soru-yazim", "Nota Yazımı", ""),
            ("soru-kulak", "Kulak", ""),
            ("soru-sure", "Sol Anahtarı", ""),
            ("soru-cikis", "Sol Anahtarı", "cikis"),
        ]
        for (name, topic, action) in steps {
            for (theme, tr) in [("dark", "koyu"), ("light", "acik")] {
                let app = try launch(theme: theme, scenario: name)
                XCTAssertTrue(app.buttons["Profil"].waitForExistence(timeout: 10), "\(name): Pratik açılmadı")
                let card = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", topic)).firstMatch
                // Kart görünene kadar kaydır (alttaki konular ilk ekranda yok)
                for _ in 0..<6 where !(card.exists && card.isHittable) { app.swipeUp(velocity: .slow) }
                card.tap()
                XCTAssertTrue(app.buttons["Turdan çık"].waitForExistence(timeout: 5), "\(name): soru açılmadı")
                switch action {
                case "ipucu": app.buttons["İpucu"].firstMatch.tap()
                case "yanlis": answerUntil(app, wrong: true)
                case "dogru": answerUntil(app, wrong: false)
                case "cikis":
                    // Çıkış onayı yalnız cevap verilmişse açılır (tur-ekranlari.md): önce bir yanlış cevap
                    answerUntil(app, wrong: true)
                    app.buttons["Turdan çık"].firstMatch.tap()
                default: break
                }
                Thread.sleep(forTimeInterval: 0.5)
                snap("\(name)-\(tr)")
                app.terminate()
            }
        }
    }

    /// İlerleme sekmesi (web "ilerleme-bos", "ilerleme", "ilerleme-alt")
    @MainActor
    func testIlerleme() throws {
        continueAfterFailure = false
        for name in ["ilerleme-bos", "ilerleme", "ilerleme-alt"] {
            for (theme, tr) in [("dark", "koyu"), ("light", "acik")] {
                let app = try launch(theme: theme, scenario: name)
                XCTAssertTrue(app.buttons["Profil"].waitForExistence(timeout: 10))
                tapTab(app, "İlerleme")
                Thread.sleep(forTimeInterval: 0.6)
                if name == "ilerleme-alt" { for _ in 0..<5 { app.swipeUp() } }
                Thread.sleep(forTimeInterval: 0.4)
                snap("\(name)-\(tr)")
                app.terminate()
            }
        }
    }

    /// Profil ve Ayarlar (web "profil", "profil-alt", "ayarlar", "ayarlar-alt")
    @MainActor
    func testProfilAyarlar() throws {
        continueAfterFailure = false
        // ayarlar.md: seçim penceresi (Günlük hedef), Çalışılacak notalar ekranı, sıfırlama onayı
        for name in ["profil", "profil-alt", "ayarlar", "ayarlar-alt", "ayarlar-pencere", "ayarlar-notalar", "ayarlar-sifirla"] {
            for (theme, tr) in [("dark", "koyu"), ("light", "acik")] {
                let app = try launch(theme: theme, scenario: name.hasPrefix("profil") ? name : "ayarlar")
                XCTAssertTrue(app.buttons["Profil"].waitForExistence(timeout: 10))
                tapTab(app, "Profil")
                Thread.sleep(forTimeInterval: 0.5)
                if name.hasPrefix("ayarlar") {
                    app.buttons["Ayarlar"].firstMatch.tap()
                    Thread.sleep(forTimeInterval: 0.5)
                }
                if name.hasSuffix("-alt") { for _ in 0..<6 { app.swipeUp() } }
                let tap: String? = ["ayarlar-pencere": "Günlük hedef", "ayarlar-notalar": "Çalışılacak notalar", "ayarlar-sifirla": "İlerlemeyi sıfırla"][name]
                if let tap {
                    let b = app.buttons[tap].firstMatch
                    for _ in 0..<8 where !(b.exists && b.isHittable) { app.swipeUp() }
                    try must(app, b, "\(name): \(tap) yok", shot: "\(name)-hata-\(tr)", timeout: 3)
                    b.tap()
                    Thread.sleep(forTimeInterval: 0.6)
                }
                Thread.sleep(forTimeInterval: 0.4)
                snap("\(name)-\(tr)")
                app.terminate()
            }
        }
    }

    /// Öğretmen kodu, Gizlilik ve Lisanslar (web "ogretmen-kodu…", "gizlilik", "lisanslar"): öğretmen kodu Profil'deki
    /// karttan, Gizlilik ve Lisanslar Profil › Ayarlar'dan açılır
    @MainActor
    func testOgretmenHukuk() throws {
        continueAfterFailure = false
        func open(_ app: XCUIApplication, _ row: String) {
            XCTAssertTrue(app.buttons["Profil"].waitForExistence(timeout: 10))
            tapTab(app, "Profil")
            Thread.sleep(forTimeInterval: 0.5)
            if row != "Öğretmen kodu" {
                app.buttons["Ayarlar"].firstMatch.tap()
                Thread.sleep(forTimeInterval: 0.5)
            }
            let link = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", row)).firstMatch
            for _ in 0..<8 where !(link.exists && link.isHittable) { app.swipeUp() }
            link.tap()
            Thread.sleep(forTimeInterval: 0.6)
        }
        for name in ["ogretmen-kodu", "ogretmen-kodu-alt", "ogretmen-kodu-hata", "ogretmen-kodu-uygulandi", "gizlilik", "lisanslar"] {
            for (theme, tr) in [("dark", "koyu"), ("light", "acik")] {
                let app = try launch(theme: theme, scenario: name)
                switch name {
                case "gizlilik": open(app, "Gizlilik")
                case "lisanslar": open(app, "Lisanslar")
                default:
                    open(app, "Öğretmen kodu")
                    let field = app.textFields["Öğretmen kodu"]
                    XCTAssertTrue(field.waitForExistence(timeout: 5), "öğretmen kodu ekranı açılmadı")
                    if name == "ogretmen-kodu-alt" { for _ in 0..<6 { app.swipeUp() } }
                    if name == "ogretmen-kodu-hata" || name == "ogretmen-kodu-uygulandi" {
                        var code = "ABC-DEF"
                        if name == "ogretmen-kodu-uygulandi" {
                            let shown = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Öğrencinin gireceği kod '")).firstMatch
                            code = String(shown.label.suffix(7))
                        }
                        field.tap()
                        // Kullanıcı gibi tiresiz ve harf harf: kutu tireyi kendisi ekler (R31); hızlı yazınca simülatörde
                        // yeniden yazılan metinden sonraki harfler düşebiliyor (70021c6 koşusunda "32V" kaldı)
                        for ch in code where ch != "-" {
                            field.typeText(String(ch))
                            Thread.sleep(forTimeInterval: 0.15)
                        }
                        app.buttons["Uygula"].tap()
                        Thread.sleep(forTimeInterval: 0.5)
                    }
                }
                Thread.sleep(forTimeInterval: 0.4)
                snap("\(name)-\(tr)")
                app.terminate()
            }
        }
    }

    /// Çalışma sekmesi (web "calisma", "calisma-arama", "calisma-kaldigin-yer")
    @MainActor
    func testCalisma() throws {
        continueAfterFailure = false
        for name in ["calisma", "calisma-arama", "calisma-kaldigin-yer"] {
            for (theme, tr) in [("dark", "koyu"), ("light", "acik")] {
                let app = try launch(theme: theme, scenario: name)
                XCTAssertTrue(app.buttons["Öğren"].waitForExistence(timeout: 10))
                tapTab(app, "Öğren")
                let field = app.textFields["Konu ara"]
                XCTAssertTrue(field.waitForExistence(timeout: 5), "Öğren açılmadı")
                if name == "calisma-arama" {
                    field.tap()
                    field.typeText("legato")
                }
                Thread.sleep(forTimeInterval: 0.5)
                snap("\(name)-\(tr)")
                app.terminate()
            }
        }
    }

    /// Çalışma dersleri (web "ders-<id>"): Çalışma'dan başlığa dokunarak açılır (19 ders). İki teste bölünür: 19 ders ×
    /// 2 tema tek testte simülatörün 10 dakikalık sınırını aşıyor.
    @MainActor
    func testDersler() throws { try lessonShots(Self.lessons.filter { !$0.0.hasPrefix("terms-") && !$0.0.hasPrefix("rhythm-") }) }

    /// Ritim ve terim dersleri (testDersler'in ikinci yarısı)
    @MainActor
    func testDerslerRitimTerim() throws { try lessonShots(Self.lessons.filter { $0.0.hasPrefix("terms-") || $0.0.hasPrefix("rhythm-") }) }

    /// Dersler: kimlik (senaryo ders-<id>) ve Öğren listesindeki başlık
    static let lessons: [(String, String)] = [
        ("notes-treble", "Sol anahtarı notaları"), ("notes-bass", "Fa anahtarı notaları"),
        ("mnemonic-treble", "Kolay hatırla: Sol anahtarı"), ("mnemonic-bass", "Kolay hatırla: Fa anahtarı"),
        ("accidentals", "Diyez ve bemol"),
        ("chords-build", "Majör ve minör nasıl kurulur"), ("chords-1", "Akor kartları: Başlangıç"),
        ("chords-2", "Akor kartları: Orta"), ("chords-3", "Akor kartları: İleri"), ("chords-4", "Akor kartları: Uzman"),
        ("rhythm-values", "Nota değerleri"), ("rhythm-rests", "Sus işaretleri"), ("rhythm-dotted", "Noktalı notalar"),
        ("terms-Dinamikler", "Dinamikler"), ("terms-Tempo", "Tempo"), ("terms-Değişim işaretleri", "Değişim işaretleri"),
        ("terms-Artikülasyon", "Artikülasyon"), ("terms-İfade", "İfade"), ("terms-Yapısal İşaretler", "Yapısal İşaretler"),
    ]

    @MainActor
    private func lessonShots(_ lessons: [(String, String)]) throws {
        continueAfterFailure = false
        for (id, title) in lessons {
            for (theme, tr) in [("dark", "koyu"), ("light", "acik")] {
                let app = try launch(theme: theme, scenario: "ders-\(id)")
                XCTAssertTrue(app.buttons["Öğren"].waitForExistence(timeout: 10))
                tapTab(app, "Öğren")
                let row = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", title)).firstMatch
                XCTAssertTrue(row.waitForExistence(timeout: 5), "ders satırı yok: \(title)")
                for _ in 0..<8 where !row.isHittable { app.swipeUp() }
                row.tap()
                Thread.sleep(forTimeInterval: 0.6)
                snap("ders-\(id)-\(tr)")
                app.terminate()
            }
        }
    }

    /// Oyunlar (web "oyunlar…", "gunun-oyunu…", "meydan-oku…", "oyun-sonucu-…"): Pratik'teki Oyunlar kartından
    @MainActor
    func testOyunlar() throws {
        continueAfterFailure = false
        // 10 senaryo × 2 tema; iPad'de varsayılan 10 dakikayı aşıyordu (ekranlar dalı, hata-testOyunlar-ipad)
        executionTimeAllowance = 1800
        let steps: [(String, [String])] = [
            ("oyunlar", []), ("oyunlar-oynandi", []),
            ("gunun-oyunu", ["Günün meydan okuması"]), ("gunun-oyunu-oynandi", ["Günün meydan okuması"]),
            ("meydan-oku", ["Arkadaşına meydan oku"]), ("meydan-oku-hata", ["Arkadaşına meydan oku"]),
            ("oyun-sonucu-gunluk", ["Günün meydan okuması", "Oyna"]), ("oyun-sonucu-kod", ["Arkadaşına meydan oku", "Başla"]),
            ("duello-kurulum", ["Akor düellosu"]), ("duello-oyun", ["Akor düellosu", "Başlayalım"]),
        ]
        for (name, taps) in steps {
            for (theme, tr) in [("dark", "koyu"), ("light", "acik")] {
                let app = try launch(theme: theme, scenario: name)
                XCTAssertTrue(app.buttons["Profil"].waitForExistence(timeout: 10))
                let games = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Oyunlar'")).firstMatch
                for _ in 0..<8 where !(games.exists && games.isHittable) { app.swipeUp() }
                try must(app, games, "\(name): Oyunlar kartı yok", shot: "\(name)-hata-\(tr)")
                games.tap()
                Thread.sleep(forTimeInterval: 0.5)
                for t in taps {
                    let b = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", t)).firstMatch
                    try must(app, b, "\(name): \(t) yok", shot: "\(name)-hata-\(tr)", timeout: 5)
                    b.tap()
                    Thread.sleep(forTimeInterval: 0.5)
                }
                if name == "meydan-oku-hata" {
                    let field = app.textFields["Meydan okuma kodu"]
                    field.tap()
                    for ch in "ABCDEFGH" { field.typeText(String(ch)); Thread.sleep(forTimeInterval: 0.15) }
                    app.buttons["Kabul et"].tap()
                }
                if name.hasPrefix("oyun-sonucu") {
                    for _ in 0..<40 {
                        if app.buttons["Kapat"].exists { break }
                        let next = app.buttons.matching(NSPredicate(format: "label IN {'Sıradaki', 'Turu bitir'}")).firstMatch
                        if next.exists { next.tap() } else {
                            let key = app.buttons["Do tuşu"].firstMatch  // iPad klavyesinde iki Do tuşu var
                            if key.exists { key.tap() } else { app.buttons.allElementsBoundByIndex.last { $0.isEnabled && $0.isHittable }?.tap() }
                        }
                        Thread.sleep(forTimeInterval: 0.9)
                    }
                }
                Thread.sleep(forTimeInterval: 0.6)
                snap("\(name)-\(tr)")
                app.terminate()
            }
        }
    }

    /// Ritmi Tut (web "ritmi-tut", "ritmi-tut-ses-kapali"): Pratik'teki Ritmi Tut bağlantısından
    @MainActor
    func testRitmiTut() throws {
        continueAfterFailure = false
        for name in ["ritmi-tut", "ritmi-tut-ses-kapali"] {
            for (theme, tr) in [("dark", "koyu"), ("light", "acik")] {
                let app = try launch(theme: theme, scenario: name)
                XCTAssertTrue(app.buttons["Profil"].waitForExistence(timeout: 10))
                let link = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Ritmi Tut'")).firstMatch
                for _ in 0..<6 where !(link.exists && link.isHittable) { app.swipeUp(velocity: .slow) }
                try must(app, link, "\(name): Ritmi Tut bağlantısı yok", shot: "\(name)-hata-\(tr)")
                link.tap()
                try must(app, app.buttons["Turdan çık"], "\(name): Ritmi Tut açılmadı", shot: "\(name)-hata-\(tr)", timeout: 5)
                Thread.sleep(forTimeInterval: 0.5)
                snap("\(name)-\(tr)")
                app.terminate()
            }
        }
    }

    /// Akor turu (web "akor"): Pratik'ten Akor bağlantısı
    @MainActor
    func testAkor() throws {
        continueAfterFailure = false
        for (theme, tr) in [("dark", "koyu"), ("light", "acik")] {
            let app = try launch(theme: theme, scenario: "akor")
            XCTAssertTrue(app.buttons["Profil"].waitForExistence(timeout: 10))
            let link = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Akor'")).firstMatch
            for _ in 0..<6 where !(link.exists && link.isHittable) { app.swipeUp(velocity: .slow) }
            link.tap()
            XCTAssertTrue(app.buttons["Turdan çık"].waitForExistence(timeout: 5), "akor turu açılmadı")
            Thread.sleep(forTimeInterval: 0.5)
            snap("akor-\(tr)")
            app.terminate()
        }
    }

    /// Tur sonucu ve kutlama: Pratik'te "Devam et" ile karma tur açılır, sonuna kadar oynanır (web turuBitir)
    @MainActor
    func testSonuc() throws {
        continueAfterFailure = false
        for name in ["sonuc", "kutlama"] {
            for (theme, tr) in [("dark", "koyu"), ("light", "acik")] {
                let app = try launch(theme: theme, scenario: name)
                XCTAssertTrue(app.buttons["Profil"].waitForExistence(timeout: 10), "\(name): Pratik açılmadı")
                app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Devam et' OR label BEGINSWITH 'Bugünün çalışması' OR label BEGINSWITH 'Bir tur daha'")).firstMatch.tap()
                for _ in 0..<40 {
                    if app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Tur bitti'")).firstMatch.exists { break }
                    if app.otherElements["Kutlama"].exists || app.staticTexts["Harika iş!"].exists { break }
                    let next = app.buttons.matching(NSPredicate(format: "label IN {'Sıradaki', 'Turu bitir'}")).firstMatch
                    if next.exists { next.tap() } else {
                        let key = app.buttons["Do tuşu"].firstMatch  // iPad klavyesinde iki Do tuşu var
                        if key.exists { key.tap() } else { app.buttons.allElementsBoundByIndex.last { $0.isEnabled && $0.isHittable }?.tap() }
                    }
                    Thread.sleep(forTimeInterval: 0.9)
                }
                Thread.sleep(forTimeInterval: 0.6)
                snap("\(name)-\(tr)")
                app.terminate()
            }
        }
    }

    /// Klavyede "Do tuşu"na ya da son şıkka basarak yanlış (ya da doğru) cevaplanan ilk soruda durur
    @MainActor
    private func answerUntil(_ app: XCUIApplication, wrong: Bool) {
        for _ in 0..<10 {
            let key = app.buttons["Do tuşu"].firstMatch  // iPad klavyesinde iki Do tuşu var
            if key.exists { key.tap() } else { app.buttons.allElementsBoundByIndex.last { $0.isEnabled && $0.isHittable }?.tap() }
            Thread.sleep(forTimeInterval: 0.3)
            let isWrong = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Doğru cevap:'")).firstMatch.exists
            if isWrong == wrong { return }
            if isWrong { app.buttons.matching(NSPredicate(format: "label IN {'Sıradaki', 'Turu bitir'}")).firstMatch.tap() }
            Thread.sleep(forTimeInterval: 0.9)
        }
    }
}
