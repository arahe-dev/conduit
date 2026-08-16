import XCTest
@testable import ProductivityTracker

final class ComposePullTests: XCTestCase {
    func testResistanceIsBelowRawTranslationAndApproachesPageWidth() {
        let width: CGFloat = 390
        XCTAssertEqual(ComposePull.resist(0, pageWidth: width), 0, accuracy: 0.001)
        let small = ComposePull.resist(40, pageWidth: width)
        XCTAssertLessThan(small, 40)
        XCTAssertGreaterThan(small, 0)
        let large = ComposePull.resist(width * 4, pageWidth: width)
        XCTAssertLessThan(large, width)
        XCTAssertGreaterThan(large, width * 0.9)
    }

    func testCommitRequiresADeliberatePullUnlessRelaxed() {
        let width: CGFloat = 390
        XCTAssertFalse(
            ComposePull.shouldCommit(translation: 40, predicted: 50, pageWidth: width, relaxed: false)
        )
        XCTAssertTrue(
            ComposePull.shouldCommit(translation: width * 0.4, predicted: 0, pageWidth: width, relaxed: false)
        )
        XCTAssertTrue(
            ComposePull.shouldCommit(translation: width * 0.15, predicted: 0, pageWidth: width, relaxed: true)
        )
    }
}
