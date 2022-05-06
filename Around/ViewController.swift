//
//  ViewController.swift
//  Around
//
//  Created by sinezeleuny on 15.04.2022.
//

import UIKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    // MARK: IB
    
    @IBOutlet weak var arView: ARSCNView!
    @IBOutlet weak var restartButton: UIButton!
    @IBAction func restart(_ sender: UIButton) {
        resetTracking()
    }
    @IBOutlet weak var infoView: UIVisualEffectView!
    @IBOutlet weak var infoLabel: UILabel!
    
    @IBOutlet weak var perimeterView: UIVisualEffectView!
    @IBOutlet weak var perimeterLabel: UILabel!
    
    @IBOutlet weak var areaView: UIVisualEffectView!
    @IBOutlet weak var areaLabel: UILabel!
    
    // MARK: Properties and methods
    
    var tracingOnMessage = "Tracing..."
    var tracingOffMessage = "Tracing stopped"
    var stopTracingAlertTitle = "Stop tracing?"
    var stopTracingAlertMessage = "Area will be calculated and shown for current trajectory"
    var stopTracingButtonText = "Stop"
    var stopTracingCancelButtonText = "Cancel"
//    var crossingTitle = "Warning"
//    var crossingMessage = "Area may be miscalculated when crossings are made"
    var step: Double = 0.1
    var finalStep: Double = 0.15
    
    var mapView: MapView!
    
    private var points: [SCNVector3] = [] {
        didSet {
            mapView.points = points
        }
    }
    private var pause: Bool = false
    
    enum DistanceValues {
        case meters
        case feet
        case kilometers
    }
    var distanceValue: DistanceValues = .meters
    
    private var perimeter: Double = 0.0
    private func getPerimeterString() -> String {
        switch distanceValue {
        case .meters:
            return "Perimeter: \(String(format: "%.2f", perimeter)) m"
        case .feet:
            return "Perimeter: \(String(format: "%.2f", perimeter * 3.28084)) ft"
        case .kilometers:
            return "Perimeter: \(String(format: "%.4f", perimeter / 1000)) km"
        }
    }
    
    enum AreaUnits {
        case msquared
        case ftsquared
        case acres
        case hectares
    }
    var areaUnit: AreaUnits = .msquared
    
    private var area: Double = 0.0
    private func getAreaString() -> String {
        switch areaUnit {
        case .msquared:
            return "Area: \(String(format: "%.3f", area)) m²"
        case .ftsquared:
            return "Area: \(String(format: "%.3f", area * 10.7639)) ft²"
        case .acres:
            return "Area: \(String(format: "%.6f", area / 4046.86)) ac"
        case .hectares:
            return "Area: \(String(format: "%.6f", area / 10000)) ha"
        }
    }
    
    @objc private func changeAreaValue() {
        switch areaUnit {
        case .msquared:
            areaUnit = .ftsquared
        case .ftsquared:
            areaUnit = .acres
        case .acres:
            areaUnit = .hectares
        case .hectares:
            areaUnit = .msquared
        }
        areaLabel.text = getAreaString()
    }
    
    @objc private func changeDistanceValue() {
        switch distanceValue {
        case .meters:
            distanceValue = .feet
        case .feet:
            distanceValue = .kilometers
        case .kilometers:
            distanceValue = .meters
        }
        perimeterLabel.text = getPerimeterString()
    }
    
    private func stopTracing() {
        // // Concerning intercrossing, o(n2)
//        var showCrossingAlert = false
//
//        for point in points[1..<points.count] {
//            let i = points.firstIndex(of: point)
//            for anotherPoint in points[1..<points.count] {
//                let j = points.firstIndex(of: anotherPoint)
//                if i != j && point.subtractedFrom(anotherPoint).length() < step {
//                    showCrossingAlert = true
//                }
//            }
//        }
//        if showCrossingAlert {
//            let ac = UIAlertController(title: crossingTitle, message: crossingMessage, preferredStyle: .alert)
//            ac.addAction(UIAlertAction(title: "Ok", style: .default))
//            ac.view.layoutIfNeeded()
//            self.present(ac, animated: true)
//        }
        
        print("Finish")
        pause = true
        infoLabel.text = tracingOffMessage
        calculateArea()
        
        areaLabel.text = getAreaString()
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            self?.areaView.alpha = 1
        })
        for node in arView.scene.rootNode.childNodes {
            if let node = node as? PointNode {
                node.removeFromParentNode()
            }
        }
    }
    
    @objc private func askStopTracing() {
        if pause == false {
            let ac = UIAlertController(title: stopTracingAlertTitle, message: stopTracingAlertMessage, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: stopTracingButtonText, style: .default, handler: {[weak self] _ in
                if let firstPoint = self?.points.first, let lastPoint = self?.points.last {
                    self?.perimeter += firstPoint.subtractedFrom(lastPoint).length()
                    self?.perimeterLabel.text = self?.getPerimeterString()
                }
                self?.mapView.tracingManuallyStopped = true
                self?.stopTracing()}))
            ac.addAction(UIAlertAction(title: stopTracingCancelButtonText, style: .cancel))
            ac.view.layoutIfNeeded()
            self.present(ac, animated: true)
        }
    }
    
    private func calculateArea() {
        var a = Float(0.0)
        var b = Float(0.0)
        for point in points {
            let i = points.firstIndex(of: point)! + 1
            if i != points.count {
                a += points[i-1].x * -points[i].z
                b -= points[i].x * -points[i-1].z
            }
        }
        let c = points.last!.x * -points.first!.z - points.first!.x * -points.last!.z
        let d = a + b + c
        let s = Double(1/2 * abs(d))
        area = s
    }
    
    // MARK: Layout
    private func setupMapView() {
        mapView = MapView()
        
        // Adding blurEffect
        if !UIAccessibility.isReduceTransparencyEnabled {
            mapView.withBlurEffect = true
            let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            blurEffectView.backgroundColor = .clear
            blurEffectView.clipsToBounds = true
            blurEffectView.layer.cornerRadius = 18.0
            arView.addSubview(blurEffectView)
            arView.addSubview(mapView)
            blurEffectView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([NSLayoutConstraint(item: blurEffectView, attribute: .width, relatedBy: .equal, toItem: mapView, attribute: .width, multiplier: 1, constant: 0),
                                         NSLayoutConstraint(item: blurEffectView, attribute: .height, relatedBy: .equal, toItem: mapView, attribute: .height, multiplier: 1, constant: 0),
                                         NSLayoutConstraint(item: blurEffectView, attribute: .leading, relatedBy: .equal, toItem: mapView, attribute: .leading, multiplier: 1, constant: 0),
                                         NSLayoutConstraint(item: blurEffectView, attribute: .bottom, relatedBy: .equal, toItem: mapView, attribute: .bottom, multiplier: 1, constant: 0)])
        } else {
            mapView.withBlurEffect = false
        }
        
        // Constraints
        mapView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([mapView.widthAnchor.constraint(equalToConstant: CGFloat(150)),
                                     mapView.heightAnchor.constraint(equalToConstant: CGFloat(150)),
                                     NSLayoutConstraint(item: mapView!, attribute: .leading, relatedBy: .equal, toItem: arView.safeAreaLayoutGuide, attribute: .leading, multiplier: 1, constant: 15),
                                     NSLayoutConstraint(item: mapView!, attribute: .bottom, relatedBy: .equal, toItem: arView.safeAreaLayoutGuide, attribute: .bottom, multiplier: 1, constant: -15)])
    }
    
    // MARK: VCLC
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMapView()
        
        arView.delegate = self
        arView.session.delegate = self
