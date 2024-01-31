//
//  EasyChaptersApp.swift
//  easy-chapters
//
//  Created by Nicolas Bonamy on 1/28/24.
//

import SwiftUI

@main
struct EasyChaptersApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView().navigationTitle("Easy Chapters")
    }
    .commands {
      CommandGroup(replacing: .newItem) {
        Button("Open Video...") {
          
        }.keyboardShortcut("o", modifiers: [.command])
      }
    }
  }
}
