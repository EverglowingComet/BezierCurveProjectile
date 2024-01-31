//
//  BezierCurveView.swift
//  BezierCurve
//
//  Created by Comet on 1/31/24.
//

import UIKit
import Foundation

class BezierData {
    var startPoint: CGPoint = CGPoint(x: 0.8, y: 0.9)
    var endPoint: CGPoint = CGPoint(x: 0.1, y: 0.3)
    
    var coordX: [CGFloat] = [0,0,0]
    var coordY: [CGFloat] = [0,0,0]
    var pointCount: Int = 10
    
    func copy() -> BezierData {
        let result = BezierData()
        
        result.startPoint = startPoint
        
        return result
    }
}

class BezierCurve: UIView {
    public static var data = BezierData()
    
    public dynamic var progress: CGFloat = 0 {
        didSet {
            bezierLayer.progress = progress
        }
    }
    
    fileprivate var bezierLayer: BezierLayer {
        return layer as! BezierLayer
    }
    
    override public class var layerClass: AnyClass {
        return BezierLayer.self
    }

    func isEmpty () -> Bool {
        return bezierLayer.isEmpty()
    }
    
    func setPoints(points: [CGPoint]) {
        for i in 0..<3 {
            BezierCurve.data.coordX[i] = points[i].x
            BezierCurve.data.coordY[i] = points[i].y
        }
        bezierLayer.setNeedsDisplay()
    }
    
    func setSeedPoint(point: CGPoint) {
        BezierCurve.data.coordX[1] = point.x
        BezierCurve.data.coordY[1] = point.y
        
        bezierLayer.setNeedsDisplay()
    }
    
    func setProgress(update: CGFloat) {
        progress = update
        bezierLayer.progress = update
        bezierLayer.setNeedsDisplay()
    }
    
    override func layoutSubviews() {
        if frame.width > 0 && frame.height > 0 && isEmpty() {
            BezierCurve.data = BezierData()
            let points = [
                CGPoint(x: BezierCurve.data.startPoint.x * frame.width, y: BezierCurve.data.startPoint.y * frame.height),
                CGPoint(x: (BezierCurve.data.startPoint.x - (BezierCurve.data.startPoint.x - BezierCurve.data.endPoint.x) * 0.5) * frame.width, y: (BezierCurve.data.startPoint.y - (BezierCurve.data.startPoint.y - BezierCurve.data.endPoint.y) * 0.5) * frame.height),
                CGPoint(x: BezierCurve.data.endPoint.x * frame.width, y: BezierCurve.data.endPoint.y * frame.height),
            ]
            setPoints(points: points)
        }
    }
    
    override func action(for layer: CALayer, forKey event: String) -> CAAction? {
        if event == #keyPath(BezierLayer.progress),
                    let action = action(for: layer, forKey: #keyPath(backgroundColor)) as? CAAnimation,
                    let animation: CABasicAnimation = (action.copy() as? CABasicAnimation) {
            animation.keyPath = #keyPath(BezierLayer.progress)
            animation.fromValue = bezierLayer.progress
            animation.toValue = progress
            self.layer.add(animation, forKey: #keyPath(BezierLayer.progress))
            return animation
        }
        return super.action(for: layer, forKey: event)
    }
}

fileprivate class BezierLayer: CALayer {
    
    @NSManaged var progress: CGFloat
    
    private func bq0(t: CGFloat) -> CGFloat {
        return pow(t, 2) * pow(1 - t, 0)
    }
    
    private func bq1(t: CGFloat) -> CGFloat {
        return pow(t, 1) * pow(1 - t, 1)
    }
    
    private func bq2(t: CGFloat) -> CGFloat {
        return pow(t, 0) * pow(1 - t, 2)
    }
    
    override class func needsDisplay(forKey key: String) -> Bool {
        if key == #keyPath(progress) {
            return true
        }
        return super.needsDisplay(forKey: key)
    }

    func isEmpty () -> Bool {
        return BezierCurve.data.coordX[0] == 0 && BezierCurve.data.coordX[1] == 0 && BezierCurve.data.coordX[2] == 0 && BezierCurve.data.coordY[0] == 0 && BezierCurve.data.coordY[1] == 0 && BezierCurve.data.coordY[2] == 0
    }
    
    func setProgress(update: CGFloat) {
        progress = update
    }
    
    func getPoint(t: CGFloat) -> CGPoint {
        var x: CGFloat = 0
        var y: CGFloat = 0
        
        if t >= 0 && t <= 1 && !isEmpty() {
            x = BezierCurve.data.coordX[2] * bq0(t: t) + BezierCurve.data.coordX[1] * bq1(t: t) + BezierCurve.data.coordX[0] * bq2(t: t)
            y = BezierCurve.data.coordY[2] * bq0(t: t) + BezierCurve.data.coordY[1] * bq1(t: t) + BezierCurve.data.coordY[0] * bq2(t: t)
        }
        print("4444444", t, BezierCurve.data.coordX, BezierCurve.data.coordY)
        
        return CGPoint(x: x, y: y)
    }
    
    func getPoints() -> [CGPoint] {
        var result = [CGPoint]()
        let step = CGFloat(progress) / CGFloat(BezierCurve.data.pointCount - 1)
        for i in 0..<BezierCurve.data.pointCount {
            result.append(getPoint(t: CGFloat(i) * step))
        }
        return result
    }
    
    func getStartPoint() -> CGPoint {
        return CGPoint(x: BezierCurve.data.startPoint.x * frame.width, y: BezierCurve.data.startPoint.y * frame.height)
    }
    
    func getEndPoint() -> CGPoint {
        return CGPoint(x: BezierCurve.data.endPoint.x * frame.width, y: BezierCurve.data.endPoint.y * frame.height)
    }
    
    func getLinePoint() -> CGPoint {
        return CGPoint(x: (BezierCurve.data.startPoint.x - (BezierCurve.data.startPoint.x - BezierCurve.data.endPoint.x) * progress) * frame.width, y: (BezierCurve.data.startPoint.y - (BezierCurve.data.startPoint.y - BezierCurve.data.endPoint.y) * progress) * frame.height)
    }
    
    override func draw(in ctx: CGContext) {
        super.draw(in: ctx)
        
        UIGraphicsPushContext(ctx)
        
        let points = getPoints()
        
        ctx.beginPath()
        ctx.setLineWidth(8)
        ctx.move(to: getStartPoint())
        ctx.addLine(to: getLinePoint())
        ctx.setStrokeColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.6))
        ctx.strokePath()
        
        ctx.setLineWidth(8)
        ctx.setStrokeColor(CGColor.init(red: 1, green: 0, blue: 0, alpha: 0.6))
        ctx.beginPath()
        ctx.move(to: points[0])
        for i in 1..<points.count {
            ctx.addLine(to: points[i])
        }
        ctx.strokePath()
        
        ctx.beginPath()
        ctx.addArc(center: getStartPoint(), radius: 10, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        ctx.fillPath()
        
        ctx.beginPath()
        ctx.addArc(center: getEndPoint(), radius: 10, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        ctx.fillPath()
        
        ctx.beginPath()
        ctx.addArc(center: points[points.count - 1], radius: 10, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
        ctx.setFillColor(CGColor(red: 0, green: 1, blue: 1, alpha: 1))
        ctx.fillPath()
        
        UIGraphicsPopContext()
    }
}
