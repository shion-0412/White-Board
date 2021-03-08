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
    var temporaryOriginalLocation: NSPoint?
    private var trackingArea: NSTrackingArea?
    var subviewDics = [[String:Any]]()
    var lastSubviewDics = [[String:Any]]()
    var targetView: NSView?
    var targetViewExist = false
    var targetViewIndex: Int = 0
    var originalPoint: NSPoint?
    var temporaryDiffX: CGFloat = 0
    var temporaryDiffY: CGFloat = 0
    
    override func draw(_ dirtyRect: NSRect) {
        NSColor.white.setFill()
        __NSRectFill(dirtyRect)
        super.draw(dirtyRect)
    }
    
    func addSubviewAndResetRedoArrays(_ view: NSView) {
        self.addSubview(view)
        self.removedViewsForRedo = []
        self.behaviorsForRedo = []
        self.deletedIndexesForRedo = []
        self.deletedSizeForRedo = []
    }
    
    override func mouseDown(with event: NSEvent) {
        let locationInView = NSPoint(x: event.locationInWindow.x - self.frame.origin.x, y: event.locationInWindow.y - 2 * self.frame.origin.y)
        self.targetView?.borderWidth = 0
        self.targetViewExist = false
        self.targetView = nil
        checkCurrentPoint(locationInView: locationInView)
        if targetViewExist {
            originalPoint = event.locationInWindow
            return
        }
        temporaryLinePath = NSBezierPath()
        temporaryLineView = LineView()
        temporaryLineView!.path = temporaryLinePath
        temporaryLineView?.pathColor = globalColor
        temporaryLineView?.drawingMode = drawingMode
        temporaryLineView?.fillsShapes = fillsShapes
        self.addSubviewAndResetRedoArrays(temporaryLineView!)
        behaviorsForUndo.append(.addView)
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
        let lineWidth: CGFloat = (drawingMode == .marker) ? globalBrushSize : 7.5
        temporaryLineView?.lineWidth = lineWidth
        temporaryLinePath!.lineWidth = lineWidth
        if drawingMode != .marker {
            temporaryLineView?.frame = NSRect(x: locationInView.x, y: locationInView.y, width: 0, height: 0)
        } else {
            temporaryLineView?.frame = self.bounds
        }
        temporaryOriginalLocation = locationInView
        temporaryLinePath!.move(to: locationInView)
        temporaryLinePath!.line(to: locationInView)
        temporaryLineView!.needsDisplay = true
    }
    
    override func mouseDragged(with event: NSEvent) {
        if targetViewExist && originalPoint != nil {
            NSCursor.closedHand.set()
            let differenceX = event.locationInWindow.x - originalPoint!.x
            let differenceY = event.locationInWindow.y - originalPoint!.y
            let rect = targetView!.frame
            targetView!.frame = NSRect(x: rect.origin.x + differenceX, y: rect.origin.y + differenceY, width: rect.width, height: rect.height)
            originalPoint = event.locationInWindow
            return
        }
        guard temporaryLinePath != nil else { return }
//        setCurrentCursor()
        var diffX: CGFloat = 0
        var diffY: CGFloat = 0
        if drawingMode != .marker {
            let locationInView = NSPoint(x: event.locationInWindow.x - self.frame.origin.x, y: event.locationInWindow.y - 2 * self.frame.origin.y)
            var rectX = temporaryOriginalLocation!.x
            var rectY = temporaryOriginalLocation!.y
            diffX = locationInView.x - temporaryOriginalLocation!.x
            temporaryDiffX = diffX
            diffY = locationInView.y - temporaryOriginalLocation!.y
            temporaryDiffY = diffY
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
            temporaryLineView?.frame = rect
        }
        switch drawingMode {
        case .marker:
            drawTemporaryMarker(locationInWindow: event.locationInWindow)
        case .line:
            drawTemporaryLine(locationInWindow: event.locationInWindow, sameSign: diffX * diffY > 0)
        case .arrow:
            drawTemporaryArrow(locationInWindow: event.locationInWindow, diffX: diffX, diffY: diffY)
        case .square:
            drawTemporarySquare(locationInWindow: event.locationInWindow)
        case .circle:
            drawTemporaryCircle(locationInWindow: event.locationInWindow)
        default:
            return
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        NSCursor.arrow.set()
        if !targetViewExist && temporaryLineView != nil {
            var temporaryLineViewDic: [String:Any] = [
                "type": drawingMode,
                "index": self.subviews.count - 1,
                "originX": temporaryLineView!.frame.origin.x,
                "originY": temporaryLineView!.frame.origin.y,
                "width": temporaryLineView!.frame.width,
                "height": temporaryLineView!.frame.height]
            if drawingMode == .line || drawingMode == .arrow {
                temporaryLineViewDic.updateValue(temporaryLinePath!.lineWidth / 2, forKey: "lineWidth")
                temporaryLineViewDic.updateValue(temporaryDiffX, forKey: "diffX")
                temporaryLineViewDic.updateValue(temporaryDiffY, forKey: "diffY")
            }
            subviewDics.append(temporaryLineViewDic)
        } else if targetViewExist {
            subviewDics[targetViewIndex].updateValue(targetView!.frame.origin.x, forKey: "originX")
            subviewDics[targetViewIndex].updateValue(targetView!.frame.origin.y, forKey: "originY")
            subviewDics[targetViewIndex].updateValue(targetView!.frame.width, forKey: "width")
            subviewDics[targetViewIndex].updateValue(targetView!.frame.height, forKey: "height")
        }
        temporaryLinePath = nil
        temporaryLineView = nil
        temporaryOriginalLocation = nil
    }
    
    func windowResize(diffY: CGFloat) {
        for (index, subview) in self.subviews.enumerated() {
            subview.frame.origin.y += diffY
            let dicIndex = index
            subviewDics[dicIndex].updateValue(subview.frame.origin.y, forKey: "originY")
        }
    }
    
    func checkCurrentPoint(locationInView: NSPoint) {
        for (indexOfDic, dic) in subviewDics.reversed().enumerated() {
            let type = dic["type"] as! DrawingMode
            let index = dic["index"] as! Int
            let originX = dic["originX"] as! CGFloat
            let originY = dic["originY"] as! CGFloat
            let width = dic["width"] as! CGFloat
            let height = dic["height"] as! CGFloat
            let xIsInArea = originX <= locationInView.x && locationInView.x <= originX + width
            let yIsInArea = originY <= locationInView.y && locationInView.y <= originY + height
            if type == .square || type == .circle || type == .label || type == .image {
                if xIsInArea && yIsInArea {
                    self.targetView = self.subviews[index]
                    self.targetView?.borderWidth = 2
                    self.targetView?.borderColor = .green
                    targetViewExist = true
                    targetViewIndex = subviewDics.count - 1 - indexOfDic
                    targetViewType = type
                    return
                }
            } else if type == .line || type == .arrow {
                let lineWidth = dic["lineWidth"] as! CGFloat
                let diffX = dic["diffX"] as! CGFloat
                let diffY = dic["diffY"] as! CGFloat
                let x0 = locationInView.x - originX
                let y0 = locationInView.y - originY
                let slopeSignIsPositive = diffX * diffY > 0
                let slope = (height / width) * (slopeSignIsPositive ? 1 : -1)
                var distance = abs(-1 * slope * x0 + y0) / sqrt(1 + pow(slope, 2))
                if !slopeSignIsPositive {
                    distance = abs(-1 * slope * x0 + y0 - height) / sqrt(1 + pow(slope, 2))
                }
                if xIsInArea && yIsInArea && distance <= lineWidth {
                    self.targetView = self.subviews[index]
                    targetViewExist = true
                    targetViewIndex = subviewDics.count - 1 - indexOfDic
                    targetViewType = type
                    targetViewLineWidth = lineWidth
                    targetViewDiffX = diffX
                    targetViewDiffY = diffY
                    return
                }
            }
        }
    }
    
    private func drawTemporaryMarker(locationInWindow: NSPoint) {
        let locationInView = NSPoint(x: locationInWindow.x - self.frame.origin.x, y: locationInWindow.y - 2 * self.frame.origin.y)
        temporaryLinePath!.line(to: locationInView)
        temporaryLineView!.needsDisplay = true
    }
    
    private func drawTemporaryLine(locationInWindow: NSPoint, sameSign: Bool) {
        temporaryLinePath?.removeAllPoints()
        let width = temporaryLineView!.frame.width
        let height = temporaryLineView!.frame.height
        let edgeWidth = temporaryLinePath!.lineWidth / sqrt(2)
        if sameSign {
            temporaryLinePath!.move(to: NSPoint(x: edgeWidth, y: edgeWidth))
            temporaryLinePath!.line(to: NSPoint(x: width - edgeWidth, y: height - edgeWidth))
        } else {
            temporaryLinePath!.move(to: NSPoint(x: edgeWidth, y: height - edgeWidth))
            temporaryLinePath!.line(to: NSPoint(x: width - edgeWidth, y: edgeWidth))
        }
        temporaryLineView!.needsDisplay = true
    }
    
    private func drawTemporaryArrow(locationInWindow: NSPoint, diffX: CGFloat, diffY: CGFloat) {
        temporaryLinePath?.removeAllPoints()
        let width = temporaryLineView!.frame.width
        let height = temporaryLineView!.frame.height
        var origin = NSPoint.zero
        var endPoint = NSPoint.zero
        let arrowLength: CGFloat = 30
        let edgeWidth = (temporaryLinePath!.lineWidth / sqrt(2)) + (arrowLength / sqrt(2))
        if diffX > 0 {
            if diffY > 0 {
                origin = NSPoint(x: edgeWidth, y: edgeWidth)
                endPoint = NSPoint(x: width - edgeWidth, y: height - edgeWidth)
            } else {
                origin = NSPoint(x: edgeWidth, y: height - edgeWidth)
                endPoint = NSPoint(x: width - edgeWidth, y: edgeWidth)
            }
        } else {
            if diffY > 0 {
                origin = NSPoint(x: width - edgeWidth, y: edgeWidth)
                endPoint = NSPoint(x: edgeWidth, y: height - edgeWidth)
            } else {
                origin = NSPoint(x: width - edgeWidth, y: height - edgeWidth)
                endPoint = NSPoint(x: edgeWidth, y: edgeWidth)
            }
        }
        temporaryLinePath!.move(to: origin)
        temporaryLinePath!.line(to: endPoint)
        
        let radAngle = atan2(endPoint.y - origin.y, endPoint.x - origin.x)
        let leftAngle = radAngle + (CGFloat.pi * 3 / 4)
        let rightAngle = radAngle - (CGFloat.pi * 3 / 4)
        let leftPoint = NSPoint(x: endPoint.x + arrowLength * cos(leftAngle), y: endPoint.y + arrowLength * sin(leftAngle))
        temporaryLinePath!.line(to: leftPoint)
        temporaryLinePath!.move(to: endPoint)
        let rightPoint = NSPoint(x: endPoint.x + arrowLength * cos(rightAngle), y: endPoint.y + arrowLength * sin(rightAngle))
        temporaryLinePath!.line(to: rightPoint)
        temporaryLineView!.needsDisplay = true
    }
    
    private func drawTemporarySquare(locationInWindow: NSPoint) {
        temporaryLinePath?.removeAllPoints()
        let width = temporaryLineView!.frame.width
        let height = temporaryLineView!.frame.height
        let edgeWidth = fillsShapes ? 0 : temporaryLinePath!.lineWidth / 2
        temporaryLinePath!.move(to: NSPoint(x: edgeWidth, y: edgeWidth))
        temporaryLinePath!.line(to: NSPoint(x: edgeWidth, y: height - edgeWidth))
        temporaryLinePath!.line(to: NSPoint(x: width - edgeWidth, y: height - edgeWidth))
        temporaryLinePath!.line(to: NSPoint(x: width - edgeWidth, y: edgeWidth))
        temporaryLinePath!.line(to: NSPoint(x: edgeWidth, y: edgeWidth))
        temporaryLineView!.needsDisplay = true
    }
    
    private func drawTemporaryCircle(locationInWindow: NSPoint) {
        temporaryLinePath?.removeAllPoints()
        let edgeWidth = fillsShapes ? 0 : temporaryLinePath!.lineWidth / 2
        let rect = NSRect(x: edgeWidth, y: edgeWidth, width: temporaryLineView!.bounds.width - 2 * edgeWidth, height: temporaryLineView!.bounds.height - 2 * edgeWidth)
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
                let maxLength: CGFloat = globalImageSize
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
                let imageView = NSImageView()
                imageView.frame = NSRect(origin: NSPoint(x: 100, y: 100), size: newSize)
                imageView.imageScaling = .scaleAxesIndependently
                imageView.image = NSImage(contentsOf: dialog.url!)
                self.addSubviewAndResetRedoArrays(imageView)
                self.behaviorsForUndo.append(.addView)
                let imageViewlDic: [String:Any] = [
                    "type": DrawingMode.image,
                    "index": self.subviews.count - 1,
                    "originX": imageView.frame.origin.x,
                    "originY": imageView.frame.origin.y,
                    "width": imageView.frame.width,
                    "height": imageView.frame.height]
                self.subviewDics.append(imageViewlDic)
            }
        }
    }
    
    public func clearCanvas() {
        self.subviews.forEach {
            $0.removeFromSuperview()
        }
        self.subviewDics.removeAll()
        self.removedViewsForRedo = []
        self.behaviorsForRedo = []
        self.deletedIndexesForRedo = []
        self.deletedSizeForRedo = []
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
        let label = NSTextField(labelWithString: text)
        label.textColor = globalColor
        label.font = .systemFont(ofSize: globalLabelSize)
        label.layer?.backgroundColor = NSColor.clear.cgColor
        label.textColor = globalColor
        label.sizeToFit()
        let width = label.frame.width
        let height = label.frame.height
        let x = (self.frame.width - width) / 2
        let y = (self.frame.height - height) / 2
        label.frame = NSRect(x: x, y: y, width: width, height: height)
        self.addSubviewAndResetRedoArrays(label)
        behaviorsForUndo.append(.addView)
        let labelDic: [String:Any] = [
            "type": DrawingMode.label,
            "index": self.subviews.count - 1,
            "originX": label.frame.origin.x,
            "originY": label.frame.origin.y,
            "width": label.frame.width,
            "height": label.frame.height]
        subviewDics.append(labelDic)
    }
 
    var copiedType = DrawingMode.square
    var copiedLineView: LineView?
    var copiedImageView: NSImageView?
    var copiedLabel: NSTextField?
    var targetViewType: DrawingMode = .square
    var targetViewLineWidth: CGFloat = 0
    var targetViewDiffX: CGFloat = 0
    var targetViewDiffY: CGFloat = 0
    
    func copyView(removeTargetView: Bool) {
        if targetViewExist && targetView != nil {
            copiedType = targetViewType
            if targetViewType == .image {
                copiedImageView = NSImageView()
                copiedImageView!.image = (targetView as! NSImageView).image
                copiedImageView!.imageScaling = .scaleAxesIndependently
                copiedImageView!.frame = (targetView as! NSImageView).frame
            } else if targetViewType == .label {
                copiedLabel = NSTextField(labelWithString: (targetView as! NSTextField).stringValue)
                copiedLabel!.textColor = (targetView as! NSTextField).textColor
                copiedLabel!.font = (targetView as! NSTextField).font
                copiedLabel!.layer?.backgroundColor = (targetView as! NSTextField).layer?.backgroundColor
                copiedLabel!.textColor = (targetView as! NSTextField).textColor
                copiedLabel!.sizeToFit()
                copiedLabel!.frame = (targetView as! NSTextField).frame
            } else {
                copiedLineView = LineView()
                copiedLineView!.path = (targetView as! LineView).path
                copiedLineView!.pathColor = (targetView as! LineView).pathColor
                copiedLineView!.lineWidth = (targetView as! LineView).lineWidth
                copiedLineView!.drawingMode = copiedType
                copiedLineView!.fillsShapes = (targetView as! LineView).fillsShapes
                copiedLineView!.frame = (targetView as! LineView).frame
            }
            if removeTargetView {
                delete()
            }
        }
    }
    
    func pasteView() {
        if copiedType == .image {
            guard copiedImageView != nil else { return }
            let pastedImageView = NSImageView()
            pastedImageView.image = copiedImageView!.image
            pastedImageView.imageScaling = .scaleAxesIndependently
            let rect = copiedImageView!.frame
            pastedImageView.frame = NSRect(x: rect.origin.x + 50, y: rect.origin.y + 50, width: rect.width, height: rect.height)
            self.addSubviewAndResetRedoArrays(pastedImageView)
            behaviorsForUndo.append(.addView)
            copiedImageView = pastedImageView
            let imageViewlDic: [String:Any] = [
                "type": copiedType,
                "index": self.subviews.count - 1,
                "originX": pastedImageView.frame.origin.x,
                "originY": pastedImageView.frame.origin.y,
                "width": pastedImageView.frame.width,
                "height": pastedImageView.frame.height]
            self.subviewDics.append(imageViewlDic)
        } else if copiedType == .label {
            guard copiedLabel != nil else { return }
            let pastedLabel = NSTextField(labelWithString: copiedLabel!.stringValue)
            pastedLabel.textColor = copiedLabel!.textColor
            pastedLabel.font = copiedLabel!.font
            pastedLabel.layer?.backgroundColor = copiedLabel!.layer?.backgroundColor
            pastedLabel.textColor = copiedLabel!.textColor
            pastedLabel.sizeToFit()
            let rect = copiedLabel!.frame
            pastedLabel.frame = NSRect(x: rect.origin.x + 50, y: rect.origin.y + 50, width: rect.width, height: rect.height)
            self.addSubviewAndResetRedoArrays(pastedLabel)
            behaviorsForUndo.append(.addView)
            copiedLabel = pastedLabel
            let labelDic: [String:Any] = [
                "type": copiedType,
                "index": self.subviews.count - 1,
                "originX": pastedLabel.frame.origin.x,
                "originY": pastedLabel.frame.origin.y,
                "width": pastedLabel.frame.width,
                "height": pastedLabel.frame.height]
            subviewDics.append(labelDic)
        } else {
            guard copiedLineView != nil else { return }
            let pastedLineView = LineView()
            pastedLineView.path = copiedLineView!.path
            pastedLineView.pathColor = copiedLineView!.pathColor
            pastedLineView.lineWidth = copiedLineView!.lineWidth
            pastedLineView.drawingMode = copiedType
            pastedLineView.fillsShapes = copiedLineView!.fillsShapes
            let rect = copiedLineView!.frame
            pastedLineView.frame = NSRect(x: rect.origin.x + 50, y: rect.origin.y + 50, width: rect.width, height: rect.height)
            self.addSubviewAndResetRedoArrays(pastedLineView)
            behaviorsForUndo.append(.addView)
            copiedLineView = pastedLineView
            var copyDic: [String:Any] = [
                "type": copiedType,
                "index": self.subviews.count - 1,
                "originX": pastedLineView.frame.origin.x,
                "originY": pastedLineView.frame.origin.y,
                "width": pastedLineView.frame.width,
                "height": pastedLineView.frame.height]
            if copiedType == .line || copiedType == .arrow {
                copyDic.updateValue(targetViewLineWidth / 2, forKey: "lineWidth")
                copyDic.updateValue(targetViewDiffX, forKey: "diffX")
                copyDic.updateValue(targetViewDiffY, forKey: "diffY")
            }
            subviewDics.append(copyDic)
        }
    }
    
    var behaviorsForUndo = [Behavior]()
    var deletedIndexesForUndo = [Int]()
    var deletedSizeForUndo = [NSSize]()
    var removedViewsForRedo = [NSView]()
    var behaviorsForRedo = [Behavior]()
    var deletedIndexesForRedo = [Int]()
    var deletedSizeForRedo = [NSSize]()
    
    func delete() {
        if targetViewExist {
            let deletedViewSize = targetView!.frame.size
            targetView!.frame.size = NSSize.zero
            behaviorsForUndo.append(.deleteView)
            subviewDics[targetViewIndex].updateValue(CGFloat.zero, forKey: "width")
            subviewDics[targetViewIndex].updateValue(CGFloat.zero, forKey: "height")
            deletedIndexesForUndo.append(targetViewIndex)
            deletedSizeForUndo.append(deletedViewSize)
            targetViewExist = false
            targetView = nil
        }
    }
    
    func undo() {
        guard let lastBehavior = behaviorsForUndo.popLast() else { return }
        if lastBehavior == .addView {
            behaviorsForRedo.append(.addView)
            if self.subviews.count > 0 {
                removedViewsForRedo.append(self.subviews.last!)
                self.subviews.last!.removeFromSuperview()
            }
            if self.subviewDics.count > 0 {
                lastSubviewDics.append(self.subviewDics.last!)
                self.subviewDics.removeLast()
            }
        } else if lastBehavior == .deleteView {
            guard let lastIndex = deletedIndexesForUndo.popLast(),
                  let lastSize = deletedSizeForUndo.popLast() else { return }
            behaviorsForRedo.append(.deleteView)
            let deletedView = self.subviews[lastIndex]
            deletedView.frame.size = lastSize
            subviewDics[lastIndex].updateValue(lastSize.width, forKey: "width")
            subviewDics[lastIndex].updateValue(lastSize.height, forKey: "height")
            deletedIndexesForRedo.append(lastIndex)
            deletedSizeForRedo.append(lastSize)
        }
    }
    
    func redo() {
        guard let lastBehavior = behaviorsForRedo.popLast() else { return }
        if lastBehavior == .addView {
            if removedViewsForRedo.count > 0 {
                let last = removedViewsForRedo.popLast()
                let currentLastViews = removedViewsForRedo
                self.addSubview(last!)
                behaviorsForUndo.append(.addView)
                removedViewsForRedo = currentLastViews
            }
            if lastSubviewDics.count > 0 {
                let last = lastSubviewDics.popLast()
                let currentLastDic = lastSubviewDics
                self.subviewDics.append(last!)
                lastSubviewDics = currentLastDic
            }
        } else if lastBehavior == .deleteView {
            guard let lastIndex = deletedIndexesForRedo.popLast(),
                  let lastSize = deletedSizeForRedo.popLast() else { return }
            let deletedView = self.subviews[lastIndex]
            deletedView.frame.size = NSSize.zero
            behaviorsForUndo.append(.deleteView)
            subviewDics[lastIndex].updateValue(CGFloat.zero, forKey: "width")
            subviewDics[lastIndex].updateValue(CGFloat.zero, forKey: "height")
            deletedIndexesForUndo.append(lastIndex)
            deletedSizeForUndo.append(lastSize)
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
                path!.lineWidth = lineWidth != nil ? lineWidth! : 7.5
                path!.stroke()
            }
        }
    }
}

enum Behavior {
    case addView
    case deleteView
}
