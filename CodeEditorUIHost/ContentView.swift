//
//  ContentView.swift
//  CodeEditorUIHost
//
//  Created by Miguel de Icaza on 3/29/24.
//

import SwiftUI
import Observation
import CodeEditorUI
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import TreeSitter
import Runestone
#endif

@MainActor
@Observable
final class MyDelegate: NSObject, EditedItemDelegate {
    var contextMenuRequest: MonacoContextMenuRequest?
    var contextMenuItem: EditedItem?
    var commandPaletteRequest: MonacoCommandPaletteRequest?
    var commandPaletteItem: EditedItem?

    func save(editedItem: CodeEditorUI.EditedItem, contents: String, newPath: String?) -> CodeEditorUI.HostServiceIOError? {
        print("Attempt to save")
        return nil
    }
    
    func closing(_ editedItem: CodeEditorUI.EditedItem) {
        print ("Closing item")
    }
    
    func lookup(_ editedItem: CodeEditorUI.EditedItem, on: EditorTextView, at: EditorTextPosition, word: String) {
        print ("Lookup word")
    }
    
    func lookup(_ editedItem: CodeEditorUI.EditedItem, word: String) {
        print ("Looking up \(word)")
    }

    func contextMenuRequested(_ editedItem: EditedItem, on: EditorTextView, request: MonacoContextMenuRequest) {
#if canImport(AppKit)
        showContextMenu(for: editedItem, on: on, request: request)
#else
        _ = on
        contextMenuItem = editedItem
        contextMenuRequest = request
        if let location = request.location {
            print("Context menu requested at line \(location.lineNumber + 1), col \(location.column + 1)")
        } else {
            print("Context menu requested")
        }
#endif
    }

    func commandPaletteRequested(_ editedItem: EditedItem, on: EditorTextView, request: MonacoCommandPaletteRequest) {
        _ = on
        commandPaletteItem = editedItem
        commandPaletteRequest = request
        print("Command palette requested (\(request.actions.count) actions)")
    }

    func dismissContextMenu() {
        contextMenuRequest = nil
        contextMenuItem = nil
    }

    func dismissCommandPalette() {
        commandPaletteRequest = nil
        commandPaletteItem = nil
    }

#if canImport(AppKit)
    private func showContextMenu(for editedItem: EditedItem, on textView: EditorTextView, request: MonacoContextMenuRequest) {
        guard let monacoView = textView as? MonacoTextView,
              let webView = monacoView.webView else {
            return
        }
        let menu = NSMenu(title: "Monaco")
        addMenuItems(request.actions, to: menu, editedItem: editedItem)
        let point = menuPoint(from: request.viewPoint, in: webView)
        menu.popUp(positioning: nil, at: point, in: webView)
    }

    private func addMenuItems(_ items: [MonacoMenuItem], to menu: NSMenu, editedItem: EditedItem) {
        for item in items {
            switch item.kind {
            case .separator:
                menu.addItem(.separator())
            case .action:
                guard let id = item.id else { continue }
                let title = item.label ?? id
                let menuItem = NSMenuItem(title: title, action: #selector(performMenuAction(_:)), keyEquivalent: "")
                menuItem.target = self
                menuItem.isEnabled = item.enabled
                menuItem.representedObject = MenuActionContext(actionId: id, editedItem: editedItem)
                applyKeyEquivalent(item.keybinding, to: menuItem)
                applyIcon(for: id, to: menuItem)
                menu.addItem(menuItem)
            case .submenu:
                let title = item.label ?? "Submenu"
                let submenu = NSMenu(title: title)
                addMenuItems(item.children, to: submenu, editedItem: editedItem)
                if submenu.items.isEmpty {
                    continue
                }
                let menuItem = NSMenuItem(title: title, action: nil, keyEquivalent: "")
                menuItem.submenu = submenu
                menu.addItem(menuItem)
            }
        }
    }

    private func menuPoint(from viewPoint: CGPoint?, in view: NSView) -> NSPoint {
        if let viewPoint {
            let point = NSPoint(x: viewPoint.x, y: viewPoint.y)
            let padding = NSSize(width: 2, height: 2)
            if view.isFlipped {
                return NSPoint(x: point.x + padding.width, y: point.y + padding.height)
            }
            let flippedY = view.bounds.height - point.y
            return NSPoint(x: point.x + padding.width, y: flippedY - padding.height)
        }
        let screenPoint = NSEvent.mouseLocation
        guard let window = view.window else {
            return NSPoint(x: 0, y: 0)
        }
        let windowPoint = window.convertPoint(fromScreen: screenPoint)
        return view.convert(windowPoint, from: nil)
    }

    @objc private func performMenuAction(_ sender: NSMenuItem) {
        guard let context = sender.representedObject as? MenuActionContext else { return }
        context.editedItem.commands.runAction(id: context.actionId)
    }

    private func applyIcon(for actionId: String, to menuItem: NSMenuItem) {
        let symbolName: String?
        symbolName = switch actionId {
        case "editor.action.clipboardCutAction", "cut":
            "scissors"
        case "editor.action.clipboardCopyAction":
            "document.on.document"
        case "editor.action.revealDefinition":
            "arrow.turn.down.right"
        case "editor.action.clipboardPasteAction":
            "document.on.clipboard"
        case "editor.action.rename":
            "character.cursor.ibeam"
        case "editor.action.quickCommand":
            "terminal"
        default:
            nil
        }
        if symbolName == nil {
            print("Did not have an icon for \(actionId)")
        }
        guard let symbolName,
              let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) else {
            return
        }
        menuItem.image = image
    }

