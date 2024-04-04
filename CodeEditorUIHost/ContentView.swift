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
    
    
    func onChange (_ state: CodeEditorState, textView: TextView) {
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
        if line.hasSuffix("pri") {
            
        }
    }
    
    var body: some View {
        CodeEditorShell(state: $state)
            .padding()
            .onAppear {
                _ = state.openFile(path: "/Users/miguel/cvs/godot-master/modules/gdscript/tests/scripts/utils.notest.gd", data: nil)
                state.onChange = onChange
            }
    }
}

#Preview {
    ContentView()
}
