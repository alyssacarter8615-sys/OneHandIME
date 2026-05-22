import XCTest
@testable import OneHandEngine

final class DictLoaderTests: XCTestCase {
    private let testData = """
        the\t23135851162
        hello\t48695552
        world\t148382455
        don't\t500000000
        ABC\t999999999
        123num\t888888888
        a\t8412052401
        """

    func testParseFiltersNonAlphabetic() {
        let trie = DictLoader.parse(testData, maxWords: 100)
        let resultsD = trie.search([["d"]])
        XCTAssertTrue(resultsD.isEmpty)
        let resultsA = trie.search([["a"]])
        let words = resultsA.map(\.word)
        XCTAssertTrue(words.contains("a"))
        XCTAssertFalse(words.contains("ABC"))
    }

    func testParseRespectsMaxWords() {
        let trie = DictLoader.parse(testData, maxWords: 2)
        let allT = trie.search([["t"]])
        XCTAssertTrue(allT.contains(where: { $0.word == "the" }))
        let allH = trie.search([["h"]])
        XCTAssertFalse(allH.contains(where: { $0.word == "hello" }))
    }

    func testParseUsesLogFrequency() {
        let trie = DictLoader.parse(testData, maxWords: 100)
        let results = trie.search([["t"], ["h"], ["e"]])
        let the = results.first(where: { $0.word == "the" })!
        XCTAssertTrue(abs(the.logFreq - 10.364) < 0.01)
    }
}
