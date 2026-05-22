import Foundation

public enum DictLoader {
    public static func parse(_ content: String, maxWords: Int) -> Trie {
        var entries: [(String, Double)] = []
        for line in content.components(separatedBy: .newlines) {
            let parts = line.split(separator: "\t", maxSplits: 1)
            guard parts.count == 2 else { continue }
            let word = parts[0].trimmingCharacters(in: .whitespaces)
            guard let count = Double(parts[1].trimmingCharacters(in: .whitespaces)) else { continue }
            guard !word.isEmpty && word.allSatisfy({ $0.isASCII && $0.isLowercase }) else { continue }
            entries.append((word, count))
        }
        entries.sort { $0.1 > $1.1 }
        if entries.count > maxWords {
            entries = Array(entries.prefix(maxWords))
        }
        let trie = Trie()
        for (word, count) in entries {
            trie.insert(word, logFreq: log10(count))
        }
        return trie
    }

    public static func load(from path: String, maxWords: Int) throws -> Trie {
        let content = try String(contentsOfFile: path, encoding: .utf8)
        return parse(content, maxWords: maxWords)
    }
}
