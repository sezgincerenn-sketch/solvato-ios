// Uygulamanın görünen adı Solfado: kullanıcıya görünen hiçbir metinde eski ad (Solvato) kalmamalı. Swift kaynaklarındaki
// metinleri, gizlilik/lisans metnini, simge adını ve siteyi tarar. Kod, klasör ve kayıt adları (Solvato) bilerek kalır.
import XCTest

@testable import SolvatoCore

final class AppNameTests: XCTestCase {
    private let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        .appendingPathComponent("../../..").standardizedFileURL  // ios-native/

    /// Kullanıcı görmeyen, bilerek eski adı taşıyan metinler (klasör adı)
    private let allowed = ["appendingPathComponent(\"Solvato\""]

    func testNoOldNameInSwiftStrings() throws {
        var hits: [String] = []
        for dir in ["Solvato", "SolvatoCore/Sources"] {
            let base = root.appendingPathComponent(dir)
            let files = FileManager.default.enumerator(at: base, includingPropertiesForKeys: nil)!
                .compactMap { $0 as? URL }.filter { $0.pathExtension == "swift" }
            XCTAssertFalse(files.isEmpty, dir)
            for file in files {
                for (i, line) in try String(contentsOf: file, encoding: .utf8).components(separatedBy: "\n").enumerated() {
                    let t = line.trimmingCharacters(in: .whitespaces)
                    if t.hasPrefix("//") || t.hasPrefix("import ") || allowed.contains(where: t.contains) { continue }
                    let code = t.components(separatedBy: " // ").first ?? t
                    // Yalnız tırnak içindeki metinler
                    let quoted = code.components(separatedBy: "\"").enumerated().filter { $0.offset % 2 == 1 }.map(\.element)
                    if quoted.contains(where: { $0.contains("Solvato") }) { hits.append("\(file.lastPathComponent):\(i + 1)") }
                }
            }
        }
        XCTAssertEqual(hits, [])
    }

    func testDisplayNameLegalAndSite() throws {
        let yml = try String(contentsOf: root.appendingPathComponent("project.yml"), encoding: .utf8)
        XCTAssertTrue(yml.contains("CFBundleDisplayName: Solfado"))
        let legal = try String(contentsOf: root.appendingPathComponent("SolvatoCore/Sources/SolvatoCore/Resources/hukuk.json"), encoding: .utf8)
        XCTAssertFalse(legal.contains("Solvato"))
        XCTAssertTrue(legal.contains("Solfado"))
        let site = try String(contentsOf: root.appendingPathComponent("../scripts/site.mjs"), encoding: .utf8)
        let siteText = site.components(separatedBy: "\n").filter { !$0.contains("SolvatoCore") && !$0.contains("ios-native/Solvato/") }
        XCTAssertFalse(siteText.contains { $0.contains("Solvato") }, "site metninde eski ad")
    }

    func testShareTextsUseNewName() {
        XCTAssertTrue(AppStoreLink.line.hasPrefix("Solfado'yu App Store'dan indir"))
    }
}
