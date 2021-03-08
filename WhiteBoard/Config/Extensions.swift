//
//  Extensions.swift
//  justpaint
//
//  Created by 秋泉 on 2021/02/08.
//

import Cocoa

extension NSView {
    
    func drawRecursively() {
        self.draw(self.frame)
        for subview in self.subviews {
            subview.drawRecursively()
        }
    }
    
    @IBInspectable var backgroundColor: NSColor? {
        get {
            guard let layer = self.layer, let backgroundColor = layer.backgroundColor else { return nil }
            return NSColor(cgColor: backgroundColor)
        }
        set {
            wantsLayer = true
            layer?.backgroundColor = newValue?.cgColor
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        get {
            guard let layer = layer else {return 0}
            return layer.borderWidth
        }
        set {
            wantsLayer = true
            layer?.borderWidth = newValue
        }
    }
    
    @IBInspectable var borderColor: NSColor? {
        get {
            guard let layer = self.layer, let borderColor = layer.borderColor else { return nil }
            return NSColor(cgColor: borderColor)
        }
        set {
            wantsLayer = true
            layer?.borderColor = newValue?.cgColor
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat {
        get {
            guard let layer = layer else {return 0}
            return layer.cornerRadius
        }
        set {
            wantsLayer = true
            layer?.cornerRadius = newValue
        }
    }
    
}

extension NSBezierPath {
  var cgPath: CGPath {
    let path = CGMutablePath()
    var points = [CGPoint](repeating: .zero, count: 3)
    for i in 0 ..< self.elementCount {
      let type = self.element(at: i, associatedPoints: &points)
      switch type {
      case .moveTo:
        path.move(to: points[0])
      case .lineTo:
        path.addLine(to: points[0])
      case .curveTo:
        path.addCurve(to: points[2], control1: points[0], control2: points[1])
      case .closePath:
        path.closeSubpath()
      @unknown default:
        break
      }
    }
    return path
  }
}
