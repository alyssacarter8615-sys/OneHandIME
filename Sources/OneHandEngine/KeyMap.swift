public struct KeyMap {
    private let map: [Character: [Character]]

    private init(_ map: [Character: [Character]]) {
        self.map = map
    }

    public static func leftHand() -> KeyMap {
        KeyMap([
            "q": ["q", "p"],
            "w": ["w", "o"],
            "e": ["e", "i"],
            "r": ["r", "u"],
            "t": ["t", "y"],
            "a": ["a"],
            "s": ["s", "l"],
            "d": ["d", "k"],
            "f": ["f", "j"],
            "g": ["g", "h"],
            "z": ["z"],
            "x": ["x"],
            "c": ["c"],
            "v": ["v", "m"],
            "b": ["b", "n"],
            "p": ["p"],
            "o": ["o"],
            "i": ["i"],
            "u": ["u"],
            "y": ["y"],
            "l": ["l"],
            "k": ["k"],
            "j": ["j"],
            "h": ["h"],
            "m": ["m"],
            "n": ["n"],
        ])
    }

    public func candidates(_ key: Character) -> [Character]? {
        map[key]
    }

    public func primary(_ key: Character) -> Character? {
        map[key]?.first
    }

    public func secondary(_ key: Character) -> Character? {
        map[key]?.last
    }
}
