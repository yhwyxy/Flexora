//
//  ContentView.swift
//  Flexora
//
//  Created by yhw on 2026/5/3.
//

import SwiftUI

struct ContentView: View {
    static let placeholderTitle = "Choose a Module"

    var body: some View {
        Text(Self.placeholderTitle)
            .accessibilityIdentifier("module-chooser-placeholder")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
