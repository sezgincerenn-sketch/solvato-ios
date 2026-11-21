// SVG yol okuyucusunun testleri ve ikonların web'dekiyle aynı olduğunun kontrolü (Fixtures/icons.json).
import Foundation
import XCTest

@testable import SolvatoCore

final class SVGPathTests: XCTestCase {
    func testLinesAbsoluteAndRelative() throws {
        XCTAssertEqual(
            try SVGPath.parse("M18 6L6 18 M6 6l12 12"),
            [.move(Point(18, 6)), .line(Point(6, 18)), .move(Point(6, 6)), .line(Point(18, 18))]
        )
        XCTAssertEqual(
            try SVGPath.parse("M9 18h6 M10 22h4"),
            [.move(Point(9, 18)), .line(Point(15, 18)), .move(Point(10, 22)), .line(Point(14, 22))]
        )
        // M'den sonraki sayılar çizgi; V mutlak, v göreli; z başlangıca döner
        XCTAssertEqual(
            try SVGPath.parse("M4 7V4h16v3z"),
            [.move(Point(4, 7)), .line(Point(4, 4)), .line(Point(20, 4)), .line(Point(20, 7)), .close]
        )
        XCTAssertEqual(try SVGPath.parse("M1 1 2 2 3 3"), [.move(Point(1, 1)), .line(Point(2, 2)), .line(Point(3, 3))])
    }

    func testCompactNumbers() throws {
        // "1.5.25" iki sayı, "-.5" geçerli, eksi işareti ayırıcı yerine geçer
        XCTAssertEqual(try SVGPath.parse("M1.5.25l-.5-1.25"), [.move(Point(1.5, 0.25)), .line(Point(1, -1))])
    }

    func testCubicAndSmooth() throws {
        let cmds = try SVGPath.parse("M0 0C1 2 3 4 5 6s1 1 2 2")
        XCTAssertEqual(cmds.count, 3)
        XCTAssertEqual(cmds[1], .cubic(Point(1, 2), Point(3, 4), Point(5, 6)))
        // S: ilk kontrol noktası öncekinin yansıması (5,6)+(5,6)-(3,4) = (7,8); diğerleri göreli
        XCTAssertEqual(cmds[2], .cubic(Point(7, 8), Point(6, 7), Point(7, 8)))
    }

    func testArcCircleStaysOnCircle() throws {
        // target ikonundaki dış çember: merkez (12,12), yarıçap 10
        let cmds = try SVGPath.parse("M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20z")
        var last = Point(12, 22)
        var segments = 0
        for c in cmds {
            guard case .cubic(let c1, let c2, let end) = c else { continue }
            // Bezier'in orta noktası çember üstünde olmalı (kübik yaklaşım hatası < 0,01)
            let mid = Point(
                0.125 * last.x + 0.375 * c1.x + 0.375 * c2.x + 0.125 * end.x,
                0.125 * last.y + 0.375 * c1.y + 0.375 * c2.y + 0.125 * end.y
            )
            XCTAssertEqual(hypot(mid.x - 12, mid.y - 12), 10, accuracy: 0.01)
            XCTAssertEqual(hypot(end.x - 12, end.y - 12), 10, accuracy: 1e-9)
            last = end
            segments += 1
        }
        XCTAssertEqual(segments, 4, "iki yarım çember, her biri iki çeyrek")
        XCTAssertEqual(last.x, 12, accuracy: 1e-9)
        XCTAssertEqual(last.y, 22, accuracy: 1e-9)
        XCTAssertEqual(cmds.last, .close)
    }

    func testArcSweepDirection() throws {
        // (0,0)'dan (10,0)'a yarıçap 5 yarım çember: sweep=1 saat yönünde (SVG'de y aşağı) → yay y<0 tarafında
        let up = try SVGPath.parse("M0 0A5 5 0 0 1 10 0")
        guard case .cubic(let c1, _, _) = up[1] else { return XCTFail("eğri yok") }
        XCTAssertLessThan(c1.y, 0)
        let down = try SVGPath.parse("M0 0A5 5 0 0 0 10 0")
        guard case .cubic(let d1, _, _) = down[1] else { return XCTFail("eğri yok") }
        XCTAssertGreaterThan(d1.y, 0)
    }

    func testBrokenInputThrows() {
        XCTAssertThrowsError(try SVGPath.parse("12 4"))
        XCTAssertThrowsError(try SVGPath.parse("M1"))
        XCTAssertThrowsError(try SVGPath.parse("M0 0a1 1 0 2 0 1 1"))
    }
}

final class IconsTests: XCTestCase {
    func testIconsMatchWeb() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "icons", withExtension: "json", subdirectory: "Fixtures"))
        let web = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        let icons = try XCTUnwrap(web["icons"] as? [String: String])
        XCTAssertEqual(Set(icons.keys), Set(IconName.allCases.map(\.rawValue)), "ikon adları")
        for icon in IconName.allCases {
            XCTAssertEqual(icon.path, icons[icon.rawValue], "ikon \(icon.rawValue)")
        }
        XCTAssertEqual(starPath, web["star"] as? String, "yıldız yolu")
    }

    func testEveryIconParsesInsideViewBox() throws {
        for icon in IconName.allCases {
            let cmds = try SVGPath.parse(icon.path)
            XCTAssertFalse(cmds.isEmpty, icon.rawValue)
            for c in cmds {
                let points: [Point]
                switch c {
                case .move(let p), .line(let p): points = [p]
                case .cubic(_, _, let p), .quad(_, let p): points = [p]
                case .close: points = []
                }
                for p in points {
                    XCTAssert((-0.5...24.5).contains(p.x) && (-0.5...24.5).contains(p.y), "\(icon.rawValue): \(p)")
                }
            }
        }
        XCTAssertNoThrow(try SVGPath.parse(starPath))
    }
}
