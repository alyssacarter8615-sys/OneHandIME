public enum KeyEvent: Equatable {
    case letter(Character)
    case space
    case enter
    case backspace
    case tab
    case backTab
    case number(UInt8)
    case punctuation(Character)
    case toggleLetterMode
    case escape
}

public enum Mode: Equatable {
    case disambiguation
    case primaryLetter
    case secondaryLetter
}

public struct EngineOutput {
    public let consumed: Bool
    public let committed: String?
    public let preedit: String
    public let candidates: [Candidate]
    public let page: Int
    public let totalPages: Int
    public let mode: Mode
    public let shouldQuit: Bool
    public let capitalizeNext: Bool
    public let deletePreceding: Int
}

private let pageSize = 5

public class InputSession {
    private let engine: Engine
    private var _mode: Mode = .disambiguation
    private var _keystrokes: [Character] = []
    private var _letterBuffer: String = ""
    private var _candidates: [Candidate] = []
    private var _page: Int = 0
    private var _capitalizeNext: Bool = true

    public init(engine: Engine) {
        self.engine = engine
    }

    public var mode: Mode { _mode }
    public var keystrokes: [Character] { _keystrokes }
    public var letterBuffer: String { _letterBuffer }
    public var candidates: [Candidate] { _candidates }
    public var page: Int { _page }

    public var totalPages: Int {
        _candidates.isEmpty ? 0 : (_candidates.count - 1) / pageSize + 1
    }

    public var visibleCandidates: [Candidate] {
        let start = _page * pageSize
        guard start < _candidates.count else { return [] }
        let end = min(start + pageSize, _candidates.count)
        return Array(_candidates[start..<end])
    }

    public func processKey(_ key: KeyEvent) -> EngineOutput {
        var committed: String? = nil
        var consumed = true
        var deletePreceding = 0

        switch key {
        case .escape:
            switch _mode {
            case .disambiguation:
                if !_keystrokes.isEmpty {
                    resetInput()
                }
            case .primaryLetter, .secondaryLetter:
                _letterBuffer = ""
                _mode = .disambiguation
            }
        case .toggleLetterMode:
            toggleLetterMode()
        default:
            switch _mode {
            case .disambiguation:
                committed = handleDisambiguation(key, consumed: &consumed, deletePreceding: &deletePreceding)
            case .primaryLetter, .secondaryLetter:
                committed = handleLetter(key, consumed: &consumed, deletePreceding: &deletePreceding)
            }
        }

        if var text = committed {
            if _capitalizeNext && text.contains(where: { $0.isASCII && $0.isLetter }) {
                text = Self.capitalizeFirstAlpha(text)
                committed = text
                _capitalizeNext = false
            }
            if let last = text.last, ".!?\n".contains(last) {
                _capitalizeNext = true
            }
        }

        return EngineOutput(
            consumed: consumed,
            committed: committed,
            preedit: currentPreedit(),
            candidates: visibleCandidates,
            page: _page,
            totalPages: totalPages,
            mode: _mode,
            shouldQuit: false,
            capitalizeNext: _capitalizeNext,
            deletePreceding: deletePreceding
        )
    }

    private func toggleLetterMode() {
        switch _mode {
        case .disambiguation:
            _keystrokes.removeAll()
            _candidates.removeAll()
            _page = 0
            _mode = .secondaryLetter
        case .secondaryLetter:
            _mode = .primaryLetter
        case .primaryLetter:
            _mode = .secondaryLetter
        }
    }

    private func handleDisambiguation(_ key: KeyEvent, consumed: inout Bool, deletePreceding: inout Int) -> String? {
        switch key {
        case .letter(let c):
            _keystrokes.append(Character(String(c).lowercased()))
            _candidates = engine.search(_keystrokes)
            _page = 0
            return nil
        case .number(let n):
            if n >= 1 && n <= 5 && !_candidates.isEmpty {
                let idx = Int(n - 1) + _page * pageSize
                if idx < _candidates.count {
                    let word = _candidates[idx].word
                    resetInput()
                    return word
                }
                return nil
            } else {
                var text = ""
                if let candidate = _candidates.first {
                    text += candidate.word
                    resetInput()
                } else if !_keystrokes.isEmpty {
                    resetInput()
                }
                text.append(Character(UnicodeScalar(48 + n)))
                return text
            }
        case .space, .enter:
            if let candidate = _candidates.first {
                let text = candidate.word
                resetInput()
                return text
            } else if _keystrokes.isEmpty {
                if case .enter = key { return "\n" }
                return " "
            }
            return nil
        case .backspace:
            if _keystrokes.isEmpty {
                deletePreceding = 1
            } else {
                _keystrokes.removeLast()
                _page = 0
                if _keystrokes.isEmpty {
                    _candidates.removeAll()
                } else {
                    _candidates = engine.search(_keystrokes)
                }
            }
            return nil
        case .tab:
            let maxPage = self.maxPage
            if _page < maxPage {
                _page += 1
            }
            return nil
        case .backTab:
            if _page > 0 { _page -= 1 }
            return nil
        case .punctuation(let ch):
            var text = ""
            if let candidate = _candidates.first {
                text += candidate.word
                resetInput()
            } else if !_keystrokes.isEmpty {
                resetInput()
            }
            text.append(ch)
            return text
        default:
            consumed = false
            return nil
        }
    }

    private func handleLetter(_ key: KeyEvent, consumed: inout Bool, deletePreceding: inout Int) -> String? {
        switch key {
        case .letter(let c):
            let lc = Character(String(c).lowercased())
            let letter: Character?
            switch _mode {
            case .secondaryLetter:
                letter = engine.secondaryLetter(lc)
            case .primaryLetter:
                letter = engine.primaryLetter(lc)
            default:
                letter = nil
            }
            if let l = letter {
                _letterBuffer.append(l)
            }
            return nil
        case .space, .enter:
            let committed: String?
            if !_letterBuffer.isEmpty {
                committed = _letterBuffer
                _letterBuffer = ""
            } else if case .enter = key {
                committed = "\n"
            } else {
                committed = " "
            }
            _mode = .disambiguation
            return committed
        case .backspace:
            if _letterBuffer.isEmpty {
                deletePreceding = 1
            } else {
                _letterBuffer.removeLast()
            }
            return nil
        case .punctuation(let ch):
            var text = _letterBuffer
            _letterBuffer = ""
            text.append(ch)
            _mode = .disambiguation
            return text
        case .number(let n):
            var text = _letterBuffer
            _letterBuffer = ""
            text.append(Character(UnicodeScalar(48 + n)))
            _mode = .disambiguation
            return text
        default:
            consumed = false
            return nil
        }
    }

    private func resetInput() {
        _keystrokes.removeAll()
        _candidates.removeAll()
        _page = 0
    }

    private var maxPage: Int {
        _candidates.isEmpty ? 0 : (_candidates.count - 1) / pageSize
    }

    private static func capitalizeFirstAlpha(_ s: String) -> String {
        var result = ""
        var capitalized = false
        for ch in s {
            if !capitalized && ch.isASCII && ch.isLetter {
                result.append(Character(ch.uppercased()))
                capitalized = true
            } else {
                result.append(ch)
            }
        }
        return result
    }

    private func currentPreedit() -> String {
        switch _mode {
        case .disambiguation:
            return _keystrokes.map { String($0).uppercased() }.joined(separator: "-")
        case .primaryLetter, .secondaryLetter:
            return _letterBuffer
        }
    }
}
