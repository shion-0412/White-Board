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
    @IBOutlet weak var triangleShapeView: ChoosableShapeView!
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
        triangleShapeView.shapeType = .triangle
        triangleShapeView.delegate = self
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
 
    
    @IBAction func clearCanvas(_ sender: Any) {
        delegate?.clearCanvas()
    }
    
    @IBAction func createImage(_ sender: Any) {
        delegate?.createImage()
    }
    
    func addShape(type: ChoosableShape) {
        delegate?.addShape(type: type)
    }
    
    func changeColor(order: ChoosableColorOrder) {
        firstColorView.borderColor = .black
        secondColorView.borderColor = .black
        thirdColorView.borderColor = .black
        fourthColorView.borderColor = .black
        switch order {
        case .first:
            firstColorView.borderColor = .green
        case .second:
            secondColorView.borderColor = .green
        case .third:
            thirdColorView.borderColor = .green
        case .fourth:
            fourthColorView.borderColor = .green
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
    func clearCanvas()
    func createImage()
    func addShape(type: ChoosableShape)
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
    
    var shapeType: ChoosableShape = .square
    weak var delegate: ChoosableShapeDelegate?
    
    override func draw(_ dirtyRect: NSRect) {
        let path = NSBezierPath()
        let width = self.frame.width
        switch shapeType {
        case .triangle:
            path.move(to: NSPoint(x: 0, y: 0))
            path.line(to: NSPoint(x: width, y: 0))
            path.line(to: NSPoint(x: width / 2, y: sqrt(3) * width / 2))
            path.line(to: NSPoint(x: 0, y: 0))
        case .circle:
            let rect = NSRect(x: 0, y: 0, width: width, height: width)
            path.appendOval(in: rect)
        default:
            path.move(to: NSPoint(x: 0, y: 0))
            path.line(to: NSPoint(x: width, y: 0))
            path.line(to: NSPoint(x: width, y: width))
            path.line(to: NSPoint(x: 0, y: width))
            path.line(to: NSPoint(x: 0, y: 0))
        }
        NSColor.green.set()
        path.fill()
    }
    
    override func mouseDown(with event: NSEvent) {
        delegate?.addShape(type: shapeType)
    }
    
}

protocol ChoosableShapeDelegate: class {
    func addShape(type: ChoosableShape)
}

enum ChoosableShape {
    case square
    case triangle
    case circle
}

