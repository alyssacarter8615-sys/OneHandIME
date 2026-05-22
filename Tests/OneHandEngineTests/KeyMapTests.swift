import XCTest
@testable import OneHandEngine

final class KeyMapTests: XCTestCase {
    func testLeftHandMirrorPairs() {
        let km = KeyMap.leftHand()
        XCTAssertEqual(km.candidates("q"), ["q", "p"])
        XCTAssertEqual(km.candidates("w"), ["w", "o"])
        XCTAssertEqual(km.candidates("e"), ["e", "i"])
        XCTAssertEqual(km.candidates("r"), ["r", "u"])
        XCTAssertEqual(km.candidates("t"), ["t", "y"])
        XCTAssertEqual(km.candidates("s"), ["s", "l"])
        XCTAssertEqual(km.candidates("d"), ["d", "k"])
        XCTAssertEqual(km.candidates("f"), ["f", "j"])
        XCTAssertEqual(km.candidates("g"), ["g", "h"])
        XCTAssertEqual(km.candidates("v"), ["v", "m"])
        XCTAssertEqual(km.candidates("b"), ["b", "n"])
    }

    func testLeftHandNoMirror() {
        let km = KeyMap.leftHand()
        XCTAssertEqual(km.candidates("a"), ["a"])
        XCTAssertEqual(km.candidates("z"), ["z"])
        XCTAssertEqual(km.candidates("x"), ["x"])
        XCTAssertEqual(km.candidates("c"), ["c"])
    }

    func testRightHandKeysAreUnambiguous() {
        let km = KeyMap.leftHand()
        XCTAssertEqual(km.candidates("p"), ["p"])
        XCTAssertEqual(km.candidates("o"), ["o"])
        XCTAssertEqual(km.candidates("h"), ["h"])
        XCTAssertEqual(km.candidates("m"), ["m"])
    }

    func testUnknownKeyReturnsNil() {
        let km = KeyMap.leftHand()
        XCTAssertNil(km.candidates("1"))
        XCTAssertNil(km.candidates("."))
    }

    func testPrimaryAndSecondary() {
        let km = KeyMap.leftHand()
        XCTAssertEqual(km.primary("q"), "q")
        XCTAssertEqual(km.secondary("q"), "p")
        XCTAssertEqual(km.primary("a"), "a")
        XCTAssertEqual(km.secondary("a"), "a")
        XCTAssertEqual(km.primary("m"), "m")
        XCTAssertEqual(km.secondary("m"), "m")
        XCTAssertNil(km.primary("1"))
    }
}
