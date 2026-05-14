//
//  AppDelegate.swift
//  Applite
//
//  Created by Milán Várady on 2025.01.01.
//

import Foundation
import AppKit

class ApplicationDelegate: NSObject, NSApplicationDelegate {
    // Only keep the app alive after window close if the menu bar icon is enabled
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        let keepRunning = UserDefaults.standard.bool(forKey: Preferences.keepRunningInMenuBar.rawValue)
        return !keepRunning
    }
}
