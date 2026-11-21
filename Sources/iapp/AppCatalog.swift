import AppKit

struct LaunchableApp: Hashable {
    let name: String
    let url: URL
}

/// A per-session, in-memory index. Scanning happens only when the user opens the launcher.
final class AppCatalog {
    private var apps: [LaunchableApp] = []
    private var lastScan: Date = .distantPast

    func bestMatch(for query: String) -> LaunchableApp? {
        if Date().timeIntervalSince(lastScan) > 60 { scan() }
        let normalizedQuery = normalize(query)
        guard !normalizedQuery.isEmpty else { return nil }
        let ranked = apps.map { app in (app, score(normalizedQuery, against: normalize(app.name))) }
        guard let best = ranked.max(by: { $0.1 < $1.1 }), best.1 >= 6_000 else { return nil }
        return best.0
    }

    private func scan() {
        lastScan = Date()
        let roots = ["/Applications", "/System/Applications", "/System/Applications/Utilities", "~/Applications"]
            .map { NSString(string: $0).expandingTildeInPath }
            .map(URL.init(fileURLWithPath:))
        var found = Set<LaunchableApp>()

        for root in roots {
            // DirectoryEnumerator can omit a top-level app package when asked to
            // skip package descendants. Index direct children explicitly (Safari
            // lives at /Applications/Safari.app on this Mac).
            if let directChildren = try? FileManager.default.contentsOfDirectory(
                at: root,
                includingPropertiesForKeys: nil,
                options: []
            ) {
                for url in directChildren where url.pathExtension == "app" {
                    register(url, into: &found)
                }
            }
            guard let enumerator = FileManager.default.enumerator(
                at: root,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsPackageDescendants]
            ) else { continue }
            for case let url as URL in enumerator where url.pathExtension == "app" {
                register(url, into: &found)
            }
        }
        apps = found.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func register(_ url: URL, into apps: inout Set<LaunchableApp>) {
        let name = url.deletingPathExtension().lastPathComponent
        apps.insert(LaunchableApp(name: name, url: url))
    }

    private func normalize(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) }
            .map(String.init).joined()
    }

    private func score(_ query: String, against candidate: String) -> Int {
        if query == candidate { return 100_000 }
        if candidate.hasPrefix(query) { return 80_000 - candidate.count }
        if candidate.contains(query) { return 70_000 - candidate.count }
        if let subsequence = subsequenceScore(query, candidate) { return 50_000 + subsequence }
        // This makes short transpositions, omissions, and substitutions useful (dscird → discord).
        let distance = levenshtein(query, candidate)
        return max(0, 10_000 - distance * 1_000 - abs(query.count - candidate.count) * 100)
    }

    private func subsequenceScore(_ needle: String, _ haystack: String) -> Int? {
        var index = haystack.startIndex
        var gaps = 0
        for char in needle {
            guard let found = haystack[index...].firstIndex(of: char) else { return nil }
            gaps += haystack.distance(from: index, to: found)
            index = haystack.index(after: found)
        }
        return 10_000 - gaps
    }

    private func levenshtein(_ left: String, _ right: String) -> Int {
        let a = Array(left), b = Array(right)
        var row = Array(0...b.count)
        for (i, x) in a.enumerated() {
            var next = [i + 1]
            for (j, y) in b.enumerated() {
                next.append(min(next[j] + 1, row[j + 1] + 1, row[j] + (x == y ? 0 : 1)))
            }
            row = next
        }
        return row[b.count]
    }
}
