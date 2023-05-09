//
//  GameScene.swift
//  OrangeTree
//
//  Created by Andrew Alsing on 4/27/23.
//

import SpriteKit
import GameplayKit

// had to put this outside of class, self and normal version weren't updating properly
var currentLevel: Int = 0
var score: Int = 0

class GameScene: SKScene {
    var orangeTree: SKSpriteNode!
    var orange: Orange?
    var touchStart: CGPoint = .zero
    var shapeNode = SKShapeNode()
    var boundary = SKNode()
    var numOfLevels: UInt32 = 3
    var scoreLabelNode: SKLabelNode!
    
    override func didMove(to view: SKView) {
        // Connect Game Objects
        orangeTree = childNode(withName: "tree") as? SKSpriteNode
        // Configure shapeNode
        shapeNode.lineWidth = 20
        shapeNode.lineCap = .round
        shapeNode.strokeColor = UIColor(white: 1, alpha: 0.3)
        addChild(shapeNode)
        
        // Set the contact delegate
        physicsWorld.contactDelegate = self
        
        // Setup the boundaries
        boundary.physicsBody = SKPhysicsBody(edgeLoopFrom: CGRect(origin: .zero, size: size))
        let background = childNode(withName: "background") as? SKSpriteNode
        boundary.position = CGPoint(x: (background?.size.width ?? 0) / 2, y: (background?.size.height ?? 0) / 2)
        addChild(boundary)

        // Add the Sun to the scene
        let sun = SKSpriteNode(imageNamed: "Sun")
        sun.name = "sun"
        sun.position.x = size.width / 2 - (sun.size.width * 0.75)
        sun.position.y = size.height / 2 - (sun.size.height * 0.75)
        addChild(sun)
        
        // Score label
        let scoreLabel = self.childNode(withName: "scoreLabel") as! SKLabelNode
        scoreLabelNode = scoreLabel
    }
    
    // Class method to load .sks files
    static func Load(level: Int) -> GameScene? {
      return GameScene(fileNamed: "Level-\(level)")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Get the location of the touch on the screen
        let touch = touches.first!
        let location = touch.location(in: self)
        let scoreLabel = self.childNode(withName: "scoreLabel") as! SKLabelNode

        // Check if the touch was on the Orange Tree
        if atPoint(location).name == "tree" {
            // Create the orange and add it to the scene at the touch location
            orange = Orange()
            orange?.physicsBody?.isDynamic = false
            orange?.position = location
            addChild(orange!)

            // Store the location of the touch
            touchStart = location
        }
        
        // Check whether the sun was tapped and change the level
        for node in nodes(at: location) {
            if node.name == "sun" || node.name == "start" {
                currentLevel += 1
                print(currentLevel)
                
                if let scene = GameScene.Load(level: currentLevel) {
                    scene.scaleMode = .aspectFill
                    if let view = view {
                        view.presentScene(scene)
                    }
                }
            }
        }

    }
    
    // update score text
    override func update(_ currentTime: TimeInterval) {
        // Update the score label's text
        scoreLabelNode.text = "Score: \(score)"
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Get the location of the touch
        let touch = touches.first!
        let location = touch.location(in: self)

        // Update the position of the Orange to the current location
        orange?.position = location
        
        // Draw the firing vector
        let path = UIBezierPath()
        path.move(to: touchStart)
        path.addLine(to: location)
        shapeNode.path = path.cgPath
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Get the location of where the touch ended
        let touch = touches.first!
        let location = touch.location(in: self)

        // Get the difference between the start and end point as a vector
        let dx = (touchStart.x - location.x) * 0.5
        let dy = (touchStart.y - location.y) * 0.5
        let vector = CGVector(dx: dx, dy: dy)

        // Set the Orange dynamic again and apply the vector as an impulse
        orange?.physicsBody?.isDynamic = true
        orange?.physicsBody?.applyImpulse(vector)
        
        // Remove the path from shapeNode
        shapeNode.path = nil
    }
}


extension GameScene: SKPhysicsContactDelegate {
  // Called when the physicsWorld detects two nodes colliding
  func didBegin(_ contact: SKPhysicsContact) {
    let nodeA = contact.bodyA.node
    let nodeB = contact.bodyB.node

    // Check that the bodies collided hard enough
    if contact.collisionImpulse > 15 {
        if nodeA?.name == "skull" {
            score += 150
            removeSkull(node: nodeA!)
            skullDestroyedParticles(point: nodeA!.position)
        } else if nodeB?.name == "skull" {
            score += 150
            removeSkull(node: nodeB!)
            skullDestroyedParticles(point: nodeA!.position)
        }
        print(score)
    }
  }

  // Function used to remove the Skull node from the scene
  func removeSkull(node: SKNode) {
    node.removeFromParent()
  }
}

extension GameScene {
  func skullDestroyedParticles(point: CGPoint) {
      if let explosion = SKEmitterNode(fileNamed: "Explosion") {
        addChild(explosion)
        explosion.position = point
        let wait = SKAction.wait(forDuration: 1)
        let removeExplosion = SKAction.removeFromParent()
        explosion.run(SKAction.sequence([wait, removeExplosion]))
      }
    }
}
