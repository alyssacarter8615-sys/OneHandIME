import XCTest
@testable import OneHandEngine

final class InputSessionTests: XCTestCase {
    private func testSession() -> InputSession {
        let keymap = KeyMap.leftHand()
        let trie = Trie()
        trie.insert("the", logFreq: 10.36)
        trie.insert("they", logFreq: 9.25)
        trie.insert("this", logFreq: 9.27)
        trie.insert("think", logFreq: 8.47)
        trie.insert("these", logFreq: 8.45)
        trie.insert("them", logFreq: 8.57)
        trie.insert("there", logFreq: 8.63)
        trie.insert("their", logFreq: 8.58)
        trie.insert("than", logFreq: 9.10)
        trie.insert("that", logFreq: 9.50)
        trie.insert("well", logFreq: 8.37)
        trie.insert("will", logFreq: 8.75)
        trie.insert("hello", logFreq: 7.69)
        trie.insert("help", logFreq: 7.91)
        trie.insert("he", logFreq: 9.22)
        let engine = Engine(keymap: keymap, trie: trie)
        return InputSession(engine: engine)
    }

    func testDisambiguationKeystrokeProducesCandidates() {
        let s = testSession()
        _ = s.processKey(.letter("t"))
        _ = s.processKey(.letter("g"))
        let out = s.processKey(.letter("e"))
        XCTAssertFalse(out.candidates.isEmpty)
        let words = s.candidates.map(\.word)
        XCTAssertTrue(words.contains("the"))
    }

    func testSpaceConfirmsFirstCandidate() {
        let s = testSession()
        _ = s.processKey(.letter("t"))
        _ = s.processKey(.letter("g"))
        _ = s.processKey(.letter("e"))
        let out = s.processKey(.space)
        XCTAssertEqual(out.committed, "The")
        XCTAssertTrue(s.keystrokes.isEmpty)
        XCTAssertTrue(s.candidates.isEmpty)
    }

    func testNumberSelectsCandidateWithoutSpace() {
        let s = testSession()
        _ = s.processKey(.letter("t"))
        _ = s.processKey(.letter("g"))
        _ = s.processKey(.letter("e"))
        let out = s.processKey(.number(2))
        let committed = out.committed!
        XCTAssertTrue(committed.first!.isUppercase)
        XCTAssertFalse(committed.hasSuffix(" "))
    }

    func testBackspaceRemovesLastKeystroke() {
        let s = testSession()
        _ = s.processKey(.letter("t"))
        _ = s.processKey(.letter("g"))
        _ = s.processKey(.letter("e"))
        let count3 = s.candidates.count
        _ = s.processKey(.backspace)
        XCTAssertEqual(s.keystrokes.count, 2)
        XCTAssertNotEqual(s.candidates.count, count3)
    }

    func testTabPagesForward() {
        let s = testSession()
        _ = s.processKey(.letter("t"))
        _ = s.processKey(.letter("g"))
        XCTAssertTrue(s.candidates.count > 5)
        XCTAssertEqual(s.page, 0)
        _ = s.processKey(.tab)
        XCTAssertEqual(s.page, 1)
    }

    func testBacktabPagesBackward() {
        let s = testSession()
        _ = s.processKey(.letter("t"))
        _ = s.processKey(.letter("g"))
        _ = s.processKey(.tab)
        XCTAssertEqual(s.page, 1)
        _ = s.processKey(.backTab)
        XCTAssertEqual(s.page, 0)
    }

    func testToggleEntersSecondaryLetterMode() {
        let s = testSession()
        XCTAssertEqual(s.mode, .disambiguation)
        _ = s.processKey(.toggleLetterMode)
        XCTAssertEqual(s.mode, .secondaryLetter)
    }

    func testToggleCyclesLetterModes() {
        let s = testSession()
        _ = s.processKey(.toggleLetterMode)
        XCTAssertEqual(s.mode, .secondaryLetter)
        _ = s.processKey(.toggleLetterMode)
        XCTAssertEqual(s.mode, .primaryLetter)
        _ = s.processKey(.toggleLetterMode)
        XCTAssertEqual(s.mode, .secondaryLetter)
    }

