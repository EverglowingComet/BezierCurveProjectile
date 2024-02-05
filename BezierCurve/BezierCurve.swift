//
//  BezierCurveView.swift
//  BezierCurve
//
//  Created by Comet on 1/31/24.
//

import UIKit
import Foundation

class BezierData {
    var startPoint: CGPoint = CGPoint(x: 0.8, y: 0.5)
    var endPoint: CGPoint = CGPoint(x: 0.2, y: 0.4)
    var seedPoint: CGPoint = CGPoint(x: 0.5, y: 0.6)
    
    var pointCount: Int = 10
    var frame: CGRect = CGRect()
    
    func copy() -> BezierData {
        let result = BezierData()
        
        result.startPoint = startPoint
        
        return result
    }
    
    func setFrame(update: CGRect) {
        frame = update
    }
    
    func getStartPoint() -> CGPoint {
        return CGPoint(x: startPoint.x * frame.width, y: startPoint.y * frame.height)
    }
    
    func getEndPoint() -> CGPoint {
        return CGPoint(x: endPoint.x * frame.width, y: endPoint.y * frame.height)
    }
    
    func getSeedPoint() -> CGPoint {
        return CGPoint(x: seedPoint.x * frame.width, y: seedPoint.y * frame.height)
    }
    
    private func bq0(t: CGFloat) -> CGFloat {
        return pow(t, 2) * pow(1 - t, 0)
    }
    
    private func bq1(t: CGFloat) -> CGFloat {
        return pow(t, 1) * pow(1 - t, 1)
    }
    
    private func bq2(t: CGFloat) -> CGFloat {
        return pow(t, 0) * pow(1 - t, 2)
    }
    
    func isEmpty () -> Bool {
        if frame.isEmpty {
            return true
        }
        return getStartPoint().x == 0 && getSeedPoint().x == 0 && getEndPoint().x == 0 && getStartPoint().y == 0 && getSeedPoint().y == 0 && getEndPoint().y == 0
    }
    
    func getPoint(t: CGFloat) -> CGPoint {
        var x: CGFloat = 0
        var y: CGFloat = 0
        
        if t >= 0 && t <= 1 && !isEmpty() {
            x = getEndPoint().x * bq0(t: t) + getSeedPoint().x * bq1(t: t) + getStartPoint().x * bq2(t: t)
            y = getEndPoint().y * bq0(t: t) + getSeedPoint().y * bq1(t: t) + getStartPoint().y * bq2(t: t)
        }
        
        return CGPoint(x: x, y: y)
    }
    
    func getPoints(progress: CGFloat) -> [CGPoint] {
        var result = [CGPoint]()
        let step = CGFloat(progress) / CGFloat(pointCount - 1)
        for i in 0..<pointCount {
            result.append(getPoint(t: CGFloat(i) * step))
        }
        return result
    }
    
    func getLinePoint(progress: CGFloat) -> CGPoint {
        return CGPoint(x: (startPoint.x - (startPoint.x - endPoint.x) * progress) * frame.width, y: (startPoint.y - (startPoint.y - endPoint.y) * progress) * frame.height)
    }
    
    func getPointsArray(progress: CGFloat) -> [Float] {
        var result = [Float]()
        
        for item in getPoints(progress: progress) {
            result.append(Float(item.x))
            result.append(Float(item.y))
        }
        
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
        return BezierCurve.data.isEmpty()
    }
    
    func setSeedPoint(point: CGPoint) {
        BezierCurve.data.seedPoint.x = point.x / frame.width
        BezierCurve.data.seedPoint.y = point.y / frame.height
        
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
            BezierCurve.data.setFrame(update: frame)
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
    
    override class func needsDisplay(forKey key: String) -> Bool {
        if key == #keyPath(progress) {
            return true
        }
        return super.needsDisplay(forKey: key)
    }

    func setProgress(update: CGFloat) {
        progress = update
    }
    
    override func draw(in ctx: CGContext) {
        super.draw(in: ctx)
        
        UIGraphicsPushContext(ctx)
        
        let points = BezierCurve.data.getPoints(progress: progress)
        
        ctx.beginPath()
        ctx.setLineWidth(8)
        ctx.move(to: BezierCurve.data.getStartPoint())
        ctx.addLine(to: BezierCurve.data.getLinePoint(progress: progress))
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
        ctx.addArc(center: BezierCurve.data.getStartPoint(), radius: 10, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        ctx.fillPath()
        
        ctx.beginPath()
        ctx.addArc(center: BezierCurve.data.getEndPoint(), radius: 10, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        ctx.fillPath()
        
        ctx.beginPath()
        ctx.addArc(center: points[points.count - 1], radius: 10, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
        ctx.setFillColor(CGColor(red: 0, green: 1, blue: 1, alpha: 1))
        ctx.fillPath()
        
        UIGraphicsPopContext()
    }
}
