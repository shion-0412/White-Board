//
//  ViewController.swift
//  justpaint
//
//  Created by 秋泉 on 2021/02/02.
//

import Cocoa

class InitialViewController: NSViewController, PaletteViewDelegate, InitialViewControllerDelegate {

    @IBOutlet weak var drawView: DrawView!
    @IBOutlet weak var paletteVIew: PaletteView!
    
    override func viewDidLoad() {
        paletteVIew.delegate = self
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.initialViewControllerDelegate = self
        }
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
    
    func undo() {
        drawView.undo()
    }
    
    func redo() {
        drawView.redo()
    }
    
    func saveAsPng() {
        drawView.createImage()
    }
}
