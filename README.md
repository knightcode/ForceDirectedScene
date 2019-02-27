# ForceDirectedScene

[![CI Status](https://img.shields.io/travis/knightcode/ForceDirectedScene.svg?style=flat)](https://travis-ci.org/knightcode/ForceDirectedScene)
[![Version](https://img.shields.io/cocoapods/v/ForceDirectedScene.svg?style=flat)](https://cocoapods.org/pods/ForceDirectedScene)
[![License](https://img.shields.io/cocoapods/l/ForceDirectedScene.svg?style=flat)](https://cocoapods.org/pods/ForceDirectedScene)
[![Platform](https://img.shields.io/cocoapods/p/ForceDirectedScene.svg?style=flat)](https://cocoapods.org/pods/ForceDirectedScene)

A solution for the n-body problem on a collection of nodes. This library computes the necessary forces to produce a force directed graph in a SpriteKit scene. Only the repulsive/attractive forces amongst the charges on each node are simulated. `SKPhysicsJointSpring` should be used to add spring forces for links.

## Installation

ForceDirectedScene is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'ForceDirectedScene'
```
## Usage

### Step 1: Implement ForceBody Protocol

Implement the `ForceBody` protocol on your data model. We ship this protocol so that you're no required to provide a list of `SKNode`s with attached `SKPhysicsBody`s

```swift
protocol ForceBody {
    var position: CGPoint { get }
    var charge: CGFloat { get }
    func applyForce(force: CGVector)
}
```

Example: say your nodes are instances of a class `MyNode`, which stores an `SKNode` in a property, `skNode`, to render in your SpriteKit scene. Then you could implement the protocol as:

```swift
extension MyNode: ForceBody {

    public var position: CGPoint {
        get {
            return self.skNode.position
        }
    }
    public var charge: CGFloat {
        get {
            if let physics = self.skNode.physicsBody {
                return physics.charge
            }
            return 0.0
        }
    }
    
    public func applyForce(force: CGVector) {
        self.skNode.physicsBody?.applyForce(force)
    }
}
```

### Step 2: Setup the physicsBody on each node

You're free to set up your scene using all the tools SpriteKit has to offer. If you share the charge property of the physicsBody through the protocol to ForceDirectedGraph, your nodes can simultaneously be affected by electric fields and their mutual replusion or attraction. Also, the barnes-hut algorithm uses a quad tree to speed up simulation, which requires the bounds of your forced directed graph to be explicitly defined, so that we recommend setting constraints to confine the movement of your nodes to whatever bounds you define.

We also suggest setting a strong `linearDamping` property.

```swift
for node in mynodes {
   node.skNode = SKShapeNode( ... )
   node.skNode.positition = CGPoint( ... )
   node.skNode.physicsBody = SKPhysicsBody(circleOfRadius: 10.0)
   node.skNode.physicsBody?.isDynamic = true
   node.physicsBody?.charge = 5.5
   node.physicsBody?.linearDamping = 1.3
   
   node.skNode.constraints = [
       SKConstraint.positionX(SKRange(lowerLimit: 0, upperLimit: self.view.bounds.width)),
       SKConstraint.positionY(SKRange(lowerLimit: 0, upperLimit: self.view.bounds.height))
   ]
   
   scene.addChild(node.skNode)
}
```

### Step 3: Setup Spring Joints for Links

You can model the links in your force directed graph with spring joints. For example:
```swift
for link in links {
    let src = link.sourceSKNode
    let dest = link.destinationSKNode
    let spring = SKPhysicsJointSpring.joint(withBodyA: src.physicsBody!, bodyB: dest.physicsBody!, anchorA: src.position, anchorB: dest.position)
     spring.damping = 10.0
     spring.frequency = 0.25

     scene.physicsWorld.add(spring)
}
```
(Note that you probably also want to create an `SKShapeNode` for each link to render a line between src and dest)

### Step 4: Create the ForceDirectedGraph in your SKSceneDelegate

The `ForceDirectedGraph` constructor has two required arguments, (1) the bounds of graph's display area and (2) an array of objects conforming to the `ForceBody` protocol
```swift
fdGraph = ForceDirectedGraph(bounds: self.view.bounds, nodes: mynodes)
```

Then, call the graph's update method in the `SKSceneDelegate`'s update method:
```swift
func update(_ currentTime: TimeInterval, for scene: SKScene) {
    fdGraph.update()
}
```

It's also probable that you'll want to update the position of your links' `SKShapeNode`s. We suggest doing that in the `didApplyConstraints` method:
```swift
func didApplyConstraints(for scene: SKScene) {
    var path: UIBezierPath
    for link in links {
        let src = link.sourceSKNode
        let dest = link.destinationSKNode
        let lineNode = link.skNode
        path = UIBezierPath()
        path.move(to: src.position)
        path.addLine(to: dest.position)
            
        lineNode.path = path.cgPath
    }
}
```

## API
### ForceBody

Property | Description
---------|------------
**position** | a getter that must return the node's current position in the scene
**charge** | a getter that must return the charge of the current node. This does not have to be the same charge of SKPhysicsBody. It can be postive or negative. Similar charges repel one another. Dissimilar charges attract.
**applyForce** | a function that must ultimately pass the supplied force to the `applyForce` method of the SKPhysicsBody for each node

### ForceDirectedGraph

Public Property | Description
---------|------------
**theta** | Threshold value for Barnes-Hut algorithm. Low values improve simulation accuracy at higher computational cost. High values speed up simulation.
**maxDistance** | The maximum distance at which two nodes can have an affect upon one another. Nodes farther apart than this distance will artificially no longer influence the force applied to each other.
**minDistance** | The minimum distance required between two nodes for each to affect the other. Nodes closer than this distance will stop having an affect upon each other.
**center?** | a point around which all nodes should attempt to cluster. When not nil, causes the application of an additional constant force to each node, directing the node to the defined center. If either of the `x` or `y` coordinates of `center` are set such that `CGFloat.isFinite` is false, the force will not be applied along that cardinal direction, e.g. a center of CGPoint(x: 50.0, y: CGFloat.infinity) will cause the nodes to cluster around the vertical line at x = 50.0.
**centeringStrength** | defines the strength of the force applied to each node while moving it to its clustering point/line
**bounds** | a CGRect that defines the maximum boundaries of the force directed graph scene. Undefined behavior will result if your scene pushes the nodes beyond these bounds.
**update()** | method that must be called periodically to update the simuation, usually in an SKSceneDelegate method.
**init()** | accepts initializers for each of these properties. See below.

Each of these can be passed to the constructor as well. The default values defined in the signature are:
```swift
public init(bounds: CGRect,
            nodes: Array<ForceBody>,
            theta: CGFloat = 0.5,
            min: CGFloat = 0.0,
            max: CGFloat = CGFloat.infinity,
            center: CGPoint? = nil,
            centeringStrength: CGFloat = 0.0002)
```

## Author

Dylan Knight, knightcode1@yahoo.com

## License

ForceDirectedScene is available under the MIT license. See the LICENSE file for more info.
