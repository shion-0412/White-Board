//
//  HotKey.swift
//  white-board
//
//  Created by 志音 on 2021/02/27.
//

import Cocoa
import Carbon

class HotKey {
    
    static var hotKeyRef: EventHotKeyRef?
    
    static func getCarbonFlagsFromCocoaFlags(cocoaFlags: NSEvent.ModifierFlags) -> UInt32 {
        let flags = cocoaFlags.rawValue
        var newFlags: Int = 0
        if ((flags & NSEvent.ModifierFlags.control.rawValue) > 0) {
            newFlags |= controlKey
        }
        if ((flags & NSEvent.ModifierFlags.command.rawValue) > 0) {
            newFlags |= cmdKey
        }
        if ((flags & NSEvent.ModifierFlags.shift.rawValue) > 0) {
            newFlags |= shiftKey
        }
        if ((flags & NSEvent.ModifierFlags.option.rawValue) > 0) {
            newFlags |= optionKey
        }
        if ((flags & NSEvent.ModifierFlags.capsLock.rawValue) > 0) {
            newFlags |= alphaLock
        }
        return UInt32(newFlags)
    }
    
    static func startHandler() {
        let modifierFlags: UInt32 = getCarbonFlagsFromCocoaFlags(cocoaFlags: NSEvent.ModifierFlags.command)
        let keyCode = kVK_ANSI_1
        var gMyHotKeyID = EventHotKeyID()
        gMyHotKeyID.id = UInt32(keyCode)

        // Not sure what "swat" vs "htk1" do.
        gMyHotKeyID.signature = OSType("swat".fourCharCodeValue)
        
        // gMyHotKeyID.signature = OSType("htk1".fourCharCodeValue)
        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = OSType(kEventHotKeyPressed)
        
        // Install handler.
        InstallEventHandler(GetApplicationEventTarget(), {
          (nextHanlder, theEvent, userData) -> OSStatus in
            let appDelegate = NSApp.delegate as? AppDelegate
            appDelegate?.hotKeyPressed()
            return noErr
        }, 1, &eventType, nil, nil)
        
        // Register hotkey.
        let status = RegisterEventHotKey(UInt32(keyCode),
                                         modifierFlags,
                                         gMyHotKeyID,
                                         GetApplicationEventTarget(),
                                         0,
                                         &hotKeyRef)
        
        assert(status == noErr)
    }
    
    static func finishHandler() {
        let status = UnregisterEventHotKey(hotKeyRef)
        assert(status == noErr)
    }
}

extension String {
  // This converts string to UInt as a fourCharCode
  public var fourCharCodeValue: Int {
    var result: Int = 0
    if let data = self.data(using: String.Encoding.macOSRoman) {
      data.withUnsafeBytes({ (rawBytes) in
        let bytes = rawBytes.bindMemory(to: UInt8.self)
        for i in 0 ..< data.count {
          result = result << 8 + Int(bytes[i])
        }
      })
    }
    return result
  }
}
