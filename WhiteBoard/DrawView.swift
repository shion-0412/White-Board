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
    var selectedView: NSView?
    var selectedViewIndex: Int = 0
    var selectedViewOriginalPoint: NSPoint?
    var temporaryOriginalLocaionForMarker: NSPoint?
    
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
        self.window?.makeFirstResponder(nil)
        let locationInView = NSPoint(x: event.locationInWindow.x - self.frame.origin.x, y: event.locationInWindow.y - 2 * self.frame.origin.y)
        self.selectedView?.borderWidth = 0
        self.selectedView = nil
        checkCurrentPoint(locationInView: locationInView)
        if self.selectedView != nil {
            // selectedViewが存在するときは、選択だけしてreturn
            selectedViewOriginalPoint = event.locationInWindow
            temporaryOriginalLocaionForMarker = event.locationInWindow
            return
        }
        //DrawindModeがnoneのときは描画せずリターン
        guard drawingMode != .none else { return }
        temporaryLinePath = NSBezierPath()
        temporaryLineView = LineView()
        temporaryLineView!.path = temporaryLinePath
        temporaryLineView?.pathColor = globalColor
        temporaryLineView?.drawingMode = drawingMode
        temporaryLineView?.fillsShapes = fillsShapes
        self.addSubviewAndResetRedoArrays(temporaryLineView!)
        behaviorsForUndo.append(.addView)
        if drawingMode == .arrow || drawingMode == .line {
            temporaryLinePath!.lineJoinStyle = .bevel
            temporaryLinePath!.lineCapStyle = .square
        } else if drawingMode == .square {
            temporaryLinePath!.lineJoinStyle = .miter
            temporaryLinePath!.lineCapStyle = .square
        } else {
            temporaryLinePath!.lineJoinStyle = .round
            temporaryLinePath!.lineCapStyle = .round
        }
        let lineWidth: CGFloat = (drawingMode == .marker) ? globalBrushSize : globalLineWidth
        temporaryLineView?.lineWidth = lineWidth
        temporaryLinePath!.lineWidth = lineWidth
        if drawingMode == .marker || drawingMode == .line || drawingMode == .arrow {
            temporaryLineView?.frame = self.bounds
        } else {
            temporaryLineView?.frame = NSRect(x: locationInView.x, y: locationInView.y, width: 0, height: 0)
        }
        temporaryOriginalLocation = locationInView
        temporaryLinePath!.move(to: locationInView)
        temporaryLinePath!.line(to: locationInView)
        temporaryLineView!.needsDisplay = true
    }
    
    override func mouseDragged(with event: NSEvent) {
        if selectedView != nil && selectedViewOriginalPoint != nil {
            // selectedViewをドラッグしているとき
            NSCursor.closedHand.set()
            let dragDiffX = event.locationInWindow.x - selectedViewOriginalPoint!.x
            let dragDiffY = event.locationInWindow.y - selectedViewOriginalPoint!.y
            let dic = subviewDics[selectedViewIndex]
            if let type = dic["type"] as? DrawingMode, type == .line || type == .arrow {
                //直線、矢印のときはpathを変形、それ以外はframeを変形
                let lineView = self.subviews[selectedViewIndex] as! LineView
                let x = (dic["originX"] as! CGFloat) + dragDiffX
                let y = (dic["originY"] as! CGFloat) + dragDiffY
                let diffX = dic["diffX"] as! CGFloat
                let diffY = dic["diffY"] as! CGFloat
                drawLinePath(path: lineView.path!,
                             startPoint: NSPoint(x: x, y: y),
                             endPoint: NSPoint(x: x + diffX, y: y + diffY),
                             isArrow: type == .arrow)
                lineView.needsDisplay = true
                subviewDics[selectedViewIndex].updateValue(x, forKey: "originX")
                subviewDics[selectedViewIndex].updateValue(y, forKey: "originY")
            } else {
                let rect = selectedView!.frame
                selectedView!.frame = NSRect(x: rect.origin.x + dragDiffX, y: rect.origin.y + dragDiffY, width: rect.width, height: rect.height)
            }
            selectedViewOriginalPoint = event.locationInWindow
            return
        }
        //selectedViewの移動ではなく、lineViewを描画しているとき
        guard temporaryLinePath != nil else { return }
        var diffX: CGFloat = 0
        var diffY: CGFloat = 0
        if drawingMode != .marker && drawingMode != .line && drawingMode != .arrow {
            let locationInView = NSPoint(x: event.locationInWindow.x - self.frame.origin.x, y: event.locationInWindow.y - 2 * self.frame.origin.y)
            var rectX = temporaryOriginalLocation!.x
            var rectY = temporaryOriginalLocation!.y
            diffX = locationInView.x - temporaryOriginalLocation!.x
            diffY = locationInView.y - temporaryOriginalLocation!.y
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
            drawTemporaryLine(locationInWindow: event.locationInWindow)
        case .arrow:
            drawTemporaryArrow(locationInWindow: event.locationInWindow)
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
        if selectedView == nil && temporaryLineView != nil {
            let locationInView = NSPoint(x: event.locationInWindow.x - self.frame.origin.x, y: event.locationInWindow.y - 2 * self.frame.origin.y)
            var temporaryLineViewDic: [String:Any] = [
                "type": drawingMode,
                "index": self.subviews.count - 1,
                "originX": temporaryLineView!.frame.origin.x,
                "originY": temporaryLineView!.frame.origin.y]
            if drawingMode == .line || drawingMode == .arrow {
                var diffX = locationInView.x - temporaryOriginalLocation!.x
                var diffY = locationInView.y - temporaryOriginalLocation!.y
                if shiftKeyIsPressed {
                    if abs(diffX) < abs(diffY) {
                        diffX = 0
                    } else {
                        diffY = 0
                    }
                }
                temporaryLineViewDic.updateValue(temporaryOriginalLocation!.x, forKey: "originX")
                temporaryLineViewDic.updateValue(temporaryOriginalLocation!.y, forKey: "originY")
                temporaryLineViewDic.updateValue(temporaryLinePath!.lineWidth / 2, forKey: "lineWidth")
                temporaryLineViewDic.updateValue(diffX, forKey: "diffX")
                temporaryLineViewDic.updateValue(diffY, forKey: "diffY")
            } else if drawingMode == .marker {
                let points = getPoints(path: temporaryLinePath!)
                temporaryLineViewDic.updateValue(temporaryLinePath!.lineWidth, forKey: "lineWidth")
                temporaryLineViewDic.updateValue(points, forKey: "points")
            } else {
                temporaryLineViewDic.updateValue(temporaryLineView!.frame.width, forKey: "width")
                temporaryLineViewDic.updateValue(temporaryLineView!.frame.height, forKey: "height")
            }
            subviewDics.append(temporaryLineViewDic)
        } else if selectedView != nil {
            let dic = subviewDics[selectedViewIndex]
            if let type = dic["type"] as? DrawingMode, type != .line && type != .arrow {
                subviewDics[selectedViewIndex].updateValue(selectedView!.frame.origin.x, forKey: "originX")
                subviewDics[selectedViewIndex].updateValue(selectedView!.frame.origin.y, forKey: "originY")
            }
        }
        temporaryLinePath = nil
        temporaryLineView = nil
        temporaryOriginalLocation = nil
    }
    
    func getPoints(path: NSBezierPath) -> [NSPoint] {
        var points = [NSPoint](repeating: NSPoint.zero, count: 3)
        var pathPoints = [NSPoint]()
        for i in 0 ..< path.elementCount {
            let element = path.element(at: i, associatedPoints: &points)
            if element == .lineTo {
                pathPoints.append(points[0])
            }
        }
        return pathPoints
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
            if type == .square || type == .circle || type == .label || type == .image {
                let width = dic["width"] as! CGFloat
                let height = dic["height"] as! CGFloat
                let xIsInArea = originX <= locationInView.x && locationInView.x <= originX + width
                let yIsInArea = originY <= locationInView.y && locationInView.y <= originY + height
                if xIsInArea && yIsInArea {
                    self.selectedView = self.subviews[index]
                    self.selectedView?.borderWidth = 2
                    self.selectedView?.borderColor = .green
                    selectedViewIndex = subviewDics.count - 1 - indexOfDic
                    selectedViewType = type
                    return
                }
            } else if type == .marker {
                let points = dic["points"] as! [NSPoint]
                let lineWidth = dic["lineWidth"] as! CGFloat
                var markerViewIsSelected = false
                for i in 0 ..< points.count - 1 {
                    let startPoint = NSPoint(x: originX + points[i].x, y: originY + points[i].y)
                    let endPoint = NSPoint(x: originX + points[i+1].x, y: originY + points[i+1].y)
                    if checkLocationIsNearLine(location: locationInView,
                                               lineOrigin: startPoint,
                                               lineDiff: NSPoint(x: endPoint.x - startPoint.x, y: endPoint.y - startPoint.y),
                                               lineWidth: lineWidth) {
                        self.selectedView = self.subviews[index]
                        selectedViewIndex = subviewDics.count - 1 - indexOfDic
                        selectedViewType = type
                        markerViewIsSelected = true
                        return
                    }
                }
                if markerViewIsSelected {
                    return
                }
            } else if type == .line || type == .arrow {
                let lineWidth = dic["lineWidth"] as! CGFloat
                let diffX = dic["diffX"] as! CGFloat
                let diffY = dic["diffY"] as! CGFloat
                if checkLocationIsNearLine(location: locationInView,
                                           lineOrigin: NSPoint(x: originX, y: originY),
                                           lineDiff: NSPoint(x: diffX, y: diffY),
                                           lineWidth: lineWidth) {
                    self.selectedView = self.subviews[index]
                    selectedViewIndex = subviewDics.count - 1 - indexOfDic
                    selectedViewType = type
                    selectedViewLineWidth = lineWidth
                    selectedViewDiffX = diffX
                    selectedViewDiffY = diffY
                    return
                }
            }
        }
    }
    
    func checkLocationIsNearLine(location: NSPoint, lineOrigin: NSPoint, lineDiff: NSPoint, lineWidth: CGFloat) -> Bool {
        let diffX = lineDiff.x
        let diffY = lineDiff.y
        //直線の開始地点を原点とした時の、locationの座標(x0, y0)
        let x0 = location.x - lineOrigin.x
        let y0 = location.y - lineOrigin.y
        let slopeSignIsPositive = diffX * diffY > 0
        let slope = (abs(diffY) / abs(diffX)) * (slopeSignIsPositive ? 1 : -1)
        var distance = abs(-1 * slope * x0 + y0) / sqrt(1 + pow(slope, 2))
        if diffX == 0 {
            distance = x0
        } else if diffY == 0 {
            distance = y0
        }
        let xIsInArea = {() -> Bool in
            if diffX > 0 {
                return lineOrigin.x - lineWidth <= location.x && location.x <= lineOrigin.x + diffX + lineWidth
            } else {
                return lineOrigin.x + diffX - lineWidth <= location.x && location.x <= lineOrigin.x + lineWidth
            }
        }
        let yIsInArea = {() -> Bool in
            if diffY > 0 {
                return lineOrigin.y - lineWidth <= location.y && location.y <= lineOrigin.y + diffY + lineWidth
            } else {
                return lineOrigin.y + diffY - lineWidth <= location.y && location.y <= lineOrigin.y + lineWidth
            }
        }
        return xIsInArea() && yIsInArea() && distance <= lineWidth
    }
    
    private func drawTemporaryMarker(locationInWindow: NSPoint) {
        let locationInView = NSPoint(x: locationInWindow.x - self.frame.origin.x, y: locationInWindow.y - 2 * self.frame.origin.y)
        temporaryLinePath!.line(to: locationInView)
        temporaryLineView!.needsDisplay = true
    }
    
    private func drawTemporaryLine(locationInWindow: NSPoint) {
        let locationInView = NSPoint(x: locationInWindow.x - self.frame.origin.x, y: locationInWindow.y - 2 * self.frame.origin.y)
        drawLinePath(path: temporaryLinePath!, startPoint: temporaryOriginalLocation!, endPoint: locationInView, isArrow: false)
        temporaryLineView!.needsDisplay = true
    }
    
    private func drawTemporaryArrow(locationInWindow: NSPoint) {
        let locationInView = NSPoint(x: locationInWindow.x - self.frame.origin.x, y: locationInWindow.y - 2 * self.frame.origin.y)
        drawLinePath(path: temporaryLinePath!, startPoint: temporaryOriginalLocation!, endPoint: locationInView, isArrow: true)
        temporaryLineView!.needsDisplay = true
    }
    
    func drawLinePath(path: NSBezierPath, startPoint: NSPoint, endPoint: NSPoint, isArrow: Bool) {
        path.removeAllPoints()
        path.move(to: startPoint)
        var endPoint = endPoint
        if shiftKeyIsPressed {
            let diffX = endPoint.x - startPoint.x
            let diffY = endPoint.y - startPoint.y
            if abs(diffX) < abs(diffY) {
                endPoint = NSPoint(x: startPoint.x, y: endPoint.y)
            } else {
                endPoint = NSPoint(x: endPoint.x, y: startPoint.y)
            }
        }
        path.line(to: endPoint)
        if isArrow {
            let arrowLength: CGFloat = 30
            let radAngle = atan2(endPoint.y - startPoint.y, endPoint.x - startPoint.x)
            let leftAngle = radAngle + (CGFloat.pi * 3 / 4)
            let rightAngle = radAngle - (CGFloat.pi * 3 / 4)
            let leftPoint = NSPoint(x: endPoint.x + arrowLength * cos(leftAngle), y: endPoint.y + arrowLength * sin(leftAngle))
            path.line(to: leftPoint)
            path.move(to: endPoint)
            let rightPoint = NSPoint(x: endPoint.x + arrowLength * cos(rightAngle), y: endPoint.y + arrowLength * sin(rightAngle))
            path.line(to: rightPoint)
        }
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
                self.selectedView?.borderWidth = 0
                imageView.borderWidth = 2
                imageView.borderColor = .green
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
        self.selectedView = nil
        self.selectedViewIndex = 0
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
        selectedView?.borderWidth = 0
        label.borderWidth = 2
        label.borderColor = .green
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
    var selectedViewType: DrawingMode = .square
    var selectedViewLineWidth: CGFloat = 0
    var selectedViewDiffX: CGFloat = 0
    var selectedViewDiffY: CGFloat = 0
    
    func copyView(removeTargetView: Bool) {
        if selectedView != nil {
            copiedType = selectedViewType
            if selectedViewType == .image {
                copiedImageView = NSImageView()
                copiedImageView!.image = (selectedView as! NSImageView).image
                copiedImageView!.imageScaling = .scaleAxesIndependently
                copiedImageView!.frame = (selectedView as! NSImageView).frame
            } else if selectedViewType == .label {
                copiedLabel = NSTextField(labelWithString: (selectedView as! NSTextField).stringValue)
                copiedLabel!.textColor = (selectedView as! NSTextField).textColor
                copiedLabel!.font = (selectedView as! NSTextField).font
                copiedLabel!.layer?.backgroundColor = (selectedView as! NSTextField).layer?.backgroundColor
                copiedLabel!.textColor = (selectedView as! NSTextField).textColor
                copiedLabel!.sizeToFit()
                copiedLabel!.frame = (selectedView as! NSTextField).frame
            } else {
                copiedLineView = LineView()
                copiedLineView!.path = (selectedView as! LineView).path
                copiedLineView!.pathColor = (selectedView as! LineView).pathColor
                copiedLineView!.lineWidth = (selectedView as! LineView).lineWidth
                copiedLineView!.drawingMode = copiedType
                copiedLineView!.fillsShapes = (selectedView as! LineView).fillsShapes
                copiedLineView!.frame = (selectedView as! LineView).frame
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
                copyDic.updateValue(selectedViewLineWidth / 2, forKey: "lineWidth")
                copyDic.updateValue(selectedViewDiffX, forKey: "diffX")
                copyDic.updateValue(selectedViewDiffY, forKey: "diffY")
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
        if selectedView != nil {
            let deletedViewSize = selectedView!.frame.size
            selectedView!.frame.size = NSSize.zero
            behaviorsForUndo.append(.deleteView)
            subviewDics[selectedViewIndex].updateValue(CGFloat.zero, forKey: "width")
            subviewDics[selectedViewIndex].updateValue(CGFloat.zero, forKey: "height")
            deletedIndexesForUndo.append(selectedViewIndex)
            deletedSizeForUndo.append(deletedViewSize)
            selectedView = nil
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
    
    func changeColor() {
        guard selectedView != nil else { return }
        let selectedDic = subviewDics[selectedViewIndex]
        guard let type = selectedDic["type"] as? DrawingMode else { return }
        if type == .label {
            let labelView = self.subviews[selectedViewIndex] as! NSTextField
            labelView.textColor = globalColor
        } else {
            let lineView = self.subviews[selectedViewIndex] as! LineView
            lineView.pathColor = globalColor
            lineView.needsDisplay = true
        }
    }
    
    func changeLabelSize() {
        guard selectedView != nil else { return }
        let selectedDic = subviewDics[selectedViewIndex]
        guard let type = selectedDic["type"] as? DrawingMode else { return }
        if type == .label {
            let label = self.subviews[selectedViewIndex] as! NSTextField
            label.font = .systemFont(ofSize: globalLabelSize)
            label.sizeToFit()
            let width = label.frame.width
            let height = label.frame.height
            let x = selectedDic["originX"] as! CGFloat
            let y = selectedDic["originY"] as! CGFloat
            label.frame = NSRect(x: x, y: y, width: width, height: height)
            subviewDics[selectedViewIndex].updateValue(width, forKey: "width")
            subviewDics[selectedViewIndex].updateValue(height, forKey: "height")
        }
    }
    
    func changeImageSize() {
        guard selectedView != nil else { return }
        let selectedDic = subviewDics[selectedViewIndex]
        guard let type = selectedDic["type"] as? DrawingMode else { return }
        if type == .image {
            let imageView = self.subviews[selectedViewIndex] as! NSImageView
            let width = selectedDic["width"] as! CGFloat
            let height = selectedDic["height"] as! CGFloat
            let x = selectedDic["originX"] as! CGFloat
            let y = selectedDic["originY"] as! CGFloat
            let maxLength: CGFloat = globalImageSize
            let orgSize = NSSize(width: width, height: height)
            let orgRatio = orgSize.height / orgSize.width
            var newSize = CGSize.zero
            if orgSize.width >= orgSize.height {
                newSize.width = maxLength
                newSize.height = maxLength * orgRatio
            } else {
                newSize.height = maxLength
                newSize.width = maxLength / orgRatio
            }
            imageView.frame = NSRect(x: x, y: y, width: newSize.width, height: newSize.height)
            subviewDics[selectedViewIndex].updateValue(newSize.width, forKey: "width")
            subviewDics[selectedViewIndex].updateValue(newSize.height, forKey: "height")
        }
    }
    
    func removeSelectedView() {
        self.selectedView?.borderWidth = 0
        self.selectedView = nil
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
                path!.lineWidth = lineWidth != nil ? lineWidth! : globalLineWidth
                path!.stroke()
            }
        }
    }
}

enum Behavior {
    case addView
    case deleteView
}
