import XCTest
@testable import OneHandEngine

final class EngineTests: XCTestCase {
    private func testEngine() -> Engine {
        let keymap = KeyMap.leftHand()
        let trie = Trie()
        trie.insert("the", logFreq: 10.36)
        trie.insert("they", logFreq: 9.25)
        trie.insert("this", logFreq: 9.27)
        trie.insert("think", logFreq: 8.47)
        trie.insert("well", logFreq: 8.37)
        trie.insert("will", logFreq: 8.75)
        trie.insert("hello", logFreq: 7.69)
        trie.insert("help", logFreq: 7.91)
        trie.insert("he", logFreq: 9.22)
        trie.insert("him", logFreq: 8.84)
        trie.insert("jump", logFreq: 7.52)
        return Engine(keymap: keymap, trie: trie)
    }

    func testSearchTgeFindsTheAndThis() {
        let engine = testEngine()
        let results = engine.search(["t", "g", "e"])
        let words = results.map(\.word)
        XCTAssertTrue(words.contains("the"))
        XCTAssertTrue(words.contains("this"))
        XCTAssertTrue(words.contains("think"))
    }

    func testSearchResultsSortedByFrequency() {
        let engine = testEngine()
        let results = engine.search(["t", "g", "e"])
        for i in 0..<(results.count - 1) {
            XCTAssertGreaterThanOrEqual(results[i].logFreq, results[i + 1].logFreq)
        }
    }

    func testSearchUnknownKeyReturnsEmpty() {
        let engine = testEngine()
        let results = engine.search(["m"])
        XCTAssertTrue(results.isEmpty)
    }

    func testPrimaryAndSecondaryLetters() {
        let engine = testEngine()
        XCTAssertEqual(engine.primaryLetter("f"), "f")
        XCTAssertEqual(engine.secondaryLetter("f"), "j")
        XCTAssertEqual(engine.primaryLetter("a"), "a")
        XCTAssertEqual(engine.secondaryLetter("a"), "a")
    }
}