    func testSecondaryLetterModeOutputsMirror() {
        let s = testSession()
        _ = s.processKey(.toggleLetterMode)
        _ = s.processKey(.letter("f"))
        XCTAssertEqual(s.letterBuffer, "j")
        _ = s.processKey(.letter("r"))
        XCTAssertEqual(s.letterBuffer, "ju")
    }

    func testPrimaryLetterModeOutputsSelf() {
        let s = testSession()
        _ = s.processKey(.toggleLetterMode)
        _ = s.processKey(.toggleLetterMode)
        _ = s.processKey(.letter("a"))
        XCTAssertEqual(s.letterBuffer, "a")
        _ = s.processKey(.letter("b"))
        XCTAssertEqual(s.letterBuffer, "ab")
    }

    func testSpaceInLetterModeCommitsAndReturns() {
        let s = testSession()
        _ = s.processKey(.toggleLetterMode)
        _ = s.processKey(.letter("f"))
        _ = s.processKey(.letter("r"))
        _ = s.processKey(.letter("v"))
        _ = s.processKey(.letter("q"))
        XCTAssertEqual(s.letterBuffer, "jump")
        let out = s.processKey(.space)
        XCTAssertEqual(out.committed, "Jump")
        XCTAssertTrue(s.letterBuffer.isEmpty)
        XCTAssertEqual(s.mode, .disambiguation)
    }

    func testToggleClearsPartialDisambiguationInput() {
        let s = testSession()
        _ = s.processKey(.letter("t"))
        _ = s.processKey(.letter("g"))
        XCTAssertFalse(s.keystrokes.isEmpty)
        _ = s.processKey(.toggleLetterMode)
        XCTAssertTrue(s.keystrokes.isEmpty)
        XCTAssertTrue(s.candidates.isEmpty)
        XCTAssertEqual(s.mode, .secondaryLetter)
    }

    func testSpaceWithNoInputCommitsSpace() {
        let s = testSession()
        let out = s.processKey(.space)
        XCTAssertEqual(out.committed, " ")
    }

    func testEscapeClearsKeystrokes() {
        let s = testSession()
        _ = s.processKey(.letter("t"))
        _ = s.processKey(.letter("g"))
        XCTAssertFalse(s.keystrokes.isEmpty)
        let out = s.processKey(.escape)
        XCTAssertFalse(out.shouldQuit)
        XCTAssertTrue(s.keystrokes.isEmpty)
        XCTAssertTrue(s.candidates.isEmpty)
    }

    func testEscapeIdleDoesNothing() {
        let s = testSession()
        let out = s.processKey(.escape)
        XCTAssertFalse(out.shouldQuit)
        XCTAssertTrue(s.keystrokes.isEmpty)
    }

    func testEscapeInLetterModeClearsAndReturns() {
        let s = testSession()
        _ = s.processKey(.toggleLetterMode)
        _ = s.processKey(.letter("f"))
        XCTAssertEqual(s.letterBuffer, "j")
        let out = s.processKey(.escape)
        XCTAssertFalse(out.shouldQuit)
        XCTAssertTrue(s.letterBuffer.isEmpty)
        XCTAssertEqual(s.mode, .disambiguation)
    }

    func testBackspaceEmptySignalsDeletePreceding() {
        let s = testSession()
        let out = s.processKey(.backspace)
        XCTAssertTrue(out.consumed)
        XCTAssertEqual(out.deletePreceding, 1)
        XCTAssertNil(out.committed)
    }

    func testBackspaceEmptyLetterModeSignalsDeletePreceding() {
        let s = testSession()
        _ = s.processKey(.toggleLetterMode)
        let out = s.processKey(.backspace)
        XCTAssertTrue(out.consumed)
        XCTAssertEqual(out.deletePreceding, 1)
    }

