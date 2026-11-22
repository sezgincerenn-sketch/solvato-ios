// CSS cubic-bezier değerleri: uçlar, doğrusal, ease-out simetrisi, yay eğrisinin 1'i aşması.
import XCTest

@testable import SolvatoCore

final class CurveTests: XCTestCase {
    func testCurves() {
        XCTAssertEqual(Curve.linear.value(at: 0.3), 0.3, accuracy: 1e-6)
        XCTAssertEqual(Curve.easeInOut.value(at: 0.5), 0.5, accuracy: 1e-6)
        XCTAssertEqual(Curve.easeOut.value(at: 0), 0)
        XCTAssertEqual(Curve.easeOut.value(at: 1), 1)
        XCTAssertGreaterThan(Curve.easeOut.value(at: 0.3), 0.3)
        // CSS "ease" 0,5'te ≈ 0,8024
        XCTAssertEqual(Curve.cssEase.value(at: 0.5), 0.8024, accuracy: 1e-3)
        // Yay (spring): bir yerde 1'i aşar
        XCTAssertGreaterThan((1..<100).map { Motion.spring.value(at: Double($0) / 100) }.max()!, 1.0)
        XCTAssertEqual(Curve.linear.progress(1.5, delay: 1, duration: 2), 0.25, accuracy: 1e-9)
        XCTAssertEqual(Curve.linear.progress(0.5, delay: 1, duration: 2), 0)
    }

    func testTimeReaching() {
        let c = Curve(0.16, 1, 0.3, 1)
        let t = c.time(reaching: 0.5)
        XCTAssertEqual(c.value(at: t), 0.5, accuracy: 1e-6)
        XCTAssertLessThan(t, 0.2)
        XCTAssertEqual(Curve.linear.time(reaching: 0.5), 0.5, accuracy: 1e-9)
    }
}
