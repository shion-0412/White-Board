//
//  TestViewController.swift
//  WhiteBoard
//
//  Created by 志音 on 2021/03/06.
//

import Cocoa

class TestViewController: NSViewController {

    
    @IBOutlet weak var asdfView: NSView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(asdfView.bounds)
//        asdfView.wantsLayer = true
//        asdfView.borderWidth = 1
//        asdfView.borderColor = .black
    }
    
    
    @IBAction func clickButton(_ sender: Any) {
//        asdfView.layer?.transform = CATransform3DMakeRotation(angle, 0, 0, 1)
//        angle += CGFloat.pi / 6
    }
    
}

class ClickView: NSView {
    
    private var trackingArea: NSTrackingArea?
    
    override func draw(_ dirtyRect: NSRect) {
        NSColor.red.set()
        let path = NSBezierPath()
        path.move(to: .zero)
        path.line(to: NSPoint(x: frame.width, y: frame.height))
        path.lineWidth = 10
        path.stroke()
        self.needsDisplay = true
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if self.trackingArea != nil {
            self.removeTrackingArea(self.trackingArea!)
            self.trackingArea = nil
        }
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways]
        let rect = NSRect(origin: .zero, size: self.frame.size)
        self.trackingArea = NSTrackingArea(rect: rect, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(self.trackingArea!)
    }
    
    override func mouseEntered(with event: NSEvent) {
        print("entered---------------")
    }
    
    override func mouseDown(with event: NSEvent) {
        print("clicked----------------------")
    }
    
}
