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
    @State var state = CodeEditorState (hostServices: HostServices.makeTestHostServices())
    
    var body: some View {
        CodeEditorShell(state: $state)
            .padding()
            .onAppear {
                state.openFile(path: "/Users/miguel/cvs/godot-master/modules/gdscript/tests/scripts/utils.notest.gd", data: nil)
            }
    }
}

#Preview {
    ContentView()
}
