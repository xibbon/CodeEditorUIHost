//
//  CodeEditorUIHostApp.swift
//  CodeEditorUIHost
//
//  Created by Miguel de Icaza on 3/29/24.
//

import SwiftUI
import CodeEditorUI
import Foundation

@main
struct CodeEditorUIHostApp: App {
    @State var hostServices = HostServices.makeTestHostServices ()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(hostServices)
        }
    }
}
