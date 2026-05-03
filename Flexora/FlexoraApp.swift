//
//  FlexoraApp.swift
//  Flexora
//
//  Created by yhw on 2026/5/3.
//

import SwiftUI

@main
struct FlexoraApp: App {
    var body: some Scene {
        WindowGroup {
            Text("Choose a Module")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        Settings {
            Text("Settings")
                .padding()
        }
    }
}
