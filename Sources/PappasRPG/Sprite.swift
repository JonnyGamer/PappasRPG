
#if !os(macOS)
import UIKit
import SpriteKit
import GameplayKit
import Foundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
}

var w: CGFloat = 1000
let h: CGFloat = 1000

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        if let view = self.view as? SKView {
            w = (UIScreen.main.bounds.size.width / UIScreen.main.bounds.size.height) * 1000
            
            let scene = Scene()
            scene.scaleMode = .aspectFit
            view.presentScene(scene)
            
            view.ignoresSiblingOrder = true
            view.showsFPS = true
            view.showsNodeCount = true
        }
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

protocol Hostable {
    var this: SKNode { get set }
    init()
}

extension SKNode {
    @discardableResult func Sprite(_ named: String) -> Sprite { return sprite(.init(texture: Texture(named))) }
    @discardableResult func Collectable(_ named: String) -> Collectable { return collectable(.init(texture: Texture(named))) }
}

extension Hostable {
    @discardableResult func Collectable(_ named: String) -> Collectable { return this.collectable(.init(texture: Texture(named))) }
    @discardableResult func Collectable(_ sprite: Collectable) -> Collectable { return this.collectable(sprite) }
    @discardableResult func Sprite(_ named: String) -> Sprite { return this.sprite(.init(texture: Texture(named))) }
    @discardableResult func Sprite(_ sprite: Sprite) -> Sprite { return this.sprite(sprite) }
    @discardableResult func Label(_ label: SKLabelNode) -> SKLabelNode { return this.label(label) }
    
    func begin() {}
    func update() {}
    func updateWillEnd() {}
    func touchBegan() {}
    func touchEnded() {}
    mutating func touchMoved(_ moved: CGVector) {}
    func end(_ with: SKAction) { this.run(with) { self.this.removeFromParent() } }
}


var textures = [String:SKTexture]()
func Texture(_ name: String) -> SKTexture {
    if textures[name] == nil {
        textures[name] = SKTexture(imageNamed: name)
    }
    return textures[name]!
}


var mission: Int? = nil
var acceptedMission: Bool? = nil

public func eraseAllData() {
    UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
    UserDefaults.standard.synchronize()
}


class Scene: SKScene {
    var currentTouches: Set<UITouch> = []
    var host = Host()
    
