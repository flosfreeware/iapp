import ApplicationServices
import CoreGraphics

/// A session event tap runs before the system hotkey handler, so returning nil
/// consumes Command-Space instead of allowing Spotlight to receive it.
final class CommandSpaceInterceptor {
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private let action: () -> Void
    private(set) var isEnabled = false

    init(action: @escaping () -> Void) {
        self.action = action

        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        guard AXIsProcessTrustedWithOptions(options) else { return }

        let mask = CGEventMask(1) << CGEventType.keyDown.rawValue
        tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: Self.handleEvent,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        guard let tap else { return }

        source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        isEnabled = true
    }

    deinit {
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        if let tap { CFMachPortInvalidate(tap) }
    }

    private static let handleEvent: CGEventTapCallBack = { _, type, event, userInfo in
        guard let userInfo else { return Unmanaged.passUnretained(event) }
        let owner = Unmanaged<CommandSpaceInterceptor>.fromOpaque(userInfo).takeUnretainedValue()

        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = owner.tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return Unmanaged.passUnretained(event)
        }

        let isCommandSpace = type == .keyDown
            && event.getIntegerValueField(.keyboardEventKeycode) == 49 // kVK_Space
            && event.flags.contains(.maskCommand)
        guard isCommandSpace else { return Unmanaged.passUnretained(event) }

        DispatchQueue.main.async { owner.action() }
        return nil
    }
}
