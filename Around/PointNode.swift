//
//  PointNode.swift
//  Around
//
//  Created by sinezeleuny on 05.05.2022.
//

import UIKit
import SceneKit

class PointNode: SCNNode {
    let radius = 0.04
    
    override init() {
        super.init()
        self.geometry = SCNSphere(radius: radius)
    }
    
    init(radius: CGFloat) {
        super.init()
        self.geometry = SCNSphere(radius: radius)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