    func testSpaceConfirmsWithoutTrailingSpace() {
        let s = testSession()
        _ = s.processKey(.letter("t"))
        _ = s.processKey(.letter("g"))
        _ = s.processKey(.letter("e"))
        let out = s.processKey(.space)
        let committed = out.committed!
        XCTAssertEqual(committed, "The")
        XCTAssertFalse(committed.hasSuffix(" "))
    }

    func testEnterConfirmsWithoutTrailingNewline() {
        let s = testSession()
        _ = s.processKey(.letter("t"))
        _ = s.processKey(.letter("g"))
        _ = s.processKey(.letter("e"))
        let out = s.processKey(.enter)
        let committed = out.committed!
        XCTAssertEqual(committed, "The")
        XCTAssertFalse(committed.hasSuffix("\n"))
    }

    func testSpaceInLetterModeCommitsWithoutTrailingSpace() {
        let s = testSession()
        _ = s.processKey(.toggleLetterMode)
        _ = s.processKey(.letter("f"))
        _ = s.processKey(.letter("r"))
        XCTAssertEqual(s.letterBuffer, "ju")
        let out = s.processKey(.space)
        XCTAssertEqual(out.committed, "Ju")
        XCTAssertEqual(s.mode, .disambiguation)
    }

    func testPunctuationAutoConfirmsWithCandidates() {
        let s = testSession()
        _ = s.processKey(.letter("t"))
        _ = s.processKey(.letter("g"))
        _ = s.processKey(.letter("e"))
        let out = s.processKey(.punctuation("."))
        let committed = out.committed!
        XCTAssertEqual(committed, "The.")
        XCTAssertTrue(s.keystrokes.isEmpty)
        XCTAssertTrue(s.candidates.isEmpty)
    }

    func testPunctuationIdleCommitsChar() {
        let s = testSession()
        let out = s.processKey(.punctuation(","))
        XCTAssertEqual(out.committed, ",")
        XCTAssertTrue(out.consumed)
    }

    func testPunctuationDiscardsUnmatchedKeystrokes() {
        let s = testSession()
        _ = s.processKey(.letter("z"))
        _ = s.processKey(.letter("z"))
        _ = s.processKey(.letter("z"))
        XCTAssertTrue(s.candidates.isEmpty)
        XCTAssertFalse(s.keystrokes.isEmpty)
        let out = s.processKey(.punctuation("!"))
        XCTAssertEqual(out.committed, "!")
        XCTAssertTrue(s.keystrokes.isEmpty)
    }

    func testPunctuationInLetterModeCommitsBuffer() {
        let s = testSession()
        _ = s.processKey(.toggleLetterMode)
        _ = s.processKey(.letter("f"))
        _ = s.processKey(.letter("r"))
        XCTAssertEqual(s.letterBuffer, "ju")
        let out = s.processKey(.punctuation("."))
        XCTAssertEqual(out.committed, "Ju.")
        XCTAssertTrue(s.letterBuffer.isEmpty)
        XCTAssertEqual(s.mode, .disambiguation)
    }

    func testPunctuationEmptyLetterModeCommitsChar() {
        let s = testSession()
        _ = s.processKey(.toggleLetterMode)
        let out = s.processKey(.punctuation("?"))
        XCTAssertEqual(out.committed, "?")
        XCTAssertEqual(s.mode, .disambiguation)
    }

    func testNumberWithoutCandidatesCommitsDigit() {
        let s = testSession()
        let out = s.processKey(.number(7))
        XCTAssertEqual(out.committed, "7")
        XCTAssertTrue(out.consumed)
    }

    func testNumber1WithoutCandidatesCommitsDigit() {
        let s = testSession()
        let out = s.processKey(.number(1))
        XCTAssertEqual(out.committed, "1")
    }

    func testNumber0CommitsDigit() {
        let s = testSession()
        let out = s.processKey(.number(0))
        XCTAssertEqual(out.committed, "0")
    }

    func testNumber6WithCandidatesAutoConfirmsAndInsertsDigit() {
        let s = testSession()
        _ = s.processKey(.letter("t"))
        _ = s.processKey(.letter("g"))
        _ = s.processKey(.letter("e"))
        let out = s.processKey(.number(6))
        XCTAssertEqual(out.committed, "The6")
        XCTAssertTrue(s.keystrokes.isEmpty)
    }

