//
//  GameViewController.swift
//  Super-Cool_Race-v2
//
//  Created by Miles Richmond on 4/28/24.
//

import UIKit
import QuartzCore
import SceneKit

class GameViewController: UIViewController, SCNSceneRendererDelegate {
    var currentCar: Car!
    let colorableComponents: [String] = ["NIS59_body_0","NIS105_body_0","NIS43_body_0","NIS19_body_0","NIS34_body_0"]
    
    var cameraNode: SCNNode!
    
    var carBehavior: SCNPhysicsVehicle!
    var carNode: SCNNode!
    var speedometer: UILabel!
    
    var timer: UILabel!
    var lastTime: UILabel!
    var timeDifference: UILabel!
    var counter: Int = 0
    var timeHistory: [Int] = []
    var isOnFinish: Bool = false
    
    // 0: none, 1: forward, 2: reverse
    var throttle: UInt8 = 0
    var brakes: Bool = false
    // 0: none, 1: left, 2: right
    var steer: UInt8 = 0 // No need for an extra big number
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Future implementations may involve the other characteristics of the car, but for now its just color
        if let pastCar = UserDefaults.standard.data(forKey: "savedCarColor") {
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode([CGFloat].self, from: pastCar) {
                currentCar = Car.getBasicCar()
                currentCar.color1 = .init(red: decoded[0], green: decoded[1], blue: decoded[2], alpha: 1)
            }
        }
        
        if(currentCar == nil) {
            currentCar = Car.getBasicCar()
        }
        
        setupSpeedometer()
        setupTimer()
        setupControls()
        
        let mapScene = setupScene()
        
        setupVehicle(mapScene)
        
