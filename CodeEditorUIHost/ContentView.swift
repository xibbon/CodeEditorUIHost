//
//  ContentView.swift
//  CodeEditorUIHost
//
//  Created by Miguel de Icaza on 3/29/24.
//

import SwiftUI
import CodeEditorUI
import TreeSitter
import Runestone

@MainActor
class MyDelegate: EditedItemDelegate {
    deinit {
        print ("Fuck")
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
    
    func started(editedItem: CodeEditorUI.EditedItem, textView: Runestone.TextView) {
        
    }
    
    /// Implements breakpoint toggling
    func gutterTapped(_ editedItem: EditedItem, _ textView: TextView, _ line: Int) {
        if editedItem.breakpoints.contains(line) {
            editedItem.breakpoints.remove (line)
        } else {
            editedItem.breakpoints.insert (line)
        }
    }

    func editedTextChanged(_ editedItem: CodeEditorUI.EditedItem, _ textView: Runestone.TextView) {
        
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
    }
}

@MainActor
struct ContentView: View {
    @State var state = CodeEditorState (hostServices: HostServices.makeTestHostServices())
    @State var delegate = MyDelegate ()
    @State var breakUtils = [0, 26, 120]
    @State var breakEmpty = [2]
    @State var htmlItem: HtmlItem? = nil
    
    var body: some View {
        VStack {
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
                CodeEditorShell(state: $state) { urlRequest in
                    print ("Loading \(urlRequest)")
                    return nil
                } emptyView: {
                    Text ("No Files Open")
                }
                    .padding()
                    .onAppear {
                        _ = state.openFile(path: "/Users/miguel/cvs/godot-master/modules/gdscript/tests/scripts/utils.notest.gd", delegate: delegate, fileHint: .detect, breakpoints: breakUtils)
                        _ =  state.openFile(path: "/Users/miguel/cvs/godot-master/modules/gdscript//editor/script_templates/Object/empty.gd", delegate: delegate, fileHint: .detect, breakpoints: breakEmpty)
                        var text = ""
                        for x in 0..<200 {
                            text += "<a id='anchor-\(x)'/><p>LOCATION \(x)</p>"
                        }
                        htmlItem = state.openHtml (title: "Demo", path: "demo.html", content: "<html><body>\(text)", anchor: "anchor-100")
                    }
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(HostServices.makeTestHostServices ())
}
