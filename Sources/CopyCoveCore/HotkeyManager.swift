import Carbon.HIToolbox
import Foundation

/// 全局热键（Carbon RegisterEventHotKey，系统自带，无第三方依赖）
public final class HotkeyManager {
    private let keyCode: UInt32
    private let modifiers: UInt32
    private let handler: () -> Void
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?

    public init(keyCode: UInt32 = UInt32(kVK_ANSI_Semicolon), // ⌘;
                modifiers: UInt32 = UInt32(cmdKey),
                handler: @escaping () -> Void) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.handler = handler
    }

    public func start() -> Bool {
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        let callback: EventHandlerUPP = { _, _, userData in
            let manager = Unmanaged<HotkeyManager>.fromOpaque(userData!).takeUnretainedValue()
            manager.handler()
            return noErr
        }
        let installStatus = InstallEventHandler(GetApplicationEventTarget(), callback, 1,
                                               &eventSpec,
                                               Unmanaged.passUnretained(self).toOpaque(),
                                               &eventHandler)
        guard installStatus == noErr else { return false }

        let hotKeyID = EventHotKeyID(signature: OSType(0x4343_4356), id: 1) // 'CCCV'
        var ref: EventHotKeyRef?
        let registerStatus = RegisterEventHotKey(keyCode, modifiers, hotKeyID,
                                                 GetApplicationEventTarget(), 0, &ref)
        hotKeyRef = ref
        return registerStatus == noErr
    }
}
