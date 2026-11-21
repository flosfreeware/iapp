import ApplicationServices
import Carbon.HIToolbox
import CoreGraphics

/// Opens the launcher for a Command press/release that was not used as a
/// modifier. It observes events only; all normal keyboard input passes through.
final class CommandPressInterceptor {
    private let action: () -> Void
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private var commandIsDown = false
    private var commandWasUsed = false

    init(action: @escaping () -> Void) {
        self.action = action
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        guard AXIsProcessTrustedWithOptions(options) else { return }

        let mask = (CGEventMask(1) << CGEventType.flagsChanged.rawValue)
            | (CGEventMask(1) << CGEventType.keyDown.rawValue)
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
    }

    deinit {
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        if let tap { CFMachPortInvalidate(tap) }
    }

    private static let handleEvent: CGEventTapCallBack = { _, type, event, userInfo in
        guard let userInfo else { return Unmanaged.passUnretained(event) }
        let owner = Unmanaged<CommandPressInterceptor>.fromOpaque(userInfo).takeUnretainedValue()
        owner.process(type: type, event: event)
        return Unmanaged.passUnretained(event)
    }

    private func process(type: CGEventType, event: CGEvent) {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return
        }

        if type == .keyDown, commandIsDown {
            commandWasUsed = true
            return
        }
        guard type == .flagsChanged else { return }

        let key = event.getIntegerValueField(.keyboardEventKeycode)
        guard key == Int64(kVK_Command) || key == Int64(kVK_RightCommand) else { return }
        if event.flags.contains(.maskCommand) {
            commandIsDown = true
            commandWasUsed = false
        } else if commandIsDown {
            commandIsDown = false
            if !commandWasUsed { DispatchQueue.main.async { self.action() } }
        }
    }
}
