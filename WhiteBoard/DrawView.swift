//
//  DrawView.swift
//  justpaint
//
//  Created by 秋泉 on 2021/02/07.
//

import Cocoa

class DrawView: NSView {

    var allPaths = [[String: Any]]()
    var drawingLinePath: NSBezierPath?
    var drawingLineView: LineView?
    var lastViews: [NSView] = []
    
    override func draw(_ dirtyRect: NSRect) {
        NSColor.white.setFill()
        __NSRectFill(dirtyRect)
        super.draw(dirtyRect)
    }
    
    override func mouseDown(with event: NSEvent) {
        drawingLinePath = NSBezierPath()
        drawingLineView = LineView(frame: self.bounds)
        drawingLineView!.path = drawingLinePath
        drawingLineView?.pathColor = globalColor
        self.addSubview(drawingLineView!)
        drawingLinePath!.lineJoinStyle = .round
        drawingLinePath!.lineCapStyle = .round
        var lineWidth: CGFloat = firstLineWidth
        if globalSize == .second {
            lineWidth = secondLineWidth
        } else if globalSize == .third {
            lineWidth = thirdLineWidth
        } else if globalSize == .fourth {
            lineWidth = fourthLineWidth
        }
        drawingLineView?.lineWidth = lineWidth
        drawingLinePath!.lineWidth = lineWidth
        let locationInView = NSPoint(x: event.locationInWindow.x - self.frame.origin.x, y: event.locationInWindow.y - 2 * self.frame.origin.y)
        drawingLinePath!.move(to: locationInView)
        drawingLinePath!.line(to: locationInView)
        drawingLineView!.needsDisplay = true
    }
    
    override func mouseDragged(with event: NSEvent) {
        if drawingLinePath != nil {
            let locationInView = NSPoint(x: event.locationInWindow.x - self.frame.origin.x, y: event.locationInWindow.y - 2 * self.frame.origin.y)
            drawingLinePath!.line(to: locationInView)
            drawingLinePath!.move(to: locationInView)
            drawingLineView!.needsDisplay = true
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        drawingLinePath = nil
        drawingLineView = nil
    }
    
    public func clearCanvas() {
        self.subviews.forEach {
            $0.removeFromSuperview()
        }
        needsDisplay = true
    }
    
    public func createImage() {
        let rep = self.bitmapImageRepForCachingDisplay(in: self.bounds)!
        self.cacheDisplay(in: self.bounds, to: rep)
        if let data = rep.representation(using: .png, properties: [:]) {
            let savePanel = NSSavePanel()
            savePanel.nameFieldStringValue = "image.png"
            savePanel.title = "Save as an image"
            savePanel.runModal()
            if let url = savePanel.url{
                do {
                    try data.write(to: url, options: .atomic)
                } catch let error {
                    print("error: \(error)")
                }
            }
        }
    }
    
    public func addShape(type: ChoosableShape) {
        var width: CGFloat = firstShapeWidth
        if globalSize == .second {
            width = secondShapeWidth
        } else if globalSize == .third {
            width = thirdShapeWidth
        } else if globalSize == .fourth {
            width = fourthShapeWidth
        }
        let x = (self.frame.width - width) / 2
        let y = (self.frame.height - width) / 2
        let shapeView = ShapeView(frame: NSRect(x: x, y: y, width: width, height: width))
        shapeView.type = type
        shapeView.borderColor = .green
        shapeView.borderWidth = 1
        addSubview(shapeView)
    }
    
    func addlabel(text: String) {
        var size: CGFloat = firstLabelSize
        if globalSize == .second {
            size = secondLabelSize
        } else if globalSize == .third {
            size = thirdLabelSize
        } else if globalSize == .fourth {
            size = fourthLabelSize
        }
        let label = Label(labelWithString: text)
        label.textColor = globalColor
        label.font = .systemFont(ofSize: size)
        label.layer?.backgroundColor = NSColor.clear.cgColor
        label.textColor = globalColor
        label.borderColor = .green
        label.borderWidth = 1
        label.sizeToFit()
        let width = label.frame.width
        let height = label.frame.height
        let x = (self.frame.width - width) / 2
        let y = (self.frame.height - height) / 2
        label.frame = NSRect(x: x, y: y, width: width, height: height)
        addSubview(label)
    }
    
    override func addSubview(_ view: NSView) {
        super.addSubview(view)
        self.lastViews = []
    }
 
    func undo() {
        if self.subviews.count > 0 {
            lastViews.append(self.subviews.last!)
            self.subviews.last!.removeFromSuperview()
        }
        
    }
    
    func redo() {
        if lastViews.count > 0 {
            let last = lastViews.popLast()
            let currentLastViews = lastViews
            self.addSubview(last!)
            lastViews = currentLastViews
        }
    }
}

class LineView: NSView {
    
