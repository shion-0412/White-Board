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
    @IBOutlet weak var fifthColorView: ChoosableColorView!
    @IBOutlet weak var labelTextField: NSTextField!
    @IBOutlet weak var sizeTextField: NSTextField!
    @IBOutlet weak var stepper: NSStepper!
    @IBOutlet weak var widthTextField: NSTextField!
    @IBOutlet weak var widthStepper: NSStepper!
    
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
        firstSizeView.choosableSize = .first
        firstSizeView.delegate = self
        secondSizeView.choosableSize = .second
        secondSizeView.delegate = self
        thirdSizeView.choosableSize = .third
        thirdSizeView.delegate = self
        fourthSizeView.choosableSize = .fourth
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
        fifthColorView.delegate = self
        fifthColorView.order = .fifth
        labelTextField.delegate = self
        sizeTextField.delegate = self
        widthTextField.delegate = self
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
    
    @IBAction func clickStepper(_ sender: NSStepper) {
        let newSizeValue = stepper.stringValue
        sizeTextField.stringValue = newSizeValue
        if let number = NumberFormatter().number(from: newSizeValue) {
            globalLabelSize = CGFloat(truncating: number)
        }
    }
    
    @IBAction func clickWidthStepper(_ sender: NSStepper) {
        let newSizeValue = widthStepper.stringValue
        widthTextField.stringValue = newSizeValue
        if let number = NumberFormatter().number(from: newSizeValue) {
            globalImageSize = CGFloat(truncating: number)
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
        changeBrush(type: .other)
    }
    
    func changeColor(order: ChoosableColorOrder) {
        firstColorView.borderColor = .black
        secondColorView.borderColor = .black
        thirdColorView.borderColor = .black
        fourthColorView.borderColor = .black
        fifthColorView.borderColor = .black
        switch order {
        case .first:
            firstColorView.borderColor = .green
        case .second:
            secondColorView.borderColor = .green
        case .third:
            thirdColorView.borderColor = .green
        case .fourth:
            fourthColorView.borderColor = .green
        case .fifth:
            fifthColorView.borderColor = .green
        }
    }
    
    func changeBrush(type: ChoosableSize) {
        firstSizeView.borderWidth = 0
        secondSizeView.borderWidth = 0
        thirdSizeView.borderWidth = 0
        fourthSizeView.borderWidth = 0
        switch type {
        case .first:
            changeDrawingMode(type: .marker)
            firstSizeView.borderWidth = 1
        case .second:
            changeDrawingMode(type: .marker)
            secondSizeView.borderWidth = 1
        case .third:
            changeDrawingMode(type: .marker)
            thirdSizeView.borderWidth = 1
        case .fourth:
            changeDrawingMode(type: .marker)
            fourthSizeView.borderWidth = 1
        case .other:
            break
        }
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField else { return }
        let newSizeValue = textField.stringValue.replacingOccurrences(of: ",", with: "")
        guard let number = NumberFormatter().number(from: newSizeValue) else { return }
        var newSize = CGFloat(truncating: number)
        if sizeTextField.identifier ==  textField.identifier {
            let minSize = CGFloat(stepper.minValue)
            let maxSize = CGFloat(stepper.maxValue)
            if newSize < minSize {
                sizeTextField.stringValue = minSize.description
                newSize = minSize
            }
            if maxSize < newSize {
                sizeTextField.stringValue = maxSize.description
                newSize = maxSize
            }
            stepper.stringValue = newSize.description
            globalLabelSize = newSize
        } else if widthTextField.identifier ==
                    textField.identifier {
            let minSize = CGFloat(widthStepper.minValue)
            let maxSize = CGFloat(widthStepper.maxValue)
            if newSize < minSize {
                widthTextField.stringValue = minSize.description
                newSize = minSize
            }
            if maxSize < newSize {
                widthTextField.stringValue = maxSize.description
                newSize = maxSize
            }
            widthStepper.stringValue = newSize.description
            globalImageSize = newSize
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
    case fifth
}

class ChoosableSizeView: NSView {
    
    var choosableSize: ChoosableSize = .first
    weak var delegate: ChoosableSizeDelegate?
    
    override func mouseDown(with event: NSEvent) {
        switch choosableSize {
        case .first:
            globalBrushSize = 3
        case .second:
            globalBrushSize = 7.5
        case .third:
            globalBrushSize = 20
        case .fourth:
            globalBrushSize = 80
        default:
            break
        }
        self.borderWidth = 1
        delegate?.changeBrush(type: choosableSize)
    }
}

protocol ChoosableSizeDelegate: class {
    func changeBrush(type: ChoosableSize)
}

enum ChoosableSize {
    case first
    case second
    case third
    case fourth
    case other
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
        default:
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
    case label
    case image
}