    private func applyKeyEquivalent(_ keybinding: String?, to menuItem: NSMenuItem) {
        guard let keybinding, !keybinding.isEmpty else { return }
        guard let parsed = parseKeybinding(keybinding) else { return }
        menuItem.keyEquivalent = parsed.key
        menuItem.keyEquivalentModifierMask = parsed.modifiers
    }

    private func parseKeybinding(_ binding: String) -> (key: String, modifiers: NSEvent.ModifierFlags)? {
        let trimmed = binding.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return nil
        }
        var modifiers: NSEvent.ModifierFlags = []
        var keyToken = trimmed

        let hasSymbols = trimmed.contains("⌘") || trimmed.contains("⌥") || trimmed.contains("⌃") || trimmed.contains("⇧")
        if hasSymbols {
            if trimmed.contains("⌘") { modifiers.insert(.command) }
            if trimmed.contains("⌥") { modifiers.insert(.option) }
            if trimmed.contains("⌃") { modifiers.insert(.control) }
            if trimmed.contains("⇧") { modifiers.insert(.shift) }
            keyToken = trimmed
                .replacingOccurrences(of: "⌘", with: "")
                .replacingOccurrences(of: "⌥", with: "")
                .replacingOccurrences(of: "⌃", with: "")
                .replacingOccurrences(of: "⇧", with: "")
                .trimmingCharacters(in: .whitespaces)
        } else if trimmed.contains("+") {
            let parts = trimmed.split(separator: "+").map { $0.trimmingCharacters(in: .whitespaces) }
            for part in parts {
                let lower = part.lowercased()
                switch lower {
                case "cmd", "command", "⌘":
                    modifiers.insert(.command)
                case "ctrl", "control", "⌃":
                    modifiers.insert(.control)
                case "alt", "option", "opt", "⌥":
                    modifiers.insert(.option)
                case "shift", "⇧":
                    modifiers.insert(.shift)
                default:
                    keyToken = String(part)
                }
            }
        }

        let key = keyEquivalent(for: keyToken)
        return (key: key, modifiers: modifiers)
    }

    private func keyEquivalent(for token: String) -> String {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return ""
        }
        func makeKey(_ code: Int) -> String {
            if let scalar = UnicodeScalar(UInt32(code)) {
                return String(scalar)
            }
            return ""
        }
        let lower = trimmed.lowercased()
        switch lower {
        case "space", "spacebar", "␠":
            return " "
        case "tab", "⇥":
            return "\t"
        case "enter", "return", "⏎", "↩":
            return "\r"
        case "escape", "esc", "⎋":
            return String(UnicodeScalar(0x1b))
        case "backspace", "⌫":
            return String(UnicodeScalar(0x08))
        case "delete", "⌦":
            return makeKey(NSDeleteFunctionKey)
        case "up":
            return makeKey(NSUpArrowFunctionKey)
        case "down":
            return makeKey(NSDownArrowFunctionKey)
        case "left":
            return makeKey(NSLeftArrowFunctionKey)
        case "right":
            return makeKey(NSRightArrowFunctionKey)
        case "home":
            return makeKey(NSHomeFunctionKey)
        case "end":
            return makeKey(NSEndFunctionKey)
        case "pageup", "page up":
            return makeKey(NSPageUpFunctionKey)
        case "pagedown", "page down":
            return makeKey(NSPageDownFunctionKey)
        default:
            break
        }

        if lower.hasPrefix("f"), let number = Int(lower.dropFirst()), number >= 1, number <= 20 {
            let base = Int(NSF1FunctionKey)
            let scalarValue = UInt32(base + (number - 1))
            return String(UnicodeScalar(scalarValue)!)
        }

        if trimmed.count == 1 {
            return trimmed.lowercased()
        }
        return trimmed.lowercased()
    }
