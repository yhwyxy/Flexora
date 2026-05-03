//
//  FlexoraApp.swift
//  Flexora
//
//  Created by yhw on 2026/5/3.
//

import SwiftUI

@main
struct FlexoraApp: App {
    @StateObject private var model = makeModel()

    var body: some Scene {
        WindowGroup {
            MainWindowView(model: model)
        }
        Settings {
            SettingsView(model: model)
        }
    }

    private static func makeModel() -> AppModel {
        let runtime = ModuleRuntime()
        let workflowStore = WorkflowStore()
        let videoModule = VideoFrameExtractionModule()

        runtime.register(module: videoModule)
        runtime.setModuleEnabled(videoModule.descriptor.id, isEnabled: true)

        return AppModel(runtime: runtime, workflowStore: workflowStore, route: .home)
    }
}
