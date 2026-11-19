import AppKit
import SwiftUI
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, NSMenuDelegate {
    let settings = AppSettings()
    let store = StatsStore()
    lazy var model = TimerModel(settings: settings, store: store)

    private var window: NSWindow!
    private var statusItem: NSStatusItem?
    private var toggleItem: NSMenuItem?
    private var lastStatusTitle = ""
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMainMenu()
        buildWindow()
        watchClicksToUnpin()

        model.onPhaseFinished = { [weak self] finished in self?.phaseFinished(finished) }

        settings.$showMenuBarTimer
            .removeDuplicates()
            .sink { [weak self] show in self?.setStatusItem(visible: show) }
            .store(in: &cancellables)

        settings.$hideDockIcon
            .removeDuplicates()
            .sink { [weak self] hide in self?.setDockIcon(hidden: hide) }
            .store(in: &cancellables)

        model.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.updateStatusTitle() }
            .store(in: &cancellables)

        showWindow()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showWindow()
        return true
    }

    // MARK: Window

    private func buildWindow() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Tomater"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.backgroundColor = Pal.window
        window.contentView = NSHostingView(rootView: RootView(model: model, settings: settings))
        window.delegate = self
        window.center()
        window.setFrameAutosaveName("TomaterMainWindow")
        watchDayAndNight()
    }

    // MARK: Day and night

    /// Light look from 6:00 AM to 5:59 PM, dark look from 6:00 PM to 5:59 AM.
    private func watchDayAndNight() {
        applyDayOrNight()
        let timer = Timer(timeInterval: 30, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.applyDayOrNight() }
        }
        RunLoop.main.add(timer, forMode: .common)
    }

    private func applyDayOrNight() {
        let hour = Calendar.current.component(.hour, from: Date())
        let name: NSAppearance.Name = (6..<18).contains(hour) ? .aqua : .darkAqua
        if window.appearance?.name != name { window.appearance = NSAppearance(named: name) }
    }

    @objc func showWindow() {
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    /// Puts the window on top of all other windows until the user clicks in it.
    private func bringToFront() {
        model.screen = .timer
        window.level = .floating
        window.collectionBehavior.insert(.moveToActiveSpace)
        if window.isMiniaturized { window.deminiaturize(nil) }
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }

    /// The popped-up window stays on top until the user clicks in it.
    private func watchClicksToUnpin() {
        NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let self, event.window === self.window, self.window.level != .normal {
                self.window.level = .normal
                self.window.collectionBehavior.remove(.moveToActiveSpace)
            }
            return event
        }
    }

    private func phaseFinished(_ finished: Phase) {
        Chiptune.play(finished == .work ? Chiptune.stageClear : Chiptune.ready)
        if settings.interruptMe { bringToFront() }
    }

    // MARK: Dock icon

    private func setDockIcon(hidden: Bool) {
        let wasVisible = window?.isVisible ?? false
        NSApp.setActivationPolicy(hidden ? .accessory : .regular)
        if wasVisible {
            DispatchQueue.main.async { self.showWindow() }
        }
    }

    // MARK: Menu bar timer

    private func setStatusItem(visible: Bool) {
        if visible, statusItem == nil {
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            item.menu = buildStatusMenu()
            statusItem = item
            lastStatusTitle = ""
            updateStatusTitle()
        } else if !visible, let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
    }

    private func updateStatusTitle() {
        guard let button = statusItem?.button else { return }
        let title = model.timeString
        let key = "\(model.phase) \(title)"
        guard key != lastStatusTitle else { return }
        lastStatusTitle = key
        button.image = MenuBarIcon.image(for: model.phase)
        button.imagePosition = .imageLeading
        button.attributedTitle = NSAttributedString(
            string: " " + title,
            attributes: [.font: NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .medium)]
        )
    }

    private func buildStatusMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self
        let toggle = NSMenuItem(title: "Start", action: #selector(toggleTimer), keyEquivalent: "")
        toggle.target = self
        toggleItem = toggle
        menu.addItem(toggle)
        menu.addItem(item("Stop", #selector(stopTimer)))
        menu.addItem(.separator())
        menu.addItem(item("Open Tomater", #selector(showWindow)))
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit Tomater", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)
        return menu
    }

    private func item(_ title: String, _ action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        toggleItem?.title = model.isRunning ? "Pause" : "Start \(model.phase.title.lowercased())"
    }

    @objc private func toggleTimer() { model.toggle() }
    @objc private func stopTimer() { model.stop() }

    // MARK: Main menu

    private func buildMainMenu() {
        let main = NSMenu()

        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About Tomater", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Hide Tomater", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit Tomater", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        addSubmenu(appMenu, to: main)

        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        addSubmenu(editMenu, to: main)

        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        addSubmenu(windowMenu, to: main)

        NSApp.mainMenu = main
    }

    private func addSubmenu(_ submenu: NSMenu, to main: NSMenu) {
        let item = NSMenuItem()
        item.submenu = submenu
        main.addItem(item)
    }
}