#endif
    
    deinit {
        print ("MyDelegate.deinit")
    }
    static func makeTestData () -> [CompletionEntry] {
        return [
            CompletionEntry(kind: .function, display: "print", insert: "print("),
            CompletionEntry(kind: .function, display: "print_error", insert: "print_error("),
            CompletionEntry(kind: .function, display: "print_another", insert: "print_another("),
            CompletionEntry(kind: .function, display: "print_dump", insert: "print_dump("),
            CompletionEntry(kind: .function, display: "print_stack", insert: "print_another("),
            CompletionEntry(kind: .function, display: "print_trebble", insert: "print_another("),
            CompletionEntry(kind: .class, display: "Poraint", insert: "Poraint"),
            CompletionEntry(kind: .variable, display: "apriornster", insert: "apriornster"),
            CompletionEntry(kind: .signal, display: "paraceleuinephedert", insert: "$paraceleuinephedert")
        ]
    }
    
    func started(editedItem: CodeEditorUI.EditedItem, textView: EditorTextView) {

    }
    
    /// Implements breakpoint toggling
    func gutterTapped(_ editedItem: EditedItem, _ textView: EditorTextView, _ line: Int) {
        if editedItem.breakpoints.contains(line) {
            editedItem.breakpoints.remove (line)
        } else {
            editedItem.breakpoints.insert (line)
        }
    }

    func editedTextChanged(_ editedItem: CodeEditorUI.EditedItem, _ textView: EditorTextView) {

        let range = textView.selectedRange
        guard range.length == 0 else {
            // We are not interested in doing completions when there is a selection going
            return
        }
        guard let startLoc = textView.textLocation(at: range.location) else {
            return
        }
        let lines = textView.text.split(separator: "\n", omittingEmptySubsequences: false)
        guard lines.count > startLoc.lineNumber else {
            return
        }
        let line = lines [startLoc.lineNumber]
        
        guard let r = textView.selectedTextRange else {
            return
        }
        #if canImport(UIKitt)
        var region = textView.firstRect(for: r)
        region.origin.y -= textView.contentOffset.y

        if line.hasSuffix("pri") {
            editedItem.requestCompletion (at: region, on: textView, prefix: "pri", completions: MyDelegate.makeTestData())
            
            let errors: [Issue] = [
                Issue(kind: .error, col: 1, line: 2, message: "This is a cute error"),
                Issue(kind: .error, col: 1, line: 3, message: "Another error")
            ]
            let warnings: [Issue] = [
                Issue(kind: .error, col: 1, line: 5, message: "Warning"),
                Issue(kind: .error, col: 1, line: 6, message: "I am telling you")
            ]

            editedItem.validationResult(functions: [("DemoAtLine10", 10), ("AnotherAtLine20", 20)], errors: errors, warnings: warnings)
        } else {
            editedItem.cancelCompletion()
        }
        #endif
    }
}

#if canImport(AppKit)
private struct MenuActionContext {
    let actionId: String
    let editedItem: EditedItem
}
#endif

func getSampleFiles () -> [String] {
    //return Bundle.main.paths(forResourcesOfType: ".gd", inDirectory: nil)
    return ["/Users/miguel/Downloads/godot-4-3d-third-person-controller-main/CameraMode/CameraMode.gd"]
}

@MainActor
var server: LspWebSocketProxy? = nil

@MainActor
struct ContentView: View {
    @State var state: CodeEditorState
    @State var delegate = MyDelegate ()
    @State var breakUtils = [0, 26, 120]
    @State var breakEmpty = [2]
    @State var htmlItem: HtmlItem? = nil
    @State var visible = false
    @State var sampleFiles = getSampleFiles()

    init() {
        let state = CodeEditorState()
#if canImport(AppKit)
        state.useMonacoEditor = true
#endif
        self._state = State(initialValue: state)
        state.lspWorkspaceRoot = "/Users/miguel/Downloads/godot-4-3d-third-person-controller-main/"
        if server == nil {
            server = try! LspWebSocketProxy()
            try! server?.start()
        }
    }

