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
    @State var files: [EditedItem] = [EditedItem(path: "/Users/miguel/cvs/godot-master/modules/gdscript/tests/scripts/utils.notest.gd", data: nil)]
    var body: some View {
        CodeEditorShell(openFiles: $files)
            .padding()
    }
}

#Preview {
    ContentView()
}
