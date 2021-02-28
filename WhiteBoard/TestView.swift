//
//  TestView.swift
//  WhiteBoard
//
//  Created by 志音 on 2021/02/28.
//

import Cocoa

class TestView: NSView {
    
    private var trackingArea: NSTrackingArea?
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if self.trackingArea != nil {
            self.removeTrackingArea(self.trackingArea!)
            self.trackingArea = nil
        }
        let options: NSTrackingArea.Options = [.mouseMoved, .mouseEnteredAndExited, .activeAlways]
        let rect = NSRect(origin: .zero, size: self.frame.size)
        self.trackingArea = NSTrackingArea(rect: rect, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(self.trackingArea!)
    }
    
    override func mouseEntered(with event: NSEvent) {
        let image = NSImage(named: "bigpen")
        let cursor = NSCursor(image: image!, hotSpot: .zero)
        addCursorRect(self.bounds, cursor: cursor)
    }
    
    override func mouseExited(with event: NSEvent) {
        NSCursor.arrow.set()
    }
    
}
