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
    @State var hostServices = HostServices { path in
        
        do {
            return .success (try String(contentsOf: URL (filePath: path)))
        } catch (let err) {
            if !FileManager.default.fileExists(atPath: path) {
                return .failure(.fileNotFound(path))
            }
            return .failure(.generic(err.localizedDescription))
        }
    } save: { contents, path in
        do {
            try contents.write(toFile: path, atomically: false, encoding: .utf8)
        } catch (let err) {
            return .generic(err.localizedDescription)
        }
        return nil
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(hostServices)
        }
    }
}
