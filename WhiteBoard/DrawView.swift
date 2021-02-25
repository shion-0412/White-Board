//
//  DrawView.swift
//  justpaint
//
//  Created by 秋泉 on 2021/02/07.
//

import Cocoa

class DrawView: NSView {

    var allPaths = [[String: Any]]()
    var temporaryLinePath: NSBezierPath?
    var temporaryLineView: LineView?
    var lastViews: [NSView] = []
    var temporaryOriginalLocation: NSPoint?
    
    override func draw(_ dirtyRect: NSRect) {
        NSColor.white.setFill()
        __NSRectFill(dirtyRect)
        super.draw(dirtyRect)
    }
    
    override func mouseDown(with event: NSEvent) {
        temporaryLinePath = NSBezierPath()
        temporaryLineView = LineView(frame: self.bounds)
        temporaryLineView!.path = temporaryLinePath
        temporaryLineView?.pathColor = globalColor
        self.addSubview(temporaryLineView!)
        temporaryLinePath!.lineJoinStyle = .round
        temporaryLinePath!.lineCapStyle = .round
        var lineWidth: CGFloat = firstLineWidth
        if globalSize == .second {
            lineWidth = secondLineWidth
        } else if globalSize == .third {
            lineWidth = thirdLineWidth
        } else if globalSize == .fourth {
            lineWidth = fourthLineWidth
        }
        temporaryLineView?.lineWidth = lineWidth
        temporaryLinePath!.lineWidth = lineWidth
        let locationInView = NSPoint(x: event.locationInWindow.x - self.frame.origin.x, y: event.locationInWindow.y - 2 * self.frame.origin.y)
        temporaryOriginalLocation = locationInView
        temporaryLinePath!.move(to: locationInView)
        temporaryLinePath!.line(to: locationInView)
        temporaryLineView!.needsDisplay = true
    }
    
