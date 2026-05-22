public struct Candidate: Equatable {
    public let word: String
    public let logFreq: Double

    public init(word: String, logFreq: Double) {
        self.word = word
        self.logFreq = logFreq
    }
}

private class TrieNode {
    var children: [Character: TrieNode] = [:]
    var entry: Candidate?
}

public class Trie {
    private let root = TrieNode()

    public init() {}

    public func insert(_ word: String, logFreq: Double) {
        var node = root
        for ch in word {
            if let child = node.children[ch] {
                node = child
            } else {
                let child = TrieNode()
                node.children[ch] = child
                node = child
            }
        }
        node.entry = Candidate(word: word, logFreq: logFreq)
    }

    public func search(_ candidateSets: [[Character]]) -> [Candidate] {
        if candidateSets.isEmpty { return [] }
        var results: [Candidate] = []
        searchFrom(root, sets: candidateSets, depth: 0, results: &results)
        results.sort { $0.logFreq > $1.logFreq }
        return results
    }

    private func searchFrom(_ node: TrieNode, sets: [[Character]], depth: Int, results: inout [Candidate]) {
        if depth == sets.count {
            if let entry = node.entry {
                results.append(entry)
            }
            collectBelow(node, results: &results)
            return
        }
        for ch in sets[depth] {
            if let child = node.children[ch] {
                searchFrom(child, sets: sets, depth: depth + 1, results: &results)
            }
        }
    }

    private func collectBelow(_ node: TrieNode, results: inout [Candidate]) {
        for child in node.children.values {
            if let entry = child.entry {
                results.append(entry)
            }
            collectBelow(child, results: &results)
        }
    }
}
