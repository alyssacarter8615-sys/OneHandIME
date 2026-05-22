#if os(macOS)
import Cocoa
import InputMethodKit
import OneHandEngine

class IMKController: IMKInputController {
    private var session: InputSession?

    override init!(server: IMKServer!, delegate: Any!, client inputClient: Any!) {
        super.init(server: server, delegate: delegate, client: inputClient)
        let trie = try? DictLoader.load(
            from: Bundle.main.path(forResource: "wordfreq", ofType: "txt") ?? "",
            maxWords: 50000
        )
        if let trie = trie {
            let engine = Engine(keymap: KeyMap.leftHand(), trie: trie)
            session = InputSession(engine: engine)
        }
    }

    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        guard let event = event, let session = session else { return false }
        guard let keyEvent = mapEvent(event) else { return false }

        let output = session.processKey(keyEvent)

        if let client = sender as? IMKTextInput {
            if let text = output.committed {
                client.insertText(text, replacementRange: NSRange(location: NSNotFound, length: 0))
            }
            if output.deletePreceding > 0 {
                let range = client.selectedRange()
                if range.location >= output.deletePreceding {
                    client.insertText("", replacementRange: NSRange(
                        location: range.location - output.deletePreceding,
                        length: output.deletePreceding
                    ))
                }
            }
            let preedit = output.preedit
            if !preedit.isEmpty {
                client.setMarkedText(preedit, selectionRange: NSRange(location: preedit.count, length: 0),
                                     replacementRange: NSRange(location: NSNotFound, length: 0))
            } else {
                client.setMarkedText("", selectionRange: NSRange(location: 0, length: 0),
                                     replacementRange: NSRange(location: NSNotFound, length: 0))
            }
        }

        return output.consumed
    }

    private func mapEvent(_ event: NSEvent) -> KeyEvent? {
        if event.modifierFlags.contains(.command) { return nil }

        switch event.keyCode {
        case 53: return .escape
        case 48:
            if event.modifierFlags.contains(.shift) { return .backTab }
            return .tab
        case 36: return .enter
        case 49: return .space
        case 51: return .backspace
        case 50: return .toggleLetterMode  // backtick key
        default: break
        }

        guard let chars = event.characters, let ch = chars.first else { return nil }

        if ch.isLetter {
            return .letter(ch)
        } else if ch.isNumber, let digit = ch.wholeNumberValue {
            return .number(UInt8(digit))
        } else if ch.isPunctuation || ch.isSymbol {
            return .punctuation(ch)
        }

        return nil
    }
}
#endif