//        arView.debugOptions = [.showWorldOrigin]
        
        restartButton.layer.cornerRadius = 6.0
        
        infoLabel.text = tracingOnMessage
        areaView.alpha = 0
        
        let areaTap = UITapGestureRecognizer(target: self, action: #selector(changeAreaValue))
        areaView.addGestureRecognizer(areaTap)
        
        let perimeterTap = UITapGestureRecognizer(target: self, action: #selector(changeDistanceValue))
        perimeterView.addGestureRecognizer(perimeterTap)
        
        let tracingTap = UITapGestureRecognizer(target: self, action: #selector(askStopTracing))
        infoView.addGestureRecognizer(tracingTap)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        arView.session.run(configuration)
        let node = PointNode()
        node.position = SCNVector3(x: 0, y: 0, z: 0)
        arView.scene.rootNode.addChildNode(node)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    // MARK: ARView Session
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if !pause {
            if let _ = arView.pointOfView?.position {
                let position = SCNVector3(x: arView.pointOfView!.position.x, y: 0.0, z: arView.pointOfView!.position.z)
                if let lastPoint = points.last {
                    let difference = position.subtractedFrom(lastPoint).length()
                    if Double(difference) >= step {
                        perimeter += difference
                        let distanceFromStart = /*SCNVector3(x: points.first!.x - position.x, y: 0.0, z: points.first!.z - position.z).length()*/ position.subtractedFrom(points.first!).length()
                        if Double(distanceFromStart) >= finalStep || Double(points.count) < 2 * finalStep / step {
                            points.append(position)
                            print("Point added: ", position)
                            perimeterLabel.text = getPerimeterString()
                        } else {
                            stopTracing()
                        }
                    }
                } else {
                    points.append(SCNVector3(x: 0.0, y: 0.0, z: 0.0))
                    print("First position added"/*, position*/)
                }
            }
        }
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        if pause == false {
            resetTracking()
        }
    }
    
    private func resetTracking() {
        print("To reset")
        
        points = []
        perimeter = 0.0
        area = 0.0
        mapView.coefficient = 10.0
        mapView.zeroPoint = CGPoint(x: mapView.bounds.midX, y: mapView.bounds.midY)
        mapView.tracingManuallyStopped = false
        let configuration = ARWorldTrackingConfiguration()
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        pause = false
        
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            self?.areaView.alpha = 0
        })
        
        infoLabel.text = tracingOnMessage
        perimeterLabel.text = getPerimeterString()
        areaLabel.text = getAreaString()
        
        let node = PointNode()
        node.position = SCNVector3(x: 0, y: 0, z: 0)
        arView.scene.rootNode.addChildNode(node)
    }

}

// MARK: - Extensions

extension SCNVector3: Equatable {
    public static func == (lhs: SCNVector3, rhs: SCNVector3) -> Bool {
        (lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z)
    }
    
    func length() -> CGFloat {
        return CGFloat(sqrt(self.x * self.x + self.y * self.y + self.z * self.z))
    }
    
    func addedTo(_ vector: SCNVector3) -> SCNVector3 {
        return SCNVector3(x: self.x + vector.x, y: self.y + vector.y, z: self.z + vector.z)
    }
    
    func subtractedFrom(_ vector: SCNVector3) -> SCNVector3 {
        return SCNVector3(x: -self.x + vector.x, y: -self.y + vector.y, z: -self.z + vector.z)
    }
    
    func multipliedBy(_ number: Float) -> SCNVector3 {
        return SCNVector3(x: number * self.x , y: number * self.y, z: number * self.z )
    }
    
    func scalarWith(_ vector: SCNVector3) -> CGFloat {
        return CGFloat(self.x * vector.x + self.y * vector.y + self.z * vector.z)
    }
}
