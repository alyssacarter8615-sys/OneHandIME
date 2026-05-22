public struct Engine {
    private let keymap: KeyMap
    private let trie: Trie

    public init(keymap: KeyMap, trie: Trie) {
        self.keymap = keymap
        self.trie = trie
    }

    public func search(_ keystrokes: [Character]) -> [Candidate] {
        var sets: [[Character]] = []
        for k in keystrokes {
            guard let c = keymap.candidates(k) else { return [] }
            sets.append(c)
        }
        return trie.search(sets)
    }

    public func primaryLetter(_ key: Character) -> Character? {
        keymap.primary(key)
    }

    public func secondaryLetter(_ key: Character) -> Character? {
        keymap.secondary(key)
    }
}
