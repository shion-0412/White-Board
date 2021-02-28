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
    private var trackingArea: NSTrackingArea?
    
    override func draw(_ dirtyRect: NSRect) {
        NSColor.white.setFill()
        __NSRectFill(dirtyRect)
        super.draw(dirtyRect)
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if self.trackingArea != nil {
            self.removeTrackingArea(self.trackingArea!)
            self.trackingArea = nil
        }
        let options: NSTrackingArea.Options = [.mouseMoved, .mouseEnteredAndExited, .activeAlways]
        let rect = NSRect(origin: .zero, size: self.frame.size)
        self.trackingArea = NSTrackingArea(rect: rect, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(self.trackingArea!)
    }
    
    override func mouseEntered(with event: NSEvent) {
        setCurrentCursor()
    }
    
    override func mouseExited(with event: NSEvent) {
        NSCursor.arrow.set()
    }
    
    public func setCurrentCursor() {
        if drawingMode == .marker {
            addCursorRect(self.bounds, cursor: markerCursor)
        } else {
            NSCursor.crosshair.set()
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: false, block: {_ in
            self.setCurrentCursor()
        })
        temporaryLinePath = NSBezierPath()
        temporaryLineView = LineView(frame: self.bounds)
        temporaryLineView!.path = temporaryLinePath
        temporaryLineView?.pathColor = globalColor
        temporaryLineView?.drawingMode = drawingMode
        temporaryLineView?.fillsShapes = fillsShapes
        self.addSubview(temporaryLineView!)
        switch drawingMode {
        case .arrow:
            temporaryLinePath!.lineJoinStyle = .bevel
            temporaryLinePath!.lineCapStyle = .square
        case .line:
            temporaryLinePath!.lineJoinStyle = .bevel
            temporaryLinePath!.lineCapStyle = .square
        case .square:
            temporaryLinePath!.lineJoinStyle = .miter
            temporaryLinePath!.lineCapStyle = .square
        default:
            temporaryLinePath!.lineJoinStyle = .round
            temporaryLinePath!.lineCapStyle = .round
        }
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
        guard temporaryLinePath != nil else { return }
        switch drawingMode {
        case .marker:
            drawTemporaryMarker(locationInWindow: event.locationInWindow)
        case .line:
            drawTemporaryLine(locationInWindow: event.locationInWindow)
        case .arrow:
            drawTemporaryArrow(locationInWindow: event.locationInWindow)
        case .square:
            drawTemporarySquare(locationInWindow: event.locationInWindow)
        case .circle:
            drawTemporaryCircle(locationInWindow: event.locationInWindow)
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        temporaryLinePath = nil
        temporaryLineView = nil
        temporaryOriginalLocation = nil
    }
    
    private func drawTemporaryMarker(locationInWindow: NSPoint) {
        let locationInView = NSPoint(x: locationInWindow.x - self.frame.origin.x, y: locationInWindow.y - 2 * self.frame.origin.y)
        temporaryLinePath!.line(to: locationInView)
        temporaryLineView!.needsDisplay = true
    }
    
    private func drawTemporaryLine(locationInWindow: NSPoint) {
        var locationInView = NSPoint(x: locationInWindow.x - self.frame.origin.x, y: locationInWindow.y - 2 * self.frame.origin.y)
        if shiftKeyIsPressed {
            let diffX = abs(locationInView.x - temporaryOriginalLocation!.x)
            let diffY = abs(locationInView.y - temporaryOriginalLocation!.y)
            if diffX <= diffY {
                locationInView = NSPoint(x: temporaryOriginalLocation!.x, y: locationInView.y)
            } else {
                locationInView = NSPoint(x: locationInView.x, y: temporaryOriginalLocation!.y)
            }
        }
        temporaryLinePath?.removeAllPoints()
        temporaryLinePath!.move(to: temporaryOriginalLocation!)
        temporaryLinePath!.line(to: locationInView)
        temporaryLineView!.needsDisplay = true
    }
    
    private func drawTemporaryArrow(locationInWindow: NSPoint) {
        var locationInView = NSPoint(x: locationInWindow.x - self.frame.origin.x, y: locationInWindow.y - 2 * self.frame.origin.y)
        if shiftKeyIsPressed {
            let diffX = abs(locationInView.x - temporaryOriginalLocation!.x)
            let diffY = abs(locationInView.y - temporaryOriginalLocation!.y)
            if diffX <= diffY {
                locationInView = NSPoint(x: temporaryOriginalLocation!.x, y: locationInView.y)
            } else {
                locationInView = NSPoint(x: locationInView.x, y: temporaryOriginalLocation!.y)
            }
        }
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
    
    private func drawTemporarySquare(locationInWindow: NSPoint) {
        var locationInView = NSPoint(x: locationInWindow.x - self.frame.origin.x, y: locationInWindow.y - 2 * self.frame.origin.y)
        temporaryLinePath?.removeAllPoints()
        temporaryLinePath!.move(to: temporaryOriginalLocation!)
        if shiftKeyIsPressed {
            let diffX = locationInView.x - temporaryOriginalLocation!.x
            let diffY = locationInView.y - temporaryOriginalLocation!.y
            if abs(diffX) <= abs(diffY) {
                locationInView = NSPoint(x: temporaryOriginalLocation!.x + abs(diffY) * diffX / abs(diffX),
                                         y: locationInView.y)
            } else {
                locationInView = NSPoint(x: locationInView.x,
                                         y: temporaryOriginalLocation!.y + abs(diffX) * diffY / abs(diffY))
            }
        }
        temporaryLinePath!.line(to: NSPoint(x: locationInView.x, y: temporaryOriginalLocation!.y))
        temporaryLinePath!.line(to: locationInView)
        temporaryLinePath!.line(to: NSPoint(x: temporaryOriginalLocation!.x, y: locationInView.y))
        temporaryLinePath!.line(to: temporaryOriginalLocation!)
        temporaryLineView!.needsDisplay = true
    }
    
    private func drawTemporaryCircle(locationInWindow: NSPoint) {
        let locationInView = NSPoint(x: locationInWindow.x - self.frame.origin.x, y: locationInWindow.y - 2 * self.frame.origin.y)
        temporaryLinePath?.removeAllPoints()
        var rectX = temporaryOriginalLocation!.x
        var rectY = temporaryOriginalLocation!.y
        let diffX = locationInView.x - temporaryOriginalLocation!.x
        let diffY = locationInView.y - temporaryOriginalLocation!.y
        var rect: NSRect = .zero
        if shiftKeyIsPressed {
            let width = max(abs(diffX), abs(diffY))
            if diffX < 0 {
                rectX -= width
            }
            if diffY < 0 {
                rectY -= width
            }
            rect = NSRect(x: rectX, y: rectY, width: width, height: width)
        } else {
            if diffX < 0 {
                rectX += diffX
            }
            if diffY < 0 {
                rectY += diffY
            }
            rect = NSRect(x: rectX, y: rectY, width: abs(diffX), height: abs(diffY))
        }
        temporaryLinePath!.appendOval(in: rect)
        temporaryLineView!.needsDisplay = true
    }
    
    public func addImage() {
        let dialog = NSOpenPanel()
        dialog.canChooseDirectories = false
        dialog.canChooseFiles = true
        dialog.canCreateDirectories = false
        dialog.allowsMultipleSelection = false
        dialog.allowedFileTypes = NSImage.imageTypes
        dialog.begin { (result) -> Void in
            if result == .OK {
                guard dialog.url != nil else { return }
                let image = NSImage(contentsOf: dialog.url!)
                var maxLength: CGFloat = 100
                if globalSize == .second {
                    maxLength = 200
                } else if globalSize == .third {
                    maxLength = 400
                } else if globalSize == .fourth {
                    maxLength = 800
                }
                let orgSize = image!.size
                let orgRatio = orgSize.height / orgSize.width
                var newSize = CGSize.zero
                if orgSize.width >= orgSize.height {
                    newSize.width = maxLength
                    newSize.height = maxLength * orgRatio
                } else {
                    newSize.height = maxLength
                    newSize.width = maxLength / orgRatio
                }
                let imageView = ImageView()
                imageView.frame = NSRect(origin: NSPoint(x: 100, y: 100), size: newSize)
                imageView.imageScaling = .scaleAxesIndependently
                imageView.image = NSImage(contentsOf: dialog.url!)
                imageView.borderColor = .green
                imageView.borderWidth = 1
                self.addSubview(imageView)
            }
        }
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
    var drawingMode: DrawingMode = .marker
    var fillsShapes = false
    
    override func draw(_ dirtyRect: NSRect) {
        if path != nil {
            pathColor?.set()
            if (self.drawingMode == .square || self.drawingMode == .circle) && self.fillsShapes {
                path!.fill()
            } else {
                path!.lineWidth = lineWidth != nil ? lineWidth! : firstLineWidth
                path!.stroke()
            }
        }
    }
}

enum PathType {
    case line
    case shape
    case label
}

class ImageView: NSImageView {
    
    var originalPoint: NSPoint?
    private var trackingArea: NSTrackingArea?
//    private var cursorPosition: CursorPosition = .other
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if self.trackingArea != nil {
            self.removeTrackingArea(self.trackingArea!)
            self.trackingArea = nil
        }
        let options: NSTrackingArea.Options = [.mouseMoved, .mouseEnteredAndExited, .activeAlways]
        let rect = NSRect(origin: .zero, size: self.frame.size)
        self.trackingArea = NSTrackingArea(rect: rect, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(self.trackingArea!)
    }
    
    override func mouseEntered(with event: NSEvent) {
        NSCursor.openHand.set()
    }
    
    override func mouseExited(with event: NSEvent) {
        (superview as! DrawView).setCurrentCursor()
    }

//    override func mouseMoved(with event: NSEvent) {
//        let originXInWindow = superview!.frame.origin.x + self.frame.origin.x
//        let originYInWindow = superview!.frame.origin.y + self.frame.origin.y
//        let locationInView = NSPoint(x: event.locationInWindow.x - originXInWindow, y: event.locationInWindow.y - originYInWindow)
//        let threshold: CGFloat = 10
//        if locationInView.x <= threshold || self.frame.width - locationInView.x <= threshold {
//            cursorPosition = .edgeLeftRight
//            NSCursor.resizeLeftRight.set()
//        } else if locationInView.y <= threshold || self.frame.height - locationInView.y <= threshold {
//            cursorPosition = .edgeUpDown
//            NSCursor.resizeUpDown.set()
//        } else {
//            cursorPosition = .other
//            NSCursor.arrow.set()
//        }
//    }
    
    override func mouseDown(with event: NSEvent) {
        originalPoint = event.locationInWindow
        NSCursor.closedHand.set()
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard originalPoint != nil else { return }
        NSCursor.closedHand.set()
        let differenceX = event.locationInWindow.x - originalPoint!.x
        let differenceY = event.locationInWindow.y - originalPoint!.y
        let rect = self.frame
//        if cursorPosition == .edgeLeftRight {
//            self.frame = NSRect(x: rect.origin.x, y: rect.origin.y, width: rect.width + differenceX, height: rect.height)
//            originalPoint = event.locationInWindow
//        } else if cursorPosition == .edgeUpDown {
//            self.frame = NSRect(x: rect.origin.x, y: rect.origin.y, width: rect.width, height: rect.height + differenceY)
//            originalPoint = event.locationInWindow
//        } else {
            self.frame = NSRect(x: rect.origin.x + differenceX, y: rect.origin.y + differenceY, width: rect.width, height: rect.height)
            originalPoint = event.locationInWindow
//        }
//        self.updateTrackingAreas()
    }
    
    override func mouseUp(with event: NSEvent) {
        let newImageView = UnclickableImageView(frame: self.frame)
        newImageView.imageScaling = .scaleAxesIndependently
        newImageView.image = self.image
        superview?.addSubview(newImageView)
        self.removeFromSuperview()
    }
    
}

class UnclickableImageView: NSImageView {
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: false, block: {_ in
            (self.superview as! DrawView).setCurrentCursor()
        })
    }
    
}


enum CursorPosition {
    case edgeLeftRight
    case edgeUpDown
    case other
}

class Label: NSTextField {
    
    var originalPoint: NSPoint?
    private var trackingArea: NSTrackingArea?
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if self.trackingArea != nil {
            self.removeTrackingArea(self.trackingArea!)
            self.trackingArea = nil
        }
        let options: NSTrackingArea.Options = [.mouseMoved, .mouseEnteredAndExited, .activeAlways]
        let rect = NSRect(origin: .zero, size: self.frame.size)
        self.trackingArea = NSTrackingArea(rect: rect, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(self.trackingArea!)
    }
    
    override func mouseEntered(with event: NSEvent) {
        NSCursor.openHand.set()
    }
    
    override func mouseExited(with event: NSEvent) {
        (superview as! DrawView).setCurrentCursor()
    }
    
    override func mouseDown(with event: NSEvent) {
        originalPoint = event.locationInWindow
        NSCursor.closedHand.set()
    }
    
    override func mouseDragged(with event: NSEvent) {
        if originalPoint != nil {
            NSCursor.closedHand.set()
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
        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: false, block: {_ in
            (self.superview as! DrawView).setCurrentCursor()
        })
    }
    
}
