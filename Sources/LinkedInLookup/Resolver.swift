import Foundation

struct Candidate: Identifiable, Hashable {
    let id = UUID()
    let title: String   // cleaned "Name — Headline — Company"
    let url: URL        // canonical https://www.linkedin.com/in/<slug>
}

enum ResolverError: LocalizedError {
    case badResponse(Int)
    case noNetwork

    var errorDescription: String? {
        switch self {
        case .badResponse(let code): return "Search returned HTTP \(code)."
        case .noNetwork: return "Could not reach the search engine."
        }
    }
}

/// Finds candidate LinkedIn profiles for a name via free web-search scraping.
/// Brave Search is the primary source (it honors `site:` and returns clean
/// markup); Bing is a best-effort fallback if Brave yields nothing.
enum Resolver {

    static func search(name: String) async throws -> [Candidate] {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let query = "site:linkedin.com/in \"\(trimmed)\""

        if let brave = try? await searchBrave(query: query), !brave.isEmpty {
            return dedupe(brave)
        }
        let bing = (try? await searchBing(query: query)) ?? []
        return dedupe(bing)
    }

    // MARK: - Engines

    private static func searchBrave(query: String) async throws -> [Candidate] {
        let html = try await fetchHTML("https://search.brave.com/search?q=\(encode(query))")
        return parseBrave(html)
    }

    private static func searchBing(query: String) async throws -> [Candidate] {
        let html = try await fetchHTML("https://www.bing.com/search?q=\(encode(query))&count=20")
        // Best-effort: grab any LinkedIn profile URL from hrefs, title = slug.
        let urls = matches(html, #"href="(https?://[a-z.]*linkedin\.com/in/[^"]+)""#, group: 1)
        return urls.compactMap { raw in
            guard let url = canonicalLinkedIn(raw) else { return nil }
            return Candidate(title: prettySlug(url), url: url)
        }
    }

    // MARK: - Brave parsing

    private static func parseBrave(_ html: String) -> [Candidate] {
        var doc = html
        doc = doc.replacingOccurrences(of: #"(?s)<style[^>]*>.*?</style>"#, with: "", options: [.regularExpression, .caseInsensitive])
        doc = doc.replacingOccurrences(of: #"(?s)<script[^>]*>.*?</script>"#, with: "", options: [.regularExpression, .caseInsensitive])

        // Each result card lists its URL (an "l1" anchor) before its title
        // (a "snippet-title" element). Both appear once per card in document
        // order, so we zip them by index.
        let urls = matches(doc, #"<a\s+href="(https://[a-z.]*linkedin\.com/in/[^"]+)"[^>]*class="[^"]*\bl1\b[^"]*""#, group: 1)
        let titles = matches(doc, #"class="[^"]*snippet-title[^"]*"[^>]*>(.*?)</"#, group: 1).map(cleanTitle)

        var out: [Candidate] = []
        for (i, raw) in urls.enumerated() {
            guard let url = canonicalLinkedIn(raw) else { continue }
            let title = (i < titles.count && !titles[i].isEmpty) ? titles[i] : prettySlug(url)
            out.append(Candidate(title: title, url: url))
        }
        return out
    }

    // MARK: - Networking

    private static func fetchHTML(_ urlString: String) async throws -> String {
        guard let url = URL(string: urlString) else { throw ResolverError.noNetwork }
        var req = URLRequest(url: url)
        req.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15",
                     forHTTPHeaderField: "User-Agent")
        req.setValue("text/html,application/xhtml+xml", forHTTPHeaderField: "Accept")
        req.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        req.timeoutInterval = 15
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw ResolverError.noNetwork }
        guard http.statusCode == 200 else { throw ResolverError.badResponse(http.statusCode) }
        return String(data: data, encoding: .utf8) ?? ""
    }

    // MARK: - URL handling

    /// Normalize any LinkedIn result URL to https://www.linkedin.com/in/<slug>.
    /// Collapses locale subdomains (uk., de., …) so the same person dedupes.
    private static func canonicalLinkedIn(_ raw: String) -> URL? {
        var s = raw
        if s.hasPrefix("//") { s = "https:" + s }
        guard let comps = URLComponents(string: s),
              let host = comps.host?.lowercased(),
              host.contains("linkedin.com") else { return nil }
        guard let r = comps.path.range(of: "/in/", options: .caseInsensitive) else { return nil }
        var slug = String(comps.path[r.upperBound...])
        if let slash = slug.firstIndex(of: "/") { slug = String(slug[..<slash]) }
        slug = slug.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !slug.isEmpty else { return nil }
        return URL(string: "https://www.linkedin.com/in/\(slug)")
    }

    /// Fallback label from a slug: "john-a-smith1" -> "john a smith1".
    private static func prettySlug(_ url: URL) -> String {
        let slug = url.lastPathComponent.removingPercentEncoding ?? url.lastPathComponent
        return slug.replacingOccurrences(of: "-", with: " ")
    }

    // MARK: - Text helpers

    private static func cleanTitle(_ raw: String) -> String {
        var t = unescapeEntities(stripTags(raw))
        for suffix in [" | LinkedIn", " - LinkedIn"] {
            if let r = t.range(of: suffix, options: [.caseInsensitive, .backwards]) {
                t = String(t[..<r.lowerBound])
            }
        }
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func stripTags(_ s: String) -> String {
        s.replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)
    }

    private static func unescapeEntities(_ s: String) -> String {
        var t = s
        let map = ["&amp;": "&", "&lt;": "<", "&gt;": ">", "&quot;": "\"",
                   "&#39;": "'", "&#x27;": "'", "&#x2F;": "/", "&nbsp;": " ", "&middot;": "·"]
        for (k, v) in map { t = t.replacingOccurrences(of: k, with: v) }
        return t
    }

    private static func encode(_ s: String) -> String {
        s.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? s
    }

    private static func matches(_ text: String, _ pattern: String, group: Int) -> [String] {
        guard let re = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators, .caseInsensitive]) else { return [] }
        let ns = text as NSString
        return re.matches(in: text, range: NSRange(location: 0, length: ns.length)).compactMap { m in
            guard m.numberOfRanges > group else { return nil }
            return ns.substring(with: m.range(at: group))
        }
    }

    private static func dedupe(_ list: [Candidate]) -> [Candidate] {
        var seen = Set<String>()
        var out: [Candidate] = []
        for c in list where seen.insert(c.url.absoluteString.lowercased()).inserted {
            out.append(c)
        }
        return out
    }
}
