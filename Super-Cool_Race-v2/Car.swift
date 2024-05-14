//
//  Car.swift
//  Super-Cool_Race-v2
//
//  Created by Miles Richmond on 5/10/24.
//

import Foundation
import SceneKit

struct Car {
    static var modelPath: String = "art.scnassets/NISSAN-GTR/NISSAN-GTR.scn"
    var color1: UIColor
    
    var steeringAngle: CGFloat
    var engineForce: CGFloat
    var brakingForce: CGFloat
    
    var physicsBody: SCNPhysicsBody
    
    init(color1: UIColor, handling: Handling, characteristics chara: Characteristics) {
        self.color1 = color1
        self.steeringAngle = handling.steeringAngle
        self.engineForce = handling.engineForce
        self.brakingForce = handling.brakingForce
        
        physicsBody = .dynamic()
        physicsBody.mass = chara.mass
        physicsBody.restitution = chara.restitution
        physicsBody.friction = chara.friction
        physicsBody.rollingFriction = chara.rollingFriction
    }
    
    static func getBasicCar() -> Car {
        let color: UIColor = .white
        let handling: Handling = .init(
            steeringAngle: 0.1,
            engineForce: 200,
            brakingForce: 1
        )
        let character: Characteristics = .init(
            mass: 1000,
            restitution: 0.1,
            friction: 0.5,
            rollingFriction: 0
        )
        
        return .init(color1: color, handling: handling, characteristics: character)
    }
}

struct Handling {
    var steeringAngle: CGFloat
    var engineForce: CGFloat
    var brakingForce: CGFloat
}

struct Characteristics {
    var mass: CGFloat
    var restitution: CGFloat
    var friction: CGFloat
    var rollingFriction: CGFloat
}
