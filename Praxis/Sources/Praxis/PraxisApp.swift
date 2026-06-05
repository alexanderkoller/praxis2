import AppKit
import SwiftUI

@main
struct PraxisApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1240, height: 820)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("Über Praxis") {
                    NSApplication.shared.orderFrontStandardAboutPanel(options: [
                        .applicationName: "Praxis",
                        .applicationVersion: "Mock",
                        .credits: NSAttributedString(
                            string: "Lokaler Mock für Praxisverwaltung und Patientenworkflows.",
                            attributes: [.font: NSFont.systemFont(ofSize: 12)]
                        )
                    ])
                }
            }

            CommandGroup(replacing: .appSettings) {
                Button("Einstellungen...") {
                    store.sidebarSelection = .einstellungen
                }
                .keyboardShortcut(",", modifiers: .command)
            }

            CommandGroup(replacing: .appTermination) {
                Button("Praxis beenden") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
            }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.mainMenu?.items.first?.title = "Praxis"
        DispatchQueue.main.async {
            NSApplication.shared.activate(ignoringOtherApps: true)
            NSApplication.shared.windows.forEach { window in
                window.makeKeyAndOrderFront(nil)
            }
        }
        // "Login" equivalent: DB key was successfully retrieved from Keychain, user is authenticated
        AuditLog.appendSystemEvent(
            eventType: "app.launched",
            meta: ["appVersion": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"]
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        AuditLog.appendSystemEvent(eventType: "app.terminated")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