        let scnView = self.view as! SCNView
        scnView.delegate = self
        scnView.scene = mapScene
        scnView.allowsCameraControl = false
        scnView.showsStatistics = false
        scnView.backgroundColor = UIColor.black
    }
    
    func renderer(_ renderer: any SCNSceneRenderer, didSimulatePhysicsAtTime time: TimeInterval) {
        updateSpeedometer(speed: carBehavior.speedInKilometersPerHour)
        updateTimer()
        let speed = abs(carBehavior.speedInKilometersPerHour)
        
        checkFinishLine(carNode.presentation.position)
        
        if(brakes) {
            carBehavior.applyBrakingForce(currentCar.brakingForce, forWheelAt: 0)
            carBehavior.applyBrakingForce(currentCar.brakingForce, forWheelAt: 1)
            carBehavior.applyBrakingForce(currentCar.brakingForce, forWheelAt: 2)
            carBehavior.applyBrakingForce(currentCar.brakingForce, forWheelAt: 3)
        } else {
            carBehavior.applyBrakingForce(0, forWheelAt: 0)
            carBehavior.applyBrakingForce(0, forWheelAt: 1)
            carBehavior.applyBrakingForce(0, forWheelAt: 2)
            carBehavior.applyBrakingForce(0, forWheelAt: 3)
        }
        
        let throttlePower = (((speed + 1) / 150) * currentCar.engineForce) + currentCar.engineForce
        switch(throttle) {
        case 1:
            carBehavior.applyEngineForce(throttlePower, forWheelAt: 0)
            carBehavior.applyEngineForce(throttlePower, forWheelAt: 1)
            carBehavior.applyEngineForce(throttlePower, forWheelAt: 2)
            carBehavior.applyEngineForce(throttlePower, forWheelAt: 3)
        case 2:
            carBehavior.applyEngineForce(-1 * throttlePower / 2, forWheelAt: 0)
            carBehavior.applyEngineForce(-1 * throttlePower / 2, forWheelAt: 1)
            carBehavior.applyEngineForce(-1 * throttlePower / 2, forWheelAt: 2)
            carBehavior.applyEngineForce(-1 * throttlePower / 2, forWheelAt: 3)
        default:
            carBehavior.applyEngineForce(0, forWheelAt: 0)
            carBehavior.applyEngineForce(0, forWheelAt: 1)
            carBehavior.applyEngineForce(0, forWheelAt: 2)
            carBehavior.applyEngineForce(0, forWheelAt: 3)
        }
        
        
        var angle: CGFloat!
        if(speed < 10) {
            angle = currentCar.steeringAngle * (13 / pow(10 / 4, 2))
        } else {
            angle = currentCar.steeringAngle * (12 / pow(speed / 4, 2))
        }
        
        switch(steer) {
        case 0:
            carBehavior.setSteeringAngle(0, forWheelAt: 0)
            carBehavior.setSteeringAngle(0, forWheelAt: 1)
        case 1:
            carBehavior.setSteeringAngle(angle, forWheelAt: 0)
            carBehavior.setSteeringAngle(angle, forWheelAt: 1)
        case 2:
            carBehavior.setSteeringAngle(-1 * angle, forWheelAt: 0)
            carBehavior.setSteeringAngle(-1 * angle, forWheelAt: 1)
        default:
            print("This shouldn't happen, something is horribly wrong")
        }
    }
    
    func setupScene() -> SCNScene {
        let mapScene = SCNScene(named: "art.scnassets/BlankMap.scn")!
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 100, z: 0)
        mapScene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        mapScene.rootNode.addChildNode(ambientLightNode)
        
        return mapScene
    }
    
    func setupVehicle(_ scene: SCNScene) {
        // add chassisNode
        let chassisScene = SCNScene(named: "art.scnassets/NISSAN-GTR/NISSAN-GTR.scn")!
        carNode = chassisScene.rootNode.childNode(withName: "RootNode", recursively: true)!
        
        carNode.position = .init(-73, 1, -37)
        carNode.physicsBody = currentCar.physicsBody
        
        for comp in colorableComponents {
            carNode.childNode(withName: comp, recursively: true)!.geometry?.materials[0].diffuse.contents = currentCar.color1
        }
        
        scene.rootNode.addChildNode(carNode)
        
        // Vehicle Behavior Setup
        let driverFront: SCNPhysicsVehicleWheel = .init(node: carNode.childNode(withName: "DF", recursively: true)!)
        let driverRear: SCNPhysicsVehicleWheel = .init(node: carNode.childNode(withName: "DR", recursively: true)!)
        let passengerFront: SCNPhysicsVehicleWheel = .init(node: carNode.childNode(withName: "PF", recursively: true)!)
        let passengerRear: SCNPhysicsVehicleWheel = .init(node: carNode.childNode(withName: "PR", recursively: true)!)
        
        driverFront.connectionPosition = driverFront.node.convertPosition(SCNVector3Zero, to: carNode)
        driverRear.connectionPosition = driverRear.node.convertPosition(SCNVector3Zero, to: carNode)
        passengerFront.connectionPosition = passengerFront.node.convertPosition(SCNVector3Zero, to: carNode)
        passengerRear.connectionPosition = passengerRear.node.convertPosition(SCNVector3Zero, to: carNode)
        
        
        
        // Closest possible length that doesn't have any rubbing with the chassis
        let restLength = 0.2
        driverFront.suspensionRestLength = restLength
        driverRear.suspensionRestLength = restLength
        passengerFront.suspensionRestLength = restLength
        passengerRear.suspensionRestLength = restLength
        
        carBehavior = .init(chassisBody: carNode.physicsBody!, wheels: [driverFront, passengerFront, driverRear, passengerRear])
        
        scene.physicsWorld.addBehavior(carBehavior)
        
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        carNode.addChildNode(cameraNode)
        cameraNode.position = .init(0, 2, -5)
        cameraNode.rotation = SCNVector4Make(0, 1, 0, Float.pi)
        cameraNode.look(at: .init(-72.811, 1, -36.781))
        cameraNode.camera!.zFar = 1000
    }
    
    func setupControls() {
        let gasButton = UIButton(type: .system)
        gasButton.frame = CGRect(x: 100, y: 100, width: 100, height: 100)
        gasButton.setTitle("GAS", for: .normal)
        //gasButton.setImage(UIImage(named: "gasPedal-removebg-preview.png"), for: .normal)
        gasButton.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2)
        gasButton.addTarget(self, action: #selector(applyThrottle), for: .touchDown)
        gasButton.addTarget(self, action: #selector(releaseThrottle), for: .touchUpInside)
        gasButton.addTarget(self, action: #selector(releaseThrottle), for: .touchUpOutside)
        self.view.addSubview(gasButton)
        gasButton.frame.origin.x = 700
        gasButton.frame.origin.y = 290
        
        let reverseButton = UIButton(type: .system)
        reverseButton.frame = CGRect(x: 100, y: 100, width: 100, height: 100)
        reverseButton.setTitle("REVERSE", for: .normal)
        reverseButton.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2)
        reverseButton.addTarget(self, action: #selector(applyReverseThrottle), for: .touchDown)
        reverseButton.addTarget(self, action: #selector(releaseThrottle), for: .touchUpInside)
        reverseButton.addTarget(self, action: #selector(releaseThrottle), for: .touchUpOutside)
        self.view.addSubview(reverseButton)
        reverseButton.frame.origin = .init(x: 460, y: 290)
        
        let breakButton = UIButton(type: .system)
        breakButton.frame = CGRect(x: 100, y: 100, width: 100, height: 100)
        breakButton.setTitle("BRAKE", for: .normal)
        //breakButton.setImage(UIImage(named: "breaker-removebg-preview.png"), for: .normal)
        breakButton.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2)
        breakButton.addTarget(self, action: #selector(applyBrake), for: .touchDown)
        breakButton.addTarget(self, action: #selector(releaseBrake), for: .touchUpInside)
        breakButton.addTarget(self, action: #selector(releaseBrake), for: .touchUpOutside)
        self.view.addSubview(breakButton)
        breakButton.frame.origin.x = 580
        breakButton.frame.origin.y = 290
        
        let leftButton = UIButton(type: .system)
        leftButton.frame = CGRect(x: 50, y: 50, width: 100, height: 100)
        leftButton.setTitle("LEFT", for: .normal)
        leftButton.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2)
        leftButton.addTarget(self, action: #selector(steerLeft), for: .touchDown)
        leftButton.addTarget(self, action: #selector(releaseSteer), for: .touchUpInside)
        leftButton.addTarget(self, action: #selector(releaseSteer), for: .touchUpOutside)
        self.view.addSubview(leftButton)
        leftButton.frame.origin.x = 20
        leftButton.frame.origin.y = 290
        
        let rightButton = UIButton(type: .system)
        rightButton.frame = CGRect(x: 50, y: 50, width: 100, height: 100)
        rightButton.setTitle("RIGHT", for: .normal)
        rightButton.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2)
        rightButton.addTarget(self, action: #selector(steerRight), for: .touchDown)
        rightButton.addTarget(self, action: #selector(releaseSteer), for: .touchUpInside)
        rightButton.addTarget(self, action: #selector(releaseSteer), for: .touchUpOutside)
        self.view.addSubview(rightButton)
        rightButton.frame.origin.x = 120
        rightButton.frame.origin.y = 290
        
        let changeCarButton = UIButton(type: .system)
        changeCarButton.frame = CGRect(x: 50, y: 50, width: 100, height: 40)
        changeCarButton.setTitle("Adjust Car", for: .normal)
        changeCarButton.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        changeCarButton.addTarget(self, action: #selector(changeCar), for: .touchDown)
        self.view.addSubview(changeCarButton)
        changeCarButton.frame.origin = .init(x: 400, y: 0)
    }
    
    func setupSpeedometer() {
        speedometer = UILabel(frame: .init(x: 200, y: 0, width: 200, height: 60))
        speedometer.textColor = .white
        speedometer.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        view.addSubview(speedometer)
    }
    func updateSpeedometer(speed: CGFloat) {
        DispatchQueue.main.async {
            self.speedometer.text = "\(Int(speed.rounded())) kph"
        }
    }
    
    func setupTimer() {
        timer = UILabel(frame: .init(x: 0, y: 0, width: 200, height: 30))
        timer.textColor = .white
        timer.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        timer.textAlignment = .center
        timer.font = UIFont.boldSystemFont(ofSize: 16)
        view.addSubview(timer)
        
        lastTime = .init(frame: .init(x: 0, y: 30 , width: 100, height: 30))
        lastTime.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        lastTime.textColor = .white
        lastTime.textAlignment = .right
        view.addSubview(lastTime)
        
        timeDifference = .init(frame: .init(x: 100, y: 30, width: 100, height: 30))
        timeDifference.textColor = .red
        timeDifference.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        view.addSubview(timeDifference)
    }
    func updateTimer() {
        DispatchQueue.main.async { [self] in
            self.counter += 1
            updateTime(label: timer, time: self.counter)
            updateTime(label: lastTime, time: self.timeHistory.last ?? 0)
            
            if(timeHistory.count == 2) {
                let difference = timeHistory.last! - timeHistory.first!
                timeHistory.remove(at: 0)
                updateTime(label: timeDifference, time: abs(difference))
                if(difference > 0) {
                    timeDifference.text = "+\(timeDifference.text!)"
                    timeDifference.textColor = .red
                } else {
                    timeDifference.text = "-\(timeDifference.text!)"
                    timeDifference.textColor = .green
                }
            }
        }
    }
    func updateTime(label: UILabel, time: Int) {
        let minutes = (time / 6000) % 60
        let seconds = (time / 100) % 60
        let milliseconds = time % 100
        
        label.text = String(format: "%02d:%02d:%02d", minutes, seconds, milliseconds)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .landscapeLeft
    }
    
    @objc func applyThrottle() {
        throttle = 1
    }
    @objc func releaseThrottle() {
        throttle = 0
    }
    @objc func applyReverseThrottle() {
        throttle = 2
    }
    
    @objc func applyBrake() {
        brakes = true
    }
    @objc func releaseBrake() {
        brakes = false
    }
    
    @objc func steerRight() {
        steer = 2
    }
    @objc func steerLeft() {
        steer = 1
    }
    @objc func releaseSteer() {
        steer = 0
    }
    
    @objc func changeCar() {
        let ac = UIAlertController(title: "Change Car Color", message: "RGB format (0-255)", preferredStyle: .alert)
        ac.addTextField()
        ac.addTextField()
        ac.addTextField()
        
        ac.textFields?[0].placeholder = "Red"
        ac.textFields?[1].placeholder = "Green"
        ac.textFields?[2].placeholder = "Blue"
        
        let noticeAC = UIAlertController(title: "Restart Needed", message: "To apply changes, restart the app", preferredStyle: .alert)
        noticeAC.addAction(.init(title: "Ok", style: .default))
        
        let okAction: UIAlertAction = .init(title: "Save", style: .default, handler: { _ in
            let redStr: String = ac.textFields?[0].text ?? "0"
            let greenStr: String = ac.textFields?[1].text ?? "0"
            let blueStr: String = ac.textFields?[2].text ?? "0"
            
            let red = CGFloat(Int(redStr) ?? 0)
            let green = CGFloat(Int(greenStr) ?? 0)
            let blue = CGFloat(Int(blueStr) ?? 0)
            
            self.currentCar.color1 = .init(red: red, green: green, blue: blue, alpha: 1)
            
            let encoder = JSONEncoder()
            if let encoded = try? encoder.encode([red,green,blue]) {
                UserDefaults.standard.set(encoded, forKey: "savedCarColor")
            }
            
            self.present(noticeAC, animated: true)
        })
        
        let cancelAction: UIAlertAction = .init(title: "Cancel", style: .cancel)
        
        ac.addAction(cancelAction)
        ac.addAction(okAction)
        
        present(ac, animated: true)
    }
    
    func checkFinishLine(_ pos: SCNVector3) {
        if(pos.x < -73.5 + 12.5 && pos.x > -73.5 - 12.5) {
            if(pos.z < -19 + 3.75 && pos.z > -19 - 3.75) {
                if(!isOnFinish) {
                    if(timeHistory.count == 0) {
                        counter = 0
                    }
                    isOnFinish = true
                    timeHistory.append(counter)
                    counter = 0
                }
                return
            }
        }
        
        isOnFinish = false
    }
}
