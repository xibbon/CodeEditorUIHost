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

struct ContentView: View {
    @State var state = CodeEditorState (hostServices: HostServices.makeTestHostServices())
    
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
    
    func onChange (_ state: CodeEditorState, _ editedItem: EditedItem, textView: TextView) {
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
        let region = textView.firstRect(for: r)

        if line.hasSuffix("pri") {
            editedItem.requestCompletion (at: region, prefix: "pri", completions: ContentView.makeTestData())
        }
    }
    
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
            }
            CodeEditorShell(state: $state)
                .padding()
                .onAppear {
                    _ = state.openFile(path: "/Users/miguel/cvs/godot-master/modules/gdscript/tests/scripts/utils.notest.gd", data: nil)
                    state.onChange = onChange
                }
        }
    }
}

#Preview {
    ContentView()
}