    func testNumberInLetterModeCommitsBufferAndDigit() {
        let s = testSession()
        _ = s.processKey(.toggleLetterMode)
        _ = s.processKey(.letter("f"))
        _ = s.processKey(.letter("r"))
        XCTAssertEqual(s.letterBuffer, "ju")
        let out = s.processKey(.number(3))
        XCTAssertEqual(out.committed, "Ju3")
        XCTAssertTrue(s.letterBuffer.isEmpty)
        XCTAssertEqual(s.mode, .disambiguation)
    }

    func testVisibleCandidatesReturnsCurrentPage() {
        let s = testSession()
        _ = s.processKey(.letter("t"))
        _ = s.processKey(.letter("g"))
        let page0 = s.visibleCandidates.map(\.word)
        XCTAssertTrue(page0.count <= 5)
        _ = s.processKey(.tab)
        let page1 = s.visibleCandidates.map(\.word)
        XCTAssertTrue(page1.count <= 5)
        XCTAssertNotEqual(page0[0], page1[0])
    }

    func testFirstCommitIsCapitalized() {
        let s = testSession()
        _ = s.processKey(.letter("t"))
        _ = s.processKey(.letter("g"))
        _ = s.processKey(.letter("e"))
        let out = s.processKey(.space)
        XCTAssertEqual(out.committed, "The")
    }

    func testSecondCommitIsNotCapitalized() {
        let s = testSession()
        _ = s.processKey(.letter("t"))
        _ = s.processKey(.letter("g"))
        _ = s.processKey(.letter("e"))
        _ = s.processKey(.space)
        _ = s.processKey(.letter("t"))
        _ = s.processKey(.letter("g"))
        _ = s.processKey(.letter("e"))
        let out = s.processKey(.space)
        XCTAssertEqual(out.committed, "the")
    }

    func testCapitalizeAfterPeriod() {
        let s = testSession()
        _ = s.processKey(.letter("t"))
        _ = s.processKey(.letter("g"))
        _ = s.processKey(.letter("e"))
        _ = s.processKey(.punctuation("."))
        _ = s.processKey(.letter("t"))
        _ = s.processKey(.letter("g"))
        _ = s.processKey(.letter("e"))
        let out = s.processKey(.space)
        XCTAssertEqual(out.committed, "The")
    }

    func testNoCapitalizeAfterComma() {
        let s = testSession()
        _ = s.processKey(.letter("t"))
        _ = s.processKey(.letter("g"))
        _ = s.processKey(.letter("e"))
        _ = s.processKey(.punctuation(","))
        _ = s.processKey(.letter("t"))
        _ = s.processKey(.letter("g"))
        _ = s.processKey(.letter("e"))
        let out = s.processKey(.space)
        XCTAssertEqual(out.committed, "the")
    }

    func testCapitalizeAfterNewline() {
        let s = testSession()
        _ = s.processKey(.letter("t"))
        _ = s.processKey(.letter("g"))
        _ = s.processKey(.letter("e"))
        _ = s.processKey(.space)
        _ = s.processKey(.enter)
        _ = s.processKey(.letter("t"))
        _ = s.processKey(.letter("g"))
        _ = s.processKey(.letter("e"))
        let out = s.processKey(.space)
        XCTAssertEqual(out.committed, "The")
    }

    func testCapitalizeSpaceDoesNotConsumeFlag() {
        let s = testSession()
        _ = s.processKey(.space)
        _ = s.processKey(.letter("t"))
        _ = s.processKey(.letter("g"))
        _ = s.processKey(.letter("e"))
        let out = s.processKey(.space)
        XCTAssertEqual(out.committed, "The")
    }

    func testCapitalizeInLetterMode() {
        let s = testSession()
        _ = s.processKey(.toggleLetterMode)
        _ = s.processKey(.letter("f"))
        _ = s.processKey(.letter("r"))
        let out = s.processKey(.space)
        XCTAssertEqual(out.committed, "Ju")
    }
}
