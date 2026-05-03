//
//  FlexoraApp.swift
//  Flexora
//
//  Created by yhw on 2026/5/3.
//

import SwiftUI

@main
struct FlexoraApp: App {
    @StateObject private var model = AppModel.bootstrap()

    var body: some Scene {
        WindowGroup {
            MainWindowView(model: model)
        }
        Settings {
            SettingsView(model: model)
        }
    }
}
