//
//  ContentView.swift
//  CodeEditorUIHost
//
//  Created by Miguel de Icaza on 3/29/24.
//

import SwiftUI
import CodeEditorUI
import TreeSitter

struct ContentView: View {
    @State var state = CodeEditorState (openFiles: [EditedItem(path: "/Users/miguel/cvs/godot-master/modules/gdscript/tests/scripts/utils.notest.gd", data: nil)])
    
    var body: some View {
        CodeEditorShell(state: $state)
            .padding()
    }
}

#Preview {
    ContentView()
}