    var body: some View {
        VStack {
            Toggle(isOn: $visible) { Text ("Visible")}
            HStack {
                Button ("Toggle Tabs") {
                    state.showTabs.toggle()
                }
                Button ("Toggle Spaces"){
                    state.showSpaces.toggle()
                }
                Button ("Toggle Line#") {
                    state.showLines.toggle()
                }
                Button ("Search") {
                    state.search(showReplace: false)
                }
                Button ("Goto Line 1") {
                    state.goTo(line: 0)
                }
                Button ("Highlight Line 3") {
                    state.getCurrentEditedItem()?.currentLine = 3
                }
                Button ("+Mult") {
                    state.lineHeightMultiplier += 0.1
                }
                Button ("-Mult") {
                    state.lineHeightMultiplier -= 0.1
                }
                Text ("Drag me to the editor")
                    .draggable(URL (string: "file:///res://demo.org")!)
                Button ("Scroll Html") {
                    htmlItem?.anchor = "anchor-190"
                }
            }
            ZStack {
                Color.yellow
                if visible {
                    Text ("Clear")
                } else {
                    CodeEditorShell(state: state) { urlRequest in
                        print ("Loading \(urlRequest)")
                        return nil
                    } emptyView: {
                        Text ("No Files Open")
                    } codeEditorMenu: {
                        EmptyView()
                    } tabExtension: {
                        EmptyView()
                    }
                    .padding()
                    .onAppear {
                        var text = ""
                        for x in 0..<200 {
                            text += "<a id='anchor-\(x)'/><p>LOCATION \(x)</p>"
                        }
                        htmlItem = state.openHtml (title: "Demo", path: "demo.html", content: "<html><body>\(text)", anchor: "anchor-100")
                        for sampleFile in sampleFiles {
                            _ =  state.openFile(path: sampleFile, delegate: delegate, fileHint: .detect, breakpoints: Set<Int>(breakUtils))
                        }
                    }
                }
            }
        }
#if !canImport(AppKit)
        .confirmationDialog(
            "Context Menu",
            isPresented: Binding(
                get: { delegate.contextMenuRequest != nil },
                set: { isPresented in
                    if !isPresented {
                        delegate.dismissContextMenu()
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            let actions = flattenedActions(from: delegate.contextMenuRequest?.actions ?? [])
            ForEach(actions, id: \.id) { action in
                Button(action.label) {
                    delegate.contextMenuItem?.commands.runAction(id: action.id)
                    delegate.dismissContextMenu()
                }
                .disabled(!action.enabled)
            }
            Button("Cancel", role: .cancel) {
                delegate.dismissContextMenu()
            }
        } message: {
            Text(contextMenuMessage())
        }
#endif
        .confirmationDialog(
            "Command Palette",
            isPresented: Binding(
                get: { delegate.commandPaletteRequest != nil },
                set: { isPresented in
                    if !isPresented {
                        delegate.dismissCommandPalette()
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            let actions = filteredPaletteActions()
            ForEach(actions, id: \.id) { action in
                Button(action.label) {
                    delegate.commandPaletteItem?.commands.runAction(id: action.id)
                    delegate.dismissCommandPalette()
                }
                .disabled(!action.enabled)
            }
            Button("Cancel", role: .cancel) {
                delegate.dismissCommandPalette()
            }
        } message: {
            Text(commandPaletteMessage())
        }
    }

    private func filteredPaletteActions() -> [MonacoActionItem] {
        let actions = delegate.commandPaletteRequest?.actions ?? []
        let enabled = actions.filter { $0.enabled }
        return Array(enabled.prefix(40))
    }

    private func flattenedActions(from items: [MonacoMenuItem]) -> [MonacoActionItem] {
        var results: [MonacoActionItem] = []
        for item in items {
            switch item.kind {
            case .action:
                if let id = item.id {
                    let label = item.label ?? id
                    results.append(MonacoActionItem(id: id, label: label, enabled: item.enabled))
                }
            case .submenu:
                results.append(contentsOf: flattenedActions(from: item.children))
            case .separator:
                continue
            }
        }
        return results
    }

    private func contextMenuMessage() -> String {
        guard let request = delegate.contextMenuRequest else { return "" }
        var parts: [String] = []
        if let location = request.location {
            parts.append("Line \(location.lineNumber + 1), Col \(location.column + 1)")
        }
        if let word = request.word, !word.isEmpty {
            parts.append("Word: \(word)")
        }
        if !request.selectedText.isEmpty {
            let snippet = truncated(request.selectedText, limit: 120)
            parts.append("Selection: \(snippet)")
        }
        if parts.isEmpty {
            return "Monaco requested a native context menu."
        }
        return parts.joined(separator: "\n")
    }

    private func commandPaletteMessage() -> String {
        let count = delegate.commandPaletteRequest?.actions.count ?? 0
        return "Monaco provided \(count) actions."
    }

    private func truncated(_ text: String, limit: Int) -> String {
        if text.count <= limit {
            return text
        }
        let prefix = text.prefix(limit)
        return "\(prefix)…"
    }
}

#Preview {
    ContentView()
}
