//
//  AppDelegate.swift
//  justpaint
//
//  Created by 秋泉 on 2021/02/02.
//

import Cocoa
import Carbon

var markerCursor: NSCursor = .pointingHand
var globalColor: NSColor = NSColor.black
var globalBrushSize: CGFloat = 7.5
var globalLabelSize: CGFloat = 18
var globalImageSize: CGFloat = 200
var globalLineWidth: CGFloat = 7.5
var shiftKeyIsPressed = false
var fillsShapes: Bool = true
var shapeBorderWidth: CGFloat = 5
var drawingMode: DrawingMode = .marker
var firstShapeWidth: CGFloat = 100
var secondShapeWidth: CGFloat = 150
var thirdShapeWidth: CGFloat = 200
var fourthShapeWidth: CGFloat = 400
var firstLabelSize: CGFloat = 14
var secondLabelSize: CGFloat = 20
var thirdLabelSize: CGFloat = 30
var fourthLabelSize: CGFloat = 60

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    weak var initialViewControllerDelegate: InitialViewControllerDelegate?
    var shiftKeyMonitor: Any?
    
    @IBAction func copy(_ sender: Any) {
        initialViewControllerDelegate?.copyView()
    }
    
    @IBAction func cut(_ sender: Any) {
        initialViewControllerDelegate?.cutView()
    }
    
    @IBAction func paste(_ sender: Any) {
        initialViewControllerDelegate?.pasteView()
    }
    
    @IBAction func undo(_ sender: Any) {
        initialViewControllerDelegate?.undo()
    }
    
    @IBAction func delete(_ sender: Any) {
        initialViewControllerDelegate?.delete()
    }
    
    @IBAction func redo(_ sender: Any) {
        initialViewControllerDelegate?.redo()
    }
    
    @IBAction func saveAsPng(_ sender: Any) {
        initialViewControllerDelegate?.saveAsPng()
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        shiftKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged, handler: { (event) -> NSEvent? in
            if event.keyCode == 56 {
                shiftKeyIsPressed.toggle()
            }
            return event
        })
        if let image = NSImage(named: "black") {
            markerCursor = NSCursor(image: image, hotSpot: NSPoint(x: 7, y: 42))
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        NSEvent.removeMonitor(shiftKeyMonitor)
        shiftKeyMonitor = nil
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func hotKeyPressed() {
//        print("pressed ")
    }
    
    
}

protocol InitialViewControllerDelegate: class {
    func undo()
    func redo()
    func delete()
    func copyView()
    func cutView()
    func pasteView()
    func saveAsPng()
}
