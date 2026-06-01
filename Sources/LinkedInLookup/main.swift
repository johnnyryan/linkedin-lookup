import AppKit

// Headless mode for testing the resolver:  LinkedInLookup --search "Some Name"
if let idx = CommandLine.arguments.firstIndex(of: "--search"),
   idx + 1 < CommandLine.arguments.count {
    let name = CommandLine.arguments[idx + 1]
    let sema = DispatchSemaphore(value: 0)
    Task {
        do {
            let results = try await Resolver.search(name: name)
            if results.isEmpty {
                print("No results for \"\(name)\".")
            } else {
                print("\(results.count) candidate(s) for \"\(name)\":\n")
                for c in results {
                    print("• \(c.title)")
                    print("  \(c.url.absoluteString)\n")
                }
            }
        } catch {
            print("Error: \(error.localizedDescription)")
        }
        sema.signal()
    }
    sema.wait()
    exit(0)
}

// GUI mode: floating drop panel.
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
