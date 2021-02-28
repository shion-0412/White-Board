//
//  PaletteView.swift
//  justpaint
//
//  Created by 秋泉 on 2021/02/07.
//

import Cocoa

class PaletteView: NSView, ChoosableShapeDelegate, ChoosableSizeDelegate, ChoosableColorDelegate, NSTextFieldDelegate {

    @IBOutlet var topView: NSView!
    @IBOutlet weak var firstSizeView: ChoosableSizeView!
    @IBOutlet weak var secondSizeView: ChoosableSizeView!
    @IBOutlet weak var thirdSizeView: ChoosableSizeView!
    @IBOutlet weak var fourthSizeView: ChoosableSizeView!
    @IBOutlet weak var squareShapeView: ChoosableShapeView!
    @IBOutlet weak var circleShapeView: ChoosableShapeView!
    @IBOutlet weak var arrowShapeView: ChoosableShapeView!
    @IBOutlet weak var lineShapeView: ChoosableShapeView!
    @IBOutlet weak var firstColorView: ChoosableColorView!
    @IBOutlet weak var secondColorView: ChoosableColorView!
    @IBOutlet weak var thirdColorView: ChoosableColorView!
    @IBOutlet weak var fourthColorView: ChoosableColorView!
    @IBOutlet weak var labelTextField: NSTextField!
    
    weak var delegate: PaletteViewDelegate?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        setup()
    }

    private func setup() {
        let myName = type(of: self).className().components(separatedBy: ".").last!
        if let nib = NSNib(nibNamed: myName, bundle: Bundle(for: type(of: self))) {
            nib.instantiate(withOwner: self, topLevelObjects: nil)
            var newConstraints: [NSLayoutConstraint] = []
            for oldConstraint in topView.constraints {
                let firstItem = oldConstraint.firstItem === topView ? self : oldConstraint.firstItem!
                let secondItem = oldConstraint.secondItem === topView ? self : oldConstraint.secondItem
                newConstraints.append(NSLayoutConstraint(item: firstItem, attribute: oldConstraint.firstAttribute, relatedBy: oldConstraint.relation, toItem: secondItem, attribute: oldConstraint.secondAttribute, multiplier: oldConstraint.multiplier, constant: oldConstraint.constant))
            }
            for newView in topView.subviews {
                self.addSubview(newView)
            }
            self.addConstraints(newConstraints)
        } else {
            Swift.print("init couldn't load nib")
        }
        firstSizeView.ChoosableSize = .first
        firstSizeView.delegate = self
        secondSizeView.ChoosableSize = .second
        secondSizeView.delegate = self
        thirdSizeView.ChoosableSize = .third
        thirdSizeView.delegate = self
        fourthSizeView.ChoosableSize = .fourth
        fourthSizeView.delegate = self
        squareShapeView.shapeType = .square
        squareShapeView.delegate = self
        circleShapeView.shapeType = .circle
        circleShapeView.delegate = self
        arrowShapeView.shapeType = .arrow
        arrowShapeView.delegate = self
        lineShapeView.shapeType = .line
        lineShapeView.delegate = self
        firstColorView.delegate = self
        firstColorView.order = .first
        secondColorView.delegate = self
        secondColorView.order = .second
        thirdColorView.delegate = self
        thirdColorView.order = .third
        fourthColorView.delegate = self
        fourthColorView.order = .fourth
        labelTextField.delegate = self
    }
    
    override func draw(_ dirtyRect: NSRect) {
        self.layer?.masksToBounds = true
        let backgroundColor = NSColor.gray
        backgroundColor.setFill()
        __NSRectFill(dirtyRect)
        super.draw(dirtyRect)
    }
 
    @IBAction func switchFill(_ sender: NSButton) {
        if sender.state == .on {
            fillsShapes = true
        } else {
            fillsShapes = false
        }
    }
    
    @IBAction func AddImage(_ sender: Any) {
        delegate?.addImage()
    }
    
    @IBAction func clearCanvas(_ sender: Any) {
        delegate?.clearCanvas()
    }
    
    @IBAction func createImage(_ sender: Any) {
        delegate?.createImage()
    }
    
    func changeDrawingMode(type: DrawingMode) {
        drawingMode = .marker
        [squareShapeView, circleShapeView, arrowShapeView, lineShapeView].forEach {
            if $0!.shapeType == type && $0!.borderWidth == 0 {
                $0!.borderWidth = 1
                drawingMode = type
            } else {
                $0!.borderWidth = 0
            }
        }
    }
    
    func changeColor(order: ChoosableColorOrder) {
        firstColorView.borderColor = .black
        secondColorView.borderColor = .black
        thirdColorView.borderColor = .black
        fourthColorView.borderColor = .black
        switch order {
        case .first:
            firstColorView.borderColor = .green
            if let image = NSImage(named: "white") {
                markerCursor = NSCursor(image: image, hotSpot: NSPoint(x: 7, y: 42))
            }
        case .second:
            secondColorView.borderColor = .green
            if let image = NSImage(named: "black") {
                markerCursor = NSCursor(image: image, hotSpot: NSPoint(x: 7, y: 42))
            }
        case .third:
            thirdColorView.borderColor = .green
            if let image = NSImage(named: "red") {
                markerCursor = NSCursor(image: image, hotSpot: NSPoint(x: 7, y: 42))
            }
        case .fourth:
            fourthColorView.borderColor = .green
            if let image = NSImage(named: "blue") {
                markerCursor = NSCursor(image: image, hotSpot: NSPoint(x: 7, y: 42))
            }
        }
    }
    
    func changeWidth(type: ChoosableSize) {
        firstSizeView.borderWidth = 0
        secondSizeView.borderWidth = 0
        thirdSizeView.borderWidth = 0
        fourthSizeView.borderWidth = 0
        switch type {
        case .first:
            firstSizeView.borderWidth = 1
        case .second:
            secondSizeView.borderWidth = 1
        case .third:
            thirdSizeView.borderWidth = 1
        case .fourth:
            fourthSizeView.borderWidth = 1
        }
    }
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            self.window?.makeFirstResponder(nil)
            if self.labelTextField.stringValue != "" {
                delegate?.addLabel(text: self.labelTextField.stringValue)
                self.labelTextField.stringValue = ""
            }
            return true
        }
        return false
    }
    
}

