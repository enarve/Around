//
//  MapView.swift
//  Around
//
//  Created by sinezeleuny on 22.04.2022.
//

import UIKit
import SceneKit

class MapView: UIView {
    
    // line constants
    var lineColor = #colorLiteral(red: 0.9053438902, green: 0.9053438902, blue: 0.9053438902, alpha: 1)
    var lineWidth = 2.0
    
    // when user stops tracing manually
    var additionalLineColor = #colorLiteral(red: 0.9053438902, green: 0.9053438902, blue: 0.9053438902, alpha: 1)
//    var additionalLineProximityToFirstPoint = 0.1
    lazy var additionalLineStep = 1.0 //* (10.0 / coefficient)
    
    // starting point constants
    var firstPointColor = UIColor.white
    var firstPointDiameter = 4.0
    
    // various constants
    var coefficientDifference = 0.2
    var directionVectorMultiplier = 5.0
    
    // view constants
    var safeSpaceDivider = 10.0
    var cornerRadius = 18.0
    
    var points: [SCNVector3] = [] { didSet { setNeedsLayout(); setNeedsDisplay() }}
    
    // coefficient changes itself whith the scale of the map
    var coefficient: Double = 10.0
    
    lazy var zeroPoint = CGPoint(x: bounds.midX, y: bounds.midY)
    var withBlurEffect = false { didSet { setNeedsLayout(); setNeedsDisplay() }}

    var tracingManuallyStopped = false { didSet { if tracingManuallyStopped == true {
        setNeedsLayout(); setNeedsDisplay()
    } }}
    
    override func draw(_ rect: CGRect) {
        backgroundColor = .clear
        
        if !withBlurEffect {
            let bar = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius)
            let color = UIColor.lightGray
            color.setFill()
            bar.fill()
        }

        // zeroPoint calculating
        let safeSpace = CGSize(width: bounds.width / safeSpaceDivider, height: bounds.height / safeSpaceDivider)
        let numberOfPoints = points.count
        var xLeftBorderPoint: SCNVector3? = nil
        var xRightBorderPoint: SCNVector3? = nil
        var yLeftBorderPoint: SCNVector3? = nil
        var yRightBorderPoint: SCNVector3? = nil
        
        if points.count >= 2 {
            let directionVector = points[numberOfPoints-2].subtractedFrom(points[numberOfPoints-1]).multipliedBy(Float(directionVectorMultiplier))
            
            for point in points {
                let pointOrigin = CGPoint(x: zeroPoint.x + coefficient * CGFloat(point.x), y: zeroPoint.y + coefficient * CGFloat(point.z))
                
                if pointOrigin.x <= bounds.minX + safeSpace.width {
                    xLeftBorderPoint = point
                }
                if pointOrigin.x >= bounds.maxX - safeSpace.width {
                    xRightBorderPoint = point
                }
                if pointOrigin.y <= bounds.minY + safeSpace.height {
                    yLeftBorderPoint = point
                }
                if pointOrigin.y >= bounds.maxY - safeSpace.height {
                    yRightBorderPoint = point
                }
            }
            
            if xLeftBorderPoint == nil {
                if directionVector.x >= 0 {
                    zeroPoint = CGPoint(x: zeroPoint.x - CGFloat(directionVector.x), y: zeroPoint.y)
                }
            }
            if xRightBorderPoint == nil {
                if directionVector.x <= 0 {
                    zeroPoint = CGPoint(x: zeroPoint.x - CGFloat(directionVector.x), y: zeroPoint.y)
                }
            }
            if yLeftBorderPoint == nil {
                if directionVector.z >= 0 {
                    zeroPoint = CGPoint(x: zeroPoint.x , y: zeroPoint.y - CGFloat(directionVector.z))
                }
            }
            if yRightBorderPoint == nil {
                if directionVector.z <= 0 {
                    zeroPoint = CGPoint(x: zeroPoint.x, y: zeroPoint.y - CGFloat(directionVector.z))
                }
            }
        }
        
        // scale coefficient calculating
        for point in points {
            let pointOrigin = CGPoint(x: zeroPoint.x + coefficient * CGFloat(point.x), y: zeroPoint.y + coefficient * CGFloat(point.z))
            if pointOrigin.x <= bounds.minX + lineWidth || pointOrigin.x >= bounds.maxX - lineWidth || pointOrigin.y <= bounds.minY + lineWidth || pointOrigin.y >= bounds.maxY - lineWidth {
                coefficient -= coefficientDifference
            }
        }
        
        // drawing 'curve' on a map
        for point in points {
            let i = points.firstIndex(of: point)
            if i != 0 {
                let origin = CGPoint(x: zeroPoint.x + coefficient * CGFloat(point.x), y: zeroPoint.y + coefficient * CGFloat(point.z))
                let circle = UIBezierPath(ovalIn: CGRect(origin: origin, size: CGSize(width: lineWidth, height: lineWidth)))
                lineColor.setFill()
                circle.fill()
            }
        }
        
        // drawing additional line if tracing stopped by users intent
        if tracingManuallyStopped {
            if var ghostPoint = points.last {
                let xDist = ghostPoint.x
                let zDist = ghostPoint.z
                let ghostLength = ghostPoint.length()
                var numberOfGhostPoints = ghostLength / additionalLineStep
                if numberOfGhostPoints < 3 {
                    numberOfGhostPoints = 3
                }
                print("xDist, zDist: ", xDist, zDist)
                repeat {
                    ghostPoint = SCNVector3(x: ghostPoint.x - xDist / Float(numberOfGhostPoints), y: ghostPoint.y, z: ghostPoint.z - zDist / Float(numberOfGhostPoints))
                    let origin = CGPoint(x: zeroPoint.x + coefficient * CGFloat(ghostPoint.x), y: zeroPoint.y + coefficient * CGFloat(ghostPoint.z))
                    let circle = UIBezierPath(ovalIn: CGRect(origin: origin, size: CGSize(width: lineWidth, height: lineWidth)))
                    additionalLineColor.setFill()
                    circle.fill()
                } while (ghostPoint.length() >= additionalLineStep)
            }
        }
        
        // drawing the first point with accent color
        if let firstPoint = points.first {
            let origin = CGPoint(x: zeroPoint.x + coefficient * CGFloat(firstPoint.x), y: zeroPoint.y + coefficient * CGFloat(firstPoint.z))
            let circle = UIBezierPath(ovalIn: CGRect(origin: origin, size: CGSize(width: firstPointDiameter, height: firstPointDiameter)))
            firstPointColor.setFill()
            circle.fill()
        }
        
        
    }
    
}
