import SwiftUI

#if os(macOS)
// MARK: - macOS Keyboard Handler
struct KeyboardHandler: NSViewControllerRepresentable {
    let handleUp: () -> Void
    let handleDown: () -> Void
    let handleLeft: () -> Void
    let handleRight: () -> Void
    let handlePlayPause: () -> Void

    func makeNSViewController(context: Context) -> NSKeyCommandController {
        return NSKeyCommandController(
            handleUp: handleUp,
            handleDown: handleDown,
            handleLeft: handleLeft,
            handleRight: handleRight,
            handlePlayPause: handlePlayPause
        )
    }

    func updateNSViewController(_ nsViewController: NSKeyCommandController, context: Context) {}
}

class NSKeyCommandController: NSViewController {
    let handleUpKey: () -> Void
    let handleDownKey: () -> Void
    let handleLeftKey: () -> Void
    let handleRightKey: () -> Void
    let handlePlayPauseKey: () -> Void

    init(
        handleUp: @escaping () -> Void,
        handleDown: @escaping () -> Void,
        handleLeft: @escaping () -> Void,
        handleRight: @escaping () -> Void,
        handlePlayPause: @escaping () -> Void
    ) {
        self.handleUpKey = handleUp
        self.handleDownKey = handleDown
        self.handleLeftKey = handleLeft
        self.handleRightKey = handleRight
        self.handlePlayPauseKey = handlePlayPause
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.makeFirstResponder(self) // Set as first responder
    }

    override var acceptsFirstResponder: Bool {
        return true // Allow this view to receive keyboard events
    }

    override func keyDown(with event: NSEvent) {
        print("Key down detected: \(event.keyCode)") // Debugging print

        switch event.keyCode {
        case 126: // Up Arrow
            handleUpKey()
        case 125: // Down Arrow
            handleDownKey()
        case 123: // Left Arrow
            handleLeftKey()
        case 124: // Right Arrow
            handleRightKey()
        case 36, 49: // Enter or Spacebar
            handlePlayPauseKey()
        default:
            super.keyDown(with: event)
        }
    }
}

#else
// MARK: - iOS Keyboard Handler
struct KeyboardHandler: UIViewControllerRepresentable {
    let handleUp: () -> Void
    let handleDown: () -> Void
    let handleLeft: () -> Void
    let handleRight: () -> Void
    let handlePlayPause: () -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        return KeyCommandController(
            handleUp: handleUp,
            handleDown: handleDown,
            handleLeft: handleLeft,
            handleRight: handleRight,
            handlePlayPause: handlePlayPause
        )
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

class KeyCommandController: UIViewController {
    let handleUpKey: () -> Void
    let handleDownKey: () -> Void
    let handleLeftKey: () -> Void
    let handleRightKey: () -> Void
    let handlePlayPauseKey: () -> Void

    var keyPressTimer: Timer?
    var currentKey: String?

    init(
        handleUp: @escaping () -> Void,
        handleDown: @escaping () -> Void,
        handleLeft: @escaping () -> Void,
        handleRight: @escaping () -> Void,
        handlePlayPause: @escaping () -> Void
    ) {
        self.handleUpKey = handleUp
        self.handleDownKey = handleDown
        self.handleLeftKey = handleLeft
        self.handleRightKey = handleRight
        self.handlePlayPauseKey = handlePlayPause
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var keyCommands: [UIKeyCommand]? {
        return [
            UIKeyCommand(input: "\r", modifierFlags: [], action: #selector(handlePlayPausePress)),
            UIKeyCommand(input: " ", modifierFlags: [], action: #selector(handlePlayPausePress))
        ]
    }

    @objc private func handlePlayPausePress() {
        print("🚀 Spacebar/Enter key pressed!")
        handlePlayPauseKey()
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesBegan(presses, with: event)

        if let key = presses.first?.key?.characters {
            if currentKey == key {
                return // Prevent multiple timers for the same key
            }

            currentKey = key
            startKeyPressTimer(for: key)
        }
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesEnded(presses, with: event)

        if let key = presses.first?.key?.characters, key == currentKey {
            stopKeyPressTimer()
        }
    }

    private func startKeyPressTimer(for key: String) {
        keyPressTimer?.invalidate() // Ensure no duplicate timers

        keyPressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.handleKeyPress(key)
        }
    }

    private func stopKeyPressTimer() {
        keyPressTimer?.invalidate()
        keyPressTimer = nil
        currentKey = nil
    }

    private func handleKeyPress(_ key: String) {
        switch key {
        case UIKeyCommand.inputUpArrow:
            print("⬆️ Holding Up Arrow")
            handleUpKey()
        case UIKeyCommand.inputDownArrow:
            print("⬇️ Holding Down Arrow")
            handleDownKey()
        case UIKeyCommand.inputLeftArrow:
            print("⬅️ Holding Left Arrow")
            handleLeftKey()
        case UIKeyCommand.inputRightArrow:
            print("➡️ Holding Right Arrow")
            handleRightKey()
        default:
            break
        }
    }
}
#endif