protocol PaletteViewDelegate: class {
    func addImage()
    func clearCanvas()
    func createImage()
    func addLabel(text: String)
}

class ChoosableColorView: NSView {
     
    var order: ChoosableColorOrder = .first
    var delegate: ChoosableColorDelegate?
    
    override func mouseDown(with event: NSEvent) {
        globalColor = (self.backgroundColor != nil) ? self.backgroundColor! : NSColor.black
        delegate?.changeColor(order: order)
    }
    
}

protocol ChoosableColorDelegate: class {
    func changeColor(order: ChoosableColorOrder)
}

enum ChoosableColorOrder {
    case first
    case second
    case third
    case fourth
}

class ChoosableSizeView: NSView {
    
    var ChoosableSize: ChoosableSize = .first
    weak var delegate: ChoosableSizeDelegate?
    
    override func mouseDown(with event: NSEvent) {
        globalSize = ChoosableSize
        self.borderWidth = 1
        delegate?.changeWidth(type: ChoosableSize)
    }
}

protocol ChoosableSizeDelegate: class {
    func changeWidth(type: ChoosableSize)
}

enum ChoosableSize {
    case first
    case second
    case third
    case fourth
}

class ChoosableShapeView: NSView {
    
    var shapeType: DrawingMode = .square
    weak var delegate: ChoosableShapeDelegate?
    
    override func draw(_ dirtyRect: NSRect) {
        NSColor.green.set()
        let path = NSBezierPath()
        let width = self.frame.width
        switch shapeType {
        case .arrow:
            let lineWidth: CGFloat = 6
            let range = width - lineWidth / 2
            path.move(to: NSPoint(x: lineWidth / 2, y: lineWidth / 2))
            path.line(to: NSPoint(x: range, y: range))
            path.line(to: NSPoint(x: range / 2, y: range))
            path.move(to: NSPoint(x: range, y: range))
            path.line(to: NSPoint(x: range, y: range / 2))
            path.lineWidth = lineWidth
            path.stroke()
        case .circle:
            let rect = NSRect(x: 0, y: 0, width: width, height: width)
            path.appendOval(in: rect)
            path.fill()
        case .square:
            path.move(to: NSPoint(x: 0, y: 0))
            path.line(to: NSPoint(x: width, y: 0))
            path.line(to: NSPoint(x: width, y: width))
            path.line(to: NSPoint(x: 0, y: width))
            path.line(to: NSPoint(x: 0, y: 0))
            path.fill()
        case .line:
            let lineWidth: CGFloat = 6
            let range = width - lineWidth / 2
            path.move(to: NSPoint(x: lineWidth / 2, y: lineWidth / 2))
            path.line(to: NSPoint(x: range, y: range))
            path.lineWidth = lineWidth
            path.stroke()
        case .marker:
            break
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        delegate?.changeDrawingMode(type: shapeType)
    }
    
}

protocol ChoosableShapeDelegate: class {
    func changeDrawingMode(type: DrawingMode)
}

enum DrawingMode {
    case marker
    case line
    case arrow
    case square
    case circle
}