    var path: NSBezierPath?
    var pathColor: NSColor?
    var lineWidth: CGFloat?
    
    override func draw(_ dirtyRect: NSRect) {
        if path != nil {
            pathColor?.set()
            path!.lineWidth = lineWidth != nil ? lineWidth! : firstLineWidth
            path!.stroke()
        }
    }
}

enum PathType {
    case line
    case shape
    case label
}

class ShapeView: NSView {
    
    var originalPoint: NSPoint?
    var type: ChoosableShape?
    
    override func draw(_ dirtyRect: NSRect) {
        let path = NSBezierPath()
        let width = self.frame.width
        switch self.type {
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
        globalColor.set()
        path.fill()
    }
    
    override func mouseDown(with event: NSEvent) {
        originalPoint = event.locationInWindow
    }
    
    override func mouseDragged(with event: NSEvent) {
        if originalPoint != nil {
            let differenceX = event.locationInWindow.x - originalPoint!.x
            let differenceY = event.locationInWindow.y - originalPoint!.y
            let rect = self.frame
            self.frame = NSRect(x: rect.origin.x + differenceX, y: rect.origin.y + differenceY, width: rect.width, height: rect.height)
            originalPoint = event.locationInWindow
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        let newView = UnclickableShapeView(frame: self.frame)
        newView.endPoint = self.frame
        newView.type = type
        newView.endColor = globalColor
        superview?.addSubview(newView)
        self.removeFromSuperview()
    }
}

class UnclickableShapeView: NSView {
    
    var type: ChoosableShape?
    var endColor: NSColor?
    var endPoint: CGRect = CGRect.zero
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let path = NSBezierPath()
        let width = self.frame.width
        switch self.type {
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
        endColor?.set()
        path.fill()
        self.frame = endPoint
    }
    
}

class Label: NSTextField {
    
    var originalPoint: NSPoint?
    
    override func mouseDown(with event: NSEvent) {
        originalPoint = event.locationInWindow
    }
    
    override func mouseDragged(with event: NSEvent) {
        if originalPoint != nil {
            let differenceX = event.locationInWindow.x - originalPoint!.x
            let differenceY = event.locationInWindow.y - originalPoint!.y
            let rect = self.frame
            self.frame = NSRect(x: rect.origin.x + differenceX, y: rect.origin.y + differenceY, width: rect.width, height: rect.height)
            originalPoint = event.locationInWindow
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        let newLabel = UnclickableLabel(labelWithString: self.stringValue)
        newLabel.frame = self.frame
        newLabel.endPoint = self.frame
        var size: CGFloat = firstLabelSize
        if globalSize == .second {
            size = secondLabelSize
        } else if globalSize == .third {
            size = thirdLabelSize
        } else if globalSize == .fourth {
            size = fourthLabelSize
        }
        newLabel.stringValue = self.stringValue
        newLabel.textColor = globalColor
        newLabel.font = .systemFont(ofSize: size)
        newLabel.layer?.backgroundColor = NSColor.clear.cgColor
        newLabel.textColor = globalColor
        superview?.addSubview(newLabel)
        self.removeFromSuperview()
    }
}

class UnclickableLabel: NSTextField {
 
    var endPoint: CGRect = CGRect.zero
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        self.frame = endPoint
    }
    
}