    override func mouseDragged(with event: NSEvent) {
        if drawingMode == .line {
            drawTemporaryLine(locationInWindow: event.locationInWindow)
        } else if drawingMode == .arrow {
            drawTemporaryArrow(locationInWindow: event.locationInWindow)
        } else if drawingMode == .square {
            drawTemporarySquare(locationInWindow: event.locationInWindow)
        } else if drawingMode == .triangle {
            drawTemporaryTriangle(locationInWindow: event.locationInWindow)
        } else if drawingMode == .circle {
            drawTemporaryCircle(locationInWindow: event.locationInWindow)
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        temporaryLinePath = nil
        temporaryLineView = nil
        temporaryOriginalLocation = nil
        if drawingMode != .arrow {
            drawingMode = .line
        }
    }
    
    private func drawTemporaryTriangle(locationInWindow: NSPoint) {
        let locationInView = NSPoint(x: locationInWindow.x - self.frame.origin.x, y: locationInWindow.y - 2 * self.frame.origin.y)
        temporaryLinePath?.removeAllPoints()
        temporaryLinePath!.move(to: temporaryOriginalLocation!)
        temporaryLinePath!.line(to: NSPoint(x: locationInView.x, y: temporaryOriginalLocation!.y))
        let topX = (locationInView.x + temporaryOriginalLocation!.x) / 2
        var topY = temporaryOriginalLocation!.y + abs(locationInView.x - temporaryOriginalLocation!.x) * sqrt(3) / 2
        if temporaryOriginalLocation!.y > locationInView.y {
            topY = temporaryOriginalLocation!.y - abs(locationInView.x - temporaryOriginalLocation!.x) * sqrt(3) / 2
        }
        temporaryLinePath!.line(to: NSPoint(x: topX, y: topY))
        temporaryLinePath!.line(to: temporaryOriginalLocation!)
        temporaryLineView!.needsDisplay = true
    }
    
    private func drawTemporaryCircle(locationInWindow: NSPoint) {
        let locationInView = NSPoint(x: locationInWindow.x - self.frame.origin.x, y: locationInWindow.y - 2 * self.frame.origin.y)
        temporaryLinePath?.removeAllPoints()
        var rectX = temporaryOriginalLocation!.x
        let diffX = locationInView.x - temporaryOriginalLocation!.x
        if diffX < 0 {
            rectX += diffX
        }
        var rectY = temporaryOriginalLocation!.y
        let diffY = locationInView.y - temporaryOriginalLocation!.y
        if diffY < 0 {
            rectY += diffY
        }
        let rect = NSRect(x: rectX, y: rectY, width: abs(diffX), height: abs(diffY))
        temporaryLinePath!.appendOval(in: rect)
        temporaryLineView!.needsDisplay = true
    }
    
    private func drawTemporarySquare(locationInWindow: NSPoint) {
        let locationInView = NSPoint(x: locationInWindow.x - self.frame.origin.x, y: locationInWindow.y - 2 * self.frame.origin.y)
        temporaryLinePath?.removeAllPoints()
        temporaryLinePath!.move(to: temporaryOriginalLocation!)
        temporaryLinePath!.line(to: NSPoint(x: locationInView.x, y: temporaryOriginalLocation!.y))
        temporaryLinePath!.line(to: locationInView)
        temporaryLinePath!.line(to: NSPoint(x: temporaryOriginalLocation!.x, y: locationInView.y))
        temporaryLinePath!.line(to: temporaryOriginalLocation!)
        temporaryLineView!.needsDisplay = true
    }
    
    private func drawTemporaryLine(locationInWindow: NSPoint) {
        if temporaryLinePath != nil {
            let locationInView = NSPoint(x: locationInWindow.x - self.frame.origin.x, y: locationInWindow.y - 2 * self.frame.origin.y)
            temporaryLinePath!.line(to: locationInView)
            temporaryLinePath!.move(to: locationInView)
            temporaryLineView!.needsDisplay = true
        }
    }
    
    private func drawTemporaryArrow(locationInWindow: NSPoint) {
        let locationInView = NSPoint(x: locationInWindow.x - self.frame.origin.x, y: locationInWindow.y - 2 * self.frame.origin.y)
        temporaryLinePath?.removeAllPoints()
        temporaryLinePath!.move(to: temporaryOriginalLocation!)
        temporaryLinePath!.line(to: locationInView)
        var arrowLength: CGFloat = 20
        if globalSize == .second {
            arrowLength = 30
        } else if globalSize == .third {
            arrowLength = 50
        } else if globalSize == .fourth {
            arrowLength = 100
        }
        let radAngle = atan2(locationInView.y - temporaryOriginalLocation!.y, locationInView.x - temporaryOriginalLocation!.x)
        let leftAngle = radAngle + (CGFloat.pi * 3 / 4)
        let leftPoint = NSPoint(x: locationInView.x + arrowLength * cos(leftAngle), y: locationInView.y + arrowLength * sin(leftAngle))
        temporaryLinePath!.line(to: leftPoint)
        let rightAngle = radAngle - (CGFloat.pi * 3 / 4)
        let rightPoint = NSPoint(x: locationInView.x + arrowLength * cos(rightAngle), y: locationInView.y + arrowLength * sin(rightAngle))
        temporaryLinePath!.move(to: locationInView)
        temporaryLinePath!.line(to: rightPoint)
        temporaryLineView!.needsDisplay = true
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
            if drawingMode == .line || drawingMode == .arrow || !fillsShapes {
                path!.lineWidth = lineWidth != nil ? lineWidth! : firstLineWidth
                path!.stroke()
            } else {
                path!.fill()
            }
        }
    }
}

enum PathType {
    case line
    case shape
    case label
}

