//
//  ViewController.swift
//  justpaint
//
//  Created by 秋泉 on 2021/02/02.
//

import Cocoa

var globalColor: NSColor = NSColor.black
var globalSize: ChoosableSize = .first
var fillsShapes: Bool = true
var shapeBorderWidth: CGFloat = 5
var drawingMode: DrawingMode = .line
var firstLineWidth: CGFloat = 3
var secondLineWidth: CGFloat = 7.5
var thirdLineWidth: CGFloat = 20
var fourthLineWidth: CGFloat = 80
var firstShapeWidth: CGFloat = 100
var secondShapeWidth: CGFloat = 150
var thirdShapeWidth: CGFloat = 200
var fourthShapeWidth: CGFloat = 400
var firstLabelSize: CGFloat = 14
var secondLabelSize: CGFloat = 20
var thirdLabelSize: CGFloat = 30
var fourthLabelSize: CGFloat = 60

class InitialViewController: NSViewController, PaletteViewDelegate, InitialViewControllerDelegate {

    @IBOutlet weak var drawView: DrawView!
    @IBOutlet weak var paletteVIew: PaletteView!
    
    override func viewDidLoad() {
        paletteVIew.delegate = self
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.initialViewControllerDelegate = self
        }
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
