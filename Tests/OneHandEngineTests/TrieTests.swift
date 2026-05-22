import XCTest
@testable import OneHandEngine

final class TrieTests: XCTestCase {
    private func sampleTrie() -> Trie {
        let t = Trie()
        t.insert("the", logFreq: 10.36)
        t.insert("they", logFreq: 9.25)
        t.insert("this", logFreq: 9.27)
        t.insert("think", logFreq: 8.47)
        t.insert("these", logFreq: 8.45)
        t.insert("well", logFreq: 8.37)
        t.insert("will", logFreq: 8.75)
        t.insert("hello", logFreq: 7.69)
        t.insert("help", logFreq: 7.91)
        t.insert("he", logFreq: 9.22)
        return t
    }

    func testSearchExactSingleCandidateSet() {
        let t = sampleTrie()
        let results = t.search([["t"], ["h"], ["e"]])
        let words = results.map(\.word)
        XCTAssertTrue(words.contains("the"))
    }

    func testSearchWithAmbiguousSets() {
        let t = sampleTrie()
        let results = t.search([["t", "y"], ["g", "h"], ["e", "i"]])
        let words = results.map(\.word)
        XCTAssertTrue(words.contains("the"))
        XCTAssertTrue(words.contains("this"))
        XCTAssertTrue(words.contains("think"))
    }

    func testSearchReturnsPrefixCompletions() {
        let t = sampleTrie()
        let results = t.search([["t"], ["h"]])
        let words = results.map(\.word)
        XCTAssertTrue(words.contains("the"))
        XCTAssertTrue(words.contains("they"))
        XCTAssertTrue(words.contains("this"))
        XCTAssertTrue(words.contains("think"))
        XCTAssertTrue(words.contains("these"))
    }

    func testSearchSortedByFrequency() {
        let t = sampleTrie()
        let results = t.search([["t"], ["h"]])
        for i in 0..<(results.count - 1) {
            XCTAssertGreaterThanOrEqual(results[i].logFreq, results[i + 1].logFreq)
        }
        XCTAssertEqual(results[0].word, "the")
    }

    func testSearchEmptyKeystrokesReturnsNothing() {
        let t = sampleTrie()
        let results = t.search([])
        XCTAssertTrue(results.isEmpty)
    }

    func testSearchNoMatchReturnsEmpty() {
        let t = sampleTrie()
        let results = t.search([["z"]])
        XCTAssertTrue(results.isEmpty)
    }
}