    override init() {
        super.init(size: .init(width: w, height: h))
        anchorPoint = .zero
        backgroundColor = .white
        
        //let host = Host()
        addChild(host.this)
        host.begin()
        host.touchMoved(.zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func detectTouches(_ touches: Set<UITouch>) {
        var nodesFound: Set<SKNode> = []
        for touch in touches {
            currentTouches.insert(touch)
            nodesFound = nodesFound.union(nodes(at: touch.location(in: self)))
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let thisNodes = touches.reduce([SKNode]()) { (foo, bar) -> [SKNode] in
            if bar.phase == .began {
                return foo + nodes(at: bar.location(in: self))
            } else {
                return foo
            }
        }
        
        host.touchBegan(thisNodes)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        host.touchEnded()
    }
    
    override func update(_ currentTime: TimeInterval) {
        host.update()
    }
    
    //override func didFinishUpdate() {
        // let foo = Date().timeIntervalSince1970
        // host.update()
        //let foo2 = Date().timeIntervalSince1970
        //print(1 / (foo2 - foo))
    //}
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for i in touches {
            if i.phase == .moved {
                let loc = i.location(in: self)
                let prevLoc = i.previousLocation(in: self)
                let d = CGVector(dx: (loc.x - prevLoc.x), dy: (loc.y - prevLoc.y))
                host.touchMoved(d)
            }
        }
    }
    
}


// enum Button: Hashable { case left, right, jump, none }
class Touch {
    var touching: [SKNode]
    var touch: UITouch
    init(_ what: UITouch,_ touching: [SKNode]) {
        self.touch = what
        self.touching = touching
    }
    static func ==(lhs: Touch, rhs: Touch) -> Bool {
        lhs.touch === rhs.touch
    }
}


class Sprite: SKSpriteNode, Touchable {
    var myTouches: Set<UITouch> = []
    var draggable = false
    
    var touchBegan: () -> () = {}
    var touchEnded: () -> () = { }
    var touchMoved: () -> () = { }
}

class Collectable: SKSpriteNode, Touchable {
    var myTouches: Set<UITouch> = []
    var draggable = false
    
    var touchBegan: () -> () = {}
    var touchEnded: () -> () = { }
    var touchMoved: () -> () = { }
}


struct SK {
    static var sprite: Sprite.Type { return Sprite.self }
    static var label: SKLabelNode.Type { return SKLabelNode.self }
    static var shape: SKShapeNode.Type { return SKShapeNode.self }
    static var node: SKNode.Type { return SKNode.self }
}


@objc protocol Touchable {
    @objc var touchBegan: () -> () { get set }
    @objc var touchEnded: () -> () { get set }
    @objc var touchMoved: () -> () { get set }
}

extension Touchable {
    @discardableResult
    func onTouchBegan(_ doThis: @escaping (Self) -> ()) -> Self {
        self.touchBegan = { doThis(self) }
        return self
    }
    @discardableResult
    func onTouchEnded(_ doThis: @escaping (Self) -> ()) -> Self {
        self.touchEnded = { doThis(self) }
        return self
    }
    @discardableResult
    func onTouchMoved(_ doThis: @escaping (Self) -> ()) -> Self {
        self.touchMoved = { doThis(self) }
        return self
    }
    
    func touchy(_ touches: Set<UITouch>) {
        
    }
    
}



extension CGSize {
    static var fullScreen: CGSize { return .init(width: w, height: h) }
}
extension CGPoint {
    static var midScreen: CGPoint { return .init(x: w / 2, y: h / 2) }
    static var half: CGPoint { return .init(x: 0.5, y: 0.5) }
}


extension SKNode {
    @discardableResult
    func edit<T: SKNode>(_ this: (T) -> ()) -> T {
        this(self as! T)
        return self as! T
    }
    
    func node<T: SKNode>(_ this: T) -> T {
        addChild(this); return this
    }
    
    func sprite(_ w: Sprite) -> Sprite {
        return node(w)
    }
    
    func collectable(_ w: Collectable) -> Collectable {
        return node(w)
    }
    
    func label(_ w: SKLabelNode) -> SKLabelNode {
        return node(w)
    }
    
    
    
}

extension SKNode: Doable {
    @discardableResult
    func doChildren(_ this: (SKNode) -> ()) -> Self { for i in self.children { this(i) }; return self }
}
protocol Doable { init() }
extension Doable {
    @discardableResult
    func `do`(_ this: (Self) -> ()) -> Self { this(self); return self }
    static func `do`(_ this: (Self) -> ()) -> Self { let foo = self.init(); this(foo); return foo }
}

extension Array where Element: SKNode {
    func `do`(_ this: (Element) -> ()) { for po in self { this(po) } }
    subscript(_ this: String, _ list: String...) -> SKNode? {
        var foo: SKNode? = self.first { $0.name == this }
        for chill in list {
            foo = foo?.children.first { $0.name == chill }
        }
        if foo == nil { print("Warning! self\(list) was not found") }
        return foo
    }
    subscript<T: SKNode>(_ type: T.Type,_ this: String, _ list: String...) -> T? {
        var foo: SKNode? = self.first { $0.name == this }
        for chill in list {
            foo = foo?.children.first { $0.name == chill }
        }
        return foo as? T
    }
}
extension SKNode {
    @discardableResult
    func callAsFunction<T: SKNode>(_ type: T.Type = SKNode.self as! T.Type, _ list: String..., wow: (T) -> ()) -> T? {
        var foo: SKNode? = self
        for chill in list {
            foo = foo?.childNode(withName: chill)
        }
        return foo as? T
    }
    
    func bye() {
        removeFromParent()
    }
}


class SKSwipeNode: SKNode {
    var slip: CGFloat = 0.1
    var width: CGFloat, height: CGFloat
    var bounds: (x: (lesser: CGFloat, greater: CGFloat), y: (lesser: CGFloat, greater: CGFloat))
    var releasable = true
    var touchToDrag = false
    var beganDrag = false
    var badAttempt = false
    static var zero: SKSwipeNode { get { return SKSwipeNode(x: 0, 0, y: 0, 0) } }
    
    /// Initializers
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    init(x lesserX: CGFloat,_ greaterX: CGFloat, y lesserY: CGFloat,_ greaterY: CGFloat) {
        self.bounds = ((lesserX, greaterX), (lesserY, greaterY))
        self.width = greaterX - lesserX
        self.height = greaterY - lesserY
        super.init()
    }
    convenience init(x lesserX: CGFloat,_ greaterX: CGFloat, y lesserY: CGFloat,_ greaterY: CGFloat, releasable: Bool) {
        self.init(x: lesserX, greaterX, y: lesserY, greaterY);
        self.releasable = releasable
    }
    convenience init(x lesserX: CGFloat,_ greaterX: CGFloat) { self.init(x: lesserX, greaterX, y: 0, 0) }
    convenience init(y lesserY: CGFloat,_ greaterY: CGFloat) { self.init(x: 0, 0, y: lesserY, greaterY) }
    
    /// Drag Function
    func drag(_ change: CGVector) {
        if !beganDrag {
            if Int(self.position.x) != Int(min(max(self.position.x, bounds.x.lesser), bounds.x.greater)) { badAttempt = true; return }
            if Int(self.position.y) != Int(min(max(self.position.y, bounds.y.lesser), bounds.y.greater)) { badAttempt = true; return }
            beganDrag = true
            self.removeAction(forKey: "Bound")
        }
        #if os(iOS)
        let inverted: CGFloat = 1.0
        #else
        let inverted: CGFloat = -1.0
        #endif

        if bounds.x.lesser == bounds.x.greater && bounds.y.lesser == bounds.y.greater { return }
        if bounds.x.lesser == bounds.x.greater { self.position.y -= change.dy * inverted; return }
        if bounds.y.lesser == bounds.y.greater { self.position.x += change.dx; return }

        self.position.x += change.dx; self.position.y -= change.dy * inverted
    }
    
    /// Release Fuction
    func release(_ velocity: CGVector) {
        if self.action(forKey: "Bound") != nil { return }
        //if badAttempt { badAttempt = false; return }
        beganDrag = false
        #if os(iOS)
        let inverted: CGFloat = -1.0
        #else
        let inverted: CGFloat = 1.0
        #endif
        
        if bounds.x.lesser == bounds.x.greater && bounds.y.lesser == bounds.y.greater { return }
        if bounds.x.lesser == bounds.x.greater {
            // var v = velocity; v.dx = 0; v.dy *= -1
            self.run(SKAction.sequence(makeEasingActions(CGVector(dx: 0, dy: inverted*velocity.dy))), withKey: "Bound")
            return
        }
        if bounds.y.lesser == bounds.y.greater {
            // var v = velocity; v.dy = 0
            self.run(SKAction.sequence(makeEasingActions(CGVector(dx: velocity.dx, dy: 0))), withKey: "Bound")
            return
        }
        self.run(SKAction.sequence(makeEasingActions(CGVector(dx: velocity.dx, dy: inverted*velocity.dy))), withKey: "Bound")
    }
    
    /// Make Easing Release Action
    func makeEasingActions(_ velocity: CGVector) -> [SKAction] {
        var arr = [SKAction](), track = CGPoint()
        
        if releasable {
            for i in 0..<15 {
                let move = (cos(CGFloat(i) * CGFloat(Double.pi) / 15)/2 + 0.5) / 50
                let x = move * velocity.dx, y = move * velocity.dy
                track.x += x; track.y += y
                arr.append(SKAction.moveBy(x: x, y: y, duration: 0.0333))
            }
        }
        
        let a = bound(CGPoint(x: track.x + self.position.x, y: track.y + self.position.y), 0.25)
        if !a.0.isEmpty { arr.append(SKAction.group(a.0)) }
        return arr
    }
    
    func moveToY(_ to: CGFloat) -> SKAction { return moveToY(to, 0.5) }
    func moveToY(_ to: CGFloat,_ time: CGFloat) -> SKAction {
        let move = SKAction.moveTo(y: to, duration: Double(time))
        move.timingFunction = { simd_smoothstep(0, 1, $0) }
        // move.timingMode = .easeInEaseOut
        return move
    }
    public func moveToX(_ to: CGFloat,_ time: CGFloat) -> SKAction {
        let move = SKAction.moveTo(x: to, duration: Double(time))
        move.timingFunction = { simd_smoothstep(0, 1, $0) }
        // move.timingMode = .easeInEaseOut
        return move
    }
    
    /// Find Bounds for the Release Action
    func bound(_ pos: CGPoint,_ time: CGFloat) -> ([SKAction], CGFloat, CGFloat) {
        var arr = [SKAction](), x = CGFloat(), y = CGFloat()
        if pos.x < bounds.x.lesser { let a = moveToX(bounds.x.lesser, time); a.timingMode = .easeOut; arr.append(a); x = bounds.x.lesser - pos.x }
        if pos.y < bounds.y.lesser { let a = moveToY(bounds.y.lesser, time); a.timingMode = .easeOut; arr.append(a); y = bounds.y.lesser - pos.y }
        if pos.x > bounds.x.greater { let a = moveToX(bounds.x.greater, time); a.timingMode = .easeOut; arr.append(a); x = pos.x - bounds.x.greater }
        if pos.y > bounds.y.greater { let a = moveToY(bounds.y.greater, time); a.timingMode = .easeOut; arr.append(a); y = pos.y - bounds.y.greater }
        return (arr, x, y)
    }
    
    public func fadeTo(_ to: CGFloat) -> SKAction { return fade(to, 1) }
    public func fade(_ to: CGFloat,_ time: CGFloat) -> SKAction {
        let shade = SKAction.fadeAlpha(to: to, duration: Double(time))
        shade.timingMode = .easeInEaseOut
        return shade
    }
    
    /// Fade Into View
    func fadeToView(to toX: CGFloat,_ toY: CGFloat, by byX: CGFloat,_ byY: CGFloat) {
        let to = CGPoint(x: toX, y: toY)
        var action = SKAction.move(to: to, duration: 0.7)
        let a = bound(to, 0.7); if !a.0.isEmpty { action = SKAction.group(a.0) }
        action.timingMode = .easeOut
        
        self.do {
            $0.position = .init(x: toX + a.1 + byX, y: toY + a.2 + byY)
            $0.alpha = 0
        }
        self.run(action)
        self.run(fade(1, 0.7), withKey: "Fading")
    }
    
}

//
//extension SKSwipeNode {
//
//    func pinchBounds(
//        _ scale: CGFloat,
//        _ small: Bool, _ smallScale: CGFloat,
//        _ large: Bool, _ largeScale: CGFloat,
//        _ xBound: (lesser: CGFloat, greater: CGFloat),
//        _ yBound: (lesser: CGFloat, greater: CGFloat)) {
//
//        var scalage: CGFloat = scale
//        let pnch = (self.parent as? RootNode)?.startingPinchSize ?? 1
//        let origin = (self.parent as? RootNode)?.mazeOrigin ?? CGPoint()
//        let pinchCenter = (self.parent as? RootNode)?.pinchCenter ?? CGPoint()
//
//        if small && scale < 1 {
//            scalage = smallScale / pnch
//        } else if large && scale > 1 {
//            scalage = largeScale / pnch
//        }
//        self.position = CGPoint(
//            x: ((origin.x - pinchCenter.x) * scalage) + pinchCenter.x,
//            y: ((origin.y - pinchCenter.y) * scalage) + pinchCenter.y)
//        self.setScale(pnch * scale)
//        self.bounds.x = xBound
//        self.bounds.y = yBound
//    }
//
//}

#endif
