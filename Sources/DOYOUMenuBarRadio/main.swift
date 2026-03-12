import AppKit
import AVFoundation

private let streamURL = URL(string: "https://doyouworld.out.airtime.pro/doyouworld_a")!
private let playerPageURL = URL(string: "https://doyou.world/pages/player")!

final class RadioController: NSObject {
    enum State: Equatable {
        case stopped
        case loading
        case playing
        case failed(String)
    }

    var onStateChange: ((State) -> Void)?

    private(set) var state: State = .stopped {
        didSet {
            onStateChange?(state)
        }
    }

    private var player: AVPlayer?
    private var playerObservation: NSKeyValueObservation?
    private var itemObservation: NSKeyValueObservation?

    var isActive: Bool {
        switch state {
        case .loading, .playing:
            return true
        case .stopped, .failed:
            return false
        }
    }

    func toggle() {
        isActive ? stop() : play()
    }

    func play() {
        guard !isActive else { return }

        let item = AVPlayerItem(url: streamURL)
        let player = AVPlayer(playerItem: item)
        player.automaticallyWaitsToMinimizeStalling = true

        playerObservation = player.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self] player, _ in
            self?.handleTimeControlStatus(player.timeControlStatus)
        }

        itemObservation = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            self?.handleItemStatus(item)
        }

        self.player = player
        state = .loading
        player.play()
    }

    func stop() {
        itemObservation?.invalidate()
        itemObservation = nil

        playerObservation?.invalidate()
        playerObservation = nil

        player?.pause()
        player = nil

        state = .stopped
    }

    private func handleTimeControlStatus(_ timeControlStatus: AVPlayer.TimeControlStatus) {
        switch timeControlStatus {
        case .paused:
            break
        case .waitingToPlayAtSpecifiedRate:
            state = .loading
        case .playing:
            state = .playing
        @unknown default:
            state = .loading
        }
    }

    private func handleItemStatus(_ item: AVPlayerItem) {
        switch item.status {
        case .unknown:
            state = .loading
        case .readyToPlay:
            player?.play()
        case .failed:
            let description = item.error?.localizedDescription ?? "The stream could not be started."
            stop()
            state = .failed(description)
        @unknown default:
            state = .failed("The stream entered an unsupported playback state.")
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let radioController = RadioController()
    private let menu = NSMenu()
    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        menu.autoenablesItems = false
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.target = self
        statusItem.button?.action = #selector(handleStatusItemClick(_:))
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])

        radioController.onStateChange = { [weak self] state in
            self?.refreshInterface(for: state)
        }

        refreshInterface(for: radioController.state)
    }

    func applicationWillTerminate(_ notification: Notification) {
        radioController.stop()
    }

    @objc private func toggleRadio(_ sender: Any?) {
        radioController.toggle()
    }

    @objc private func handleStatusItemClick(_ sender: Any?) {
        guard let event = NSApp.currentEvent else {
            radioController.toggle()
            return
        }

        switch event.type {
        case .rightMouseUp:
            rebuildMenu(for: radioController.state)
            showOptionsMenu()
        case .leftMouseUp:
            radioController.toggle()
        default:
            break
        }
    }

    @objc private func openPlayerPage(_ sender: Any?) {
        NSWorkspace.shared.open(playerPageURL)
    }

    @objc private func quitApp(_ sender: Any?) {
        NSApp.terminate(nil)
    }

    private func refreshInterface(for state: RadioController.State) {
        guard let button = statusItem.button else { return }

        button.image = statusImage(for: state)
        button.title = button.image == nil ? "DO" : ""
        button.imagePosition = .imageOnly
        button.toolTip = tooltipText(for: state)

        rebuildMenu(for: state)
    }

    private func showOptionsMenu() {
        guard let button = statusItem.button else { return }

        let menuOrigin = NSPoint(x: 0, y: button.bounds.maxY + 4)
        button.highlight(true)
        menu.popUp(positioning: nil, at: menuOrigin, in: button)
        button.highlight(false)
    }

    private func rebuildMenu(for state: RadioController.State) {
        menu.removeAllItems()

        let titleItem = NSMenuItem(title: "DO!!YOU!!! RADIO", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        let statusText = switch state {
        case .stopped:
            "Stopped"
        case .loading:
            "Connecting..."
        case .playing:
            "Playing live stream"
        case .failed(let message):
            "Error: \(message)"
        }

        let statusTextItem = NSMenuItem(title: statusText, action: nil, keyEquivalent: "")
        statusTextItem.isEnabled = false
        menu.addItem(statusTextItem)
        menu.addItem(.separator())

        let toggleTitle = radioController.isActive ? "Stop Radio" : "Start Radio"
        let toggleItem = NSMenuItem(title: toggleTitle, action: #selector(toggleRadio(_:)), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)

        let pageItem = NSMenuItem(title: "Open Player Page", action: #selector(openPlayerPage(_:)), keyEquivalent: "")
        pageItem.target = self
        menu.addItem(pageItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp(_:)), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    private func tooltipText(for state: RadioController.State) -> String {
        switch state {
        case .stopped:
            return "DO!!YOU!!! Radio is stopped"
        case .loading:
            return "DO!!YOU!!! Radio is connecting"
        case .playing:
            return "DO!!YOU!!! Radio is playing"
        case .failed(let message):
            return "DO!!YOU!!! Radio error: \(message)"
        }
    }

    private func statusImage(for state: RadioController.State) -> NSImage? {
        let symbolName = switch state {
        case .stopped:
            "play.fill"
        case .loading:
            "arrow.clockwise"
        case .playing:
            "dot.radiowaves.left.and.right"
        case .failed:
            "exclamationmark.triangle.fill"
        }

        let configuration = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)?
            .withSymbolConfiguration(configuration)

        image?.isTemplate = true
        return image
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