//class ShapeView: NSView {
//
//    var originalPoint: NSPoint?
//    var type: DrawingMode?
//    var fillsThisShape: Bool!
//
//    override func draw(_ dirtyRect: NSRect) {
//        let path = NSBezierPath()
//        let halfBorderWidth: CGFloat = fillsThisShape ? 0 : shapeBorderWidth / 2
//        let width = self.frame.width - halfBorderWidth
//        switch self.type {
//        case .triangle:
//            let initialX = sqrt(3) * halfBorderWidth
//            let rightX = self.frame.width - initialX
//            path.move(to: NSPoint(x: initialX, y: halfBorderWidth))
//            path.line(to: NSPoint(x: rightX, y: halfBorderWidth))
//            path.line(to: NSPoint(x: (initialX + rightX) / 2, y: ((rightX - initialX) * sqrt(3) / 2) + halfBorderWidth))
//            path.line(to: NSPoint(x: halfBorderWidth * sqrt(3) / 2, y: -1 * halfBorderWidth / 2))
//        case .circle:
//            let rect = NSRect(x: halfBorderWidth, y: halfBorderWidth, width: width - halfBorderWidth, height: width - halfBorderWidth)
//            path.appendOval(in: rect)
//        default:
//            path.move(to: NSPoint(x: halfBorderWidth, y: halfBorderWidth))
//            path.line(to: NSPoint(x: width, y: halfBorderWidth))
//            path.line(to: NSPoint(x: width, y: width))
//            path.line(to: NSPoint(x: halfBorderWidth, y: width))
//            path.line(to: NSPoint(x: halfBorderWidth, y: 0))
//        }
//        globalColor.set()
//        if fillsThisShape {
//            path.fill()
//        } else {
//            path.lineWidth = shapeBorderWidth
//            path.stroke()
//        }
//    }
//
//    override func mouseDown(with event: NSEvent) {
//        originalPoint = event.locationInWindow
//    }
//
//    override func mouseDragged(with event: NSEvent) {
//        if originalPoint != nil {
//            let differenceX = event.locationInWindow.x - originalPoint!.x
//            let differenceY = event.locationInWindow.y - originalPoint!.y
//            let rect = self.frame
//            self.frame = NSRect(x: rect.origin.x + differenceX, y: rect.origin.y + differenceY, width: rect.width, height: rect.height)
//            originalPoint = event.locationInWindow
//        }
//    }
//
//    override func mouseUp(with event: NSEvent) {
//        let newView = UnclickableShapeView(frame: self.frame)
//        newView.endPoint = self.frame
//        newView.type = type
//        newView.endColor = globalColor
//        newView.fillsThisShape = fillsThisShape
//        superview?.addSubview(newView)
//        self.removeFromSuperview()
//    }
//}
//
//class UnclickableShapeView: NSView {
//
//    var type: DrawingMode?
//    var endColor: NSColor?
//    var endPoint: CGRect = CGRect.zero
//    var fillsThisShape: Bool!
//
//    override func draw(_ dirtyRect: NSRect) {
//        super.draw(dirtyRect)
//        let path = NSBezierPath()
//        let halfBorderWidth: CGFloat = fillsThisShape ? 0 : shapeBorderWidth / 2
//        let width = self.frame.width - halfBorderWidth
//        switch self.type {
//        case .triangle:
//            let initialX = sqrt(3) * halfBorderWidth
//            let rightX = self.frame.width - initialX
//            path.move(to: NSPoint(x: initialX, y: halfBorderWidth))
//            path.line(to: NSPoint(x: rightX, y: halfBorderWidth))
//            path.line(to: NSPoint(x: (initialX + rightX) / 2, y: ((rightX - initialX) * sqrt(3) / 2) + halfBorderWidth))
//            path.line(to: NSPoint(x: halfBorderWidth * sqrt(3) / 2, y: -1 * halfBorderWidth / 2))
//        case .circle:
//            let rect = NSRect(x: halfBorderWidth, y: halfBorderWidth, width: width - halfBorderWidth, height: width - halfBorderWidth)
//            path.appendOval(in: rect)
//        default:
//            path.move(to: NSPoint(x: halfBorderWidth, y: halfBorderWidth))
//            path.line(to: NSPoint(x: width, y: halfBorderWidth))
//            path.line(to: NSPoint(x: width, y: width))
//            path.line(to: NSPoint(x: halfBorderWidth, y: width))
//            path.line(to: NSPoint(x: halfBorderWidth, y: 0))
//        }
//        endColor?.set()
//        if fillsThisShape {
//            path.fill()
//        } else {
//            path.lineWidth = shapeBorderWidth
//            path.stroke()
//        }
//        self.frame = endPoint
//    }
//
//}

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
