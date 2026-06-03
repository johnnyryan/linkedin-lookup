import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        installMainMenu()
        let hosting = NSHostingView(rootView: ContentView())
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 520),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "LinkedIn Lookup"
        window.contentView = hosting
        window.contentMinSize = NSSize(width: 340, height: 420)
        window.setFrameAutosaveName("LinkedInLookupMainPanel")
        if !window.setFrameUsingName("LinkedInLookupMainPanel") {
            window.center()
        }
        window.makeKeyAndOrderFront(nil)
        self.window = window
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    private func installMainMenu() {
        let mainMenu = NSMenu()

        let appItem = NSMenuItem()
        mainMenu.addItem(appItem)
        let appMenu = NSMenu()
        appItem.submenu = appMenu
        let aboutItem = NSMenuItem(title: "About LinkedIn Lookup", action: #selector(showAbout(_:)), keyEquivalent: "")
        aboutItem.target = self
        appMenu.addItem(aboutItem)
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Hide LinkedIn Lookup", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit LinkedIn Lookup", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        let editItem = NSMenuItem()
        mainMenu.addItem(editItem)
        let editMenu = NSMenu(title: "Edit")
        editItem.submenu = editMenu
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

        NSApp.mainMenu = mainMenu
    }

    @objc private func showAbout(_ sender: Any?) {
        let license = """
        MIT License

        Copyright (c) 2026 Johnny Ryan

        Permission is hereby granted, free of charge, to any person obtaining a \
        copy of this software and associated documentation files (the "Software"), \
        to deal in the Software without restriction, including without limitation \
        the rights to use, copy, modify, merge, publish, distribute, sublicense, \
        and/or sell copies of the Software, and to permit persons to whom the \
        Software is furnished to do so, subject to the following conditions:

        The above copyright notice and this permission notice shall be included in \
        all copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR \
        IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, \
        FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE \
        AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER \
        LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING \
        FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER \
        DEALINGS IN THE SOFTWARE.
        """
        let credits = NSAttributedString(
            string: license,
            attributes: [.font: NSFont.systemFont(ofSize: 11)]
        )
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(options: [.credits: credits])
    }
}

struct ContentView: View {
    @State private var query = ""
    @State private var candidates: [Candidate] = []
    @State private var loading = false
    @State private var message = "Drag a selected name onto the box below — or type one and press Return."
    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 12) {
            dropBox

            HStack(spacing: 8) {
                TextField("Name", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { runSearch(query) }
                Button("Search") { runSearch(query) }
                    .disabled(query.trimmingCharacters(in: .whitespaces).isEmpty || loading)
            }

            Divider()

            results
        }
        .padding(14)
        .frame(minWidth: 340, minHeight: 440)
    }

    private var dropBox: some View {
        RoundedRectangle(cornerRadius: 12)
            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [7]))
            .foregroundStyle(isTargeted ? Color.accentColor : Color.secondary.opacity(0.4))
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isTargeted ? Color.accentColor.opacity(0.08) : Color.clear)
            )
            .frame(height: 78)
            .overlay(
                Text(isTargeted ? "Release to look up" : "⤓  Drop a name here")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            )
            .dropDestination(for: String.self) { items, _ in
                guard let text = items.first else { return false }
                runSearch(text)
                return true
            } isTargeted: { isTargeted = $0 }
    }

    @ViewBuilder
    private var results: some View {
        if loading {
            VStack(spacing: 8) {
                ProgressView()
                Text("Searching “\(query)”…").font(.callout).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if candidates.isEmpty {
            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 8)
        } else {
            List(candidates) { c in
                Button {
                    NSWorkspace.shared.open(c.url)
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(c.title.isEmpty ? c.url.lastPathComponent : c.title)
                            .fontWeight(.medium)
                            .lineLimit(2)
                        Text(c.url.absoluteString)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .padding(.vertical, 2)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .listStyle(.inset)
        }
    }

    private func runSearch(_ raw: String) {
        let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        query = name
        loading = true
        candidates = []
        message = ""
        Task {
            do {
                let found = try await Resolver.search(name: name)
                await MainActor.run {
                    candidates = found
                    loading = false
                    if found.isEmpty {
                        message = "No public LinkedIn profiles found for “\(name)”.\nTry adding a company or city to the name."
                    }
                }
            } catch {
                await MainActor.run {
                    loading = false
                    message = "Search failed: \(error.localizedDescription)"
                }
            }
        }
    }
}
