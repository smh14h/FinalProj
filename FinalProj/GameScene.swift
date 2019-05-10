//
//  GameScene.swift
//  FinalProj
//
//  Created by Sean Halstead on 4/17/19.
//  Copyright © 2019 Sean Halstead. All rights reserved.
//

import SpriteKit
import GameplayKit

struct PhysicsCategory {
    static let none      : UInt32 = 0
    static let all       : UInt32 = UInt32.max
    static let player    : UInt32 = 0b11
    static let monster   : UInt32 = 0b1
    static let projectile: UInt32 = 0b10
}

func +(left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func -(left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func *(point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func /(point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

extension CGPoint {
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    
    func normalized() -> CGPoint {
        return self / length()
    }
}

class GameScene: SKScene {
    
    var contentCreated = false
    var score = UILabel(frame: CGRect(x: 10, y: 40, width: 230, height: 21))
    let player = SKSpriteNode(imageNamed: "player")
    var enemies = [SKSpriteNode]()
    var enemiesdefeated = 0
    let enemySpeed = CGFloat(1.0)
    let moveJoystick = TLAnalogJoystick(withDiameter: 100)
    
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    
    var joystickStickImageEnabled = true {
        didSet {
            let image = joystickStickImageEnabled ? UIImage(named: "jStick") : nil
            moveJoystick.handleImage = image
        }
    }
    
    var joystickSubstrateImageEnabled = true {
        didSet {
            let image = joystickSubstrateImageEnabled ? UIImage(named: "jSubstrate") : nil
            moveJoystick.baseImage = image
        }
    }
    
    override func didMove(to view: SKView) {
        
        if (!self.contentCreated) {
            self.createContent()
            self.contentCreated = true
        }
        
        //MARK: Handlers begin
        
        moveJoystick.on(.move) { [unowned self] joystick in
            
            let pVelocity = joystick.velocity;
            let speed = CGFloat(0.12)
            
            self.player.position = CGPoint(x: self.player.position.x + (pVelocity.x * speed), y: self.player.position.y + (pVelocity.y * speed))
        }
        
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self as SKPhysicsContactDelegate
        // Create shape node to use during mouse interaction
//        let w = (self.size.width + self.size.height) * 0.05
//        self.spinnyNode = SKShapeNode.init(rectOf: CGSize.init(width: w, height: w), cornerRadius: w * 0.3)
//
//        if let spinnyNode = self.spinnyNode {
//            spinnyNode.lineWidth = 2.5
//
//            spinnyNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi), duration: 1)))
//            spinnyNode.run(SKAction.sequence([SKAction.wait(forDuration: 0.5),
//                                              SKAction.fadeOut(withDuration: 0.5),
//                                              SKAction.removeFromParent()]))
//        }
        
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run(addMonster),
                SKAction.wait(forDuration: 1.0)
                ])
        ))
    }
    
    func createContent() {
        player.position = CGPoint(x: size.width/2, y: size.height/2)
        
        let moveJoystickHiddenArea = TLAnalogJoystickHiddenArea(rect: CGRect(x: 0, y: 0, width: frame.midX / 2, height: frame.midY - 40))
        moveJoystickHiddenArea.joystick = moveJoystick
        moveJoystick.isMoveable = true
        
        addChild(moveJoystickHiddenArea)
        addMonster()
        
        addChild(player)
        
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width/5) // 1
        player.physicsBody?.isDynamic = true // 2
        player.physicsBody?.categoryBitMask = PhysicsCategory.player // 3
        player.physicsBody?.contactTestBitMask = PhysicsCategory.monster // 4
        player.physicsBody?.collisionBitMask = PhysicsCategory.none // 5
        
        let keptscore = "Goblins Defeated: 0"
        score.text = keptscore
        score.textColor = .white
        self.view?.addSubview(score)
        
    }
    
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    func addMonster() {
        
        // Create sprite
        if enemies.isEmpty {
            for _ in 0...enemiesdefeated {
            
                let monster = SKSpriteNode(imageNamed: "enemy")
                
                // Determine where to spawn the monster along the Y axis
                let Y = random(min: monster.size.height/2, max: size.height - monster.size.height/2)
                
                // Position the monster slightly off-screen along the right edge,
                // and along a random position along the Y axis as calculated above
                monster.position = CGPoint(x: size.width + monster.size.width/2, y: Y)
                
                // Add the monster to the scene
                addChild(monster)

                monster.physicsBody = SKPhysicsBody(circleOfRadius: monster.size.width/5) // 1
                monster.physicsBody?.isDynamic = true // 2
                monster.physicsBody?.categoryBitMask = PhysicsCategory.monster // 3
                monster.physicsBody?.contactTestBitMask = PhysicsCategory.projectile // 4
                monster.physicsBody?.collisionBitMask = PhysicsCategory.none // 5
                
                enemies.append(monster)
            }
        }
    }
    
    func touchDown(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.green
            self.addChild(n)
        }
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.blue
            self.addChild(n)
        }
    }
    
    func touchUp(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.red
            self.addChild(n)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let label = self.label {
            label.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
        }
        
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        
        let touchLocation = touch.location(in: self)
        
        // 2 - Set up initial location of projectile
        let projectile = SKSpriteNode(imageNamed: "Rock")
        projectile.position = player.position
        
        projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2)
        projectile.physicsBody?.isDynamic = true
        projectile.physicsBody?.categoryBitMask = PhysicsCategory.projectile
        projectile.physicsBody?.contactTestBitMask = PhysicsCategory.monster
        projectile.physicsBody?.collisionBitMask = PhysicsCategory.none
        projectile.physicsBody?.usesPreciseCollisionDetection = true
        
        // 3 - Determine offset of location to projectile
        let offset = touchLocation - projectile.position
        
        // 5 - OK to add now - you've double checked position
        addChild(projectile)
        
        // 6 - Get the direction of where to shoot
        let direction = offset.normalized()
        
        // 7 - Make it shoot far enough to be guaranteed off screen
        let shootAmount = direction * 1000
        
        // 8 - Add the shoot amount to the current position
        let realDest = shootAmount + projectile.position
        
        // 9 - Create the actions
        let actionMove = SKAction.move(to: realDest, duration: 2.0)
        let actionMoveDone = SKAction.removeFromParent()
        projectile.run(SKAction.sequence([actionMove, actionMoveDone]))
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        let location = player.position
        
        for enemy in enemies {
            //Aim
            let dx = (location.x) - enemy.position.x
            let dy = (location.y) - enemy.position.y
            let angle = atan2(dy, dx)
            
            enemy.zRotation = angle - 3 * .pi/2
            
            //Seek
            let velocityX = cos(angle) * enemySpeed
            let velocityY = sin(angle) * enemySpeed
            
            enemy.position.x += velocityX
            enemy.position.y += velocityY
        }
    }
    
    func projectileDidCollideWithMonster(projectile: SKSpriteNode, monster: SKSpriteNode) {
        
        print("Hit")
        projectile.removeFromParent()
        monster.removeFromParent()
        if let index = enemies.index(of: monster) {
            enemies.remove(at: index)
        }
        print(enemies)
        
        enemiesdefeated += 1
        score.text = "Goblins Defeated: " + String(enemiesdefeated)
    }
    
    func monsterDidCollideWithPlayer(player: SKSpriteNode, monster: SKSpriteNode) {
        let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
        let gameOverScene = GameOverScene(size: self.size, points: enemiesdefeated)
        view?.presentScene(gameOverScene, transition: reveal)
    }
}

extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        // 1
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if ((firstBody.categoryBitMask & PhysicsCategory.monster != 0) &&
            (secondBody.categoryBitMask & PhysicsCategory.player != 2)) {
            if let monster = firstBody.node as? SKSpriteNode,
                let player = secondBody.node as? SKSpriteNode {
                monsterDidCollideWithPlayer(player: player, monster: monster)
            }
        }
        
        // 2
        if ((firstBody.categoryBitMask & PhysicsCategory.monster != 0) &&
            (secondBody.categoryBitMask & PhysicsCategory.projectile != 0)) {
            if let monster = firstBody.node as? SKSpriteNode,
                let projectile = secondBody.node as? SKSpriteNode {
                projectileDidCollideWithMonster(projectile: projectile, monster: monster)
            }
        }
    }
}
