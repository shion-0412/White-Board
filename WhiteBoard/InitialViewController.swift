//
//  ViewController.swift
//  justpaint
//
//  Created by 秋泉 on 2021/02/02.
//

import Cocoa

class InitialViewController: NSViewController, PaletteViewDelegate, InitialViewControllerDelegate, NSWindowDelegate {

    @IBOutlet weak var drawView: DrawView!
    @IBOutlet weak var paletteVIew: PaletteView!
    var initialWindow: NSWindow?
    
    override func viewDidLoad() {
        paletteVIew.delegate = self
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.initialViewControllerDelegate = self
        }
    }
    
    var originalWindowFrame: NSRect = .zero
    
    override func viewWillAppear() {
        initialWindow = self.view.window
        initialWindow?.delegate = self
        originalWindowFrame = initialWindow!.frame
    }
    
    func windowDidResize(_ notification: Notification) {
        let diffY = initialWindow!.frame.height - originalWindowFrame.height
        drawView.windowResize(diffY: diffY)
        originalWindowFrame = initialWindow!.frame
    }
    
    func addImage() {
        drawView.addImage()
    }
    
    func clearCanvas() {
        drawView.clearCanvas()
    }
    
    func createImage() {
        drawView.createImage()
    }
    
    func addLabel(text: String) {
        drawView.addlabel(text: text)
    }
    
    func copyView() {
        drawView.copyView(removeTargetView: false)
    }
    
    func cutView() {
        drawView.copyView(removeTargetView: true)
    }
    
    func pasteView() {
        drawView.pasteView()
    }
    
    func delete() {
        drawView.delete()
    }
    
    func undo() {
        drawView.undo()
    }
    
    func redo() {
        drawView.redo()
    }
    
    func saveAsPng() {
        drawView.createImage()
    }
    
    func changeColor() {
        drawView.changeColor()
    }
    
    func changeLabelSize() {
        drawView.changeLabelSize()
    }
    
    func changeImageSize() {
        drawView.changeImageSize()
    }
    
    func removeSelectedView() {
        drawView.removeSelectedView()
    }
}
