//
//  ForceDirectedGraph.swift
//  ForceDirectedScene
//
//  Created by Dylan Knight on 2/05/10.
//  Copyright © 2019 Dylan Knight. All rights reserved.
//

import Foundation

public protocol ForceBody: QuadTreeElement {
    var position: CGPoint { get }
    var charge: CGFloat { get }

    func applyForce(force: CGVector)
}

func == (lhs: ForceBodyNode, rhs: ForceBodyNode) -> Bool {
    return lhs === rhs
}

public func == (lhs: QuadTreeElement, rhs: QuadTreeElement) -> Bool {
    return lhs === rhs
}

class ForceBodyNode: QuadTreeElement, Equatable {
    var force: CGVector
    var data: ForceBody
    
    var position: CGPoint {
        get {
            return data.position
        }
    }
    var charge: CGFloat {
        get {
            return data.charge
        }
    }
    
    init(data: ForceBody) {
        self.data = data
        force = CGVector(dx: 0, dy: 0)
    }
}

public class ForceDirectedGraph {
    
    private static let JIGGLE_THRESHOLD: CGFloat = 0.1

    public var centeringStrength: CGFloat
    public var theta: CGFloat
    public var maxDistance: CGFloat
    public var minDistance: CGFloat
    public var center: CGPoint?
    
    private var nodes: Array<ForceBodyNode>
    private var quadTree: QuadTree<ForceBodyNode>
    private var toRestructure: Array<ForceBodyNode>
    
    public var bounds: CGRect {
        get {
            return quadTree.root.bounds
        }
    }

    public init(bounds: CGRect, nodes: Array<ForceBody>, theta: CGFloat = 0.5, min: CGFloat = 0.0, max: CGFloat = CGFloat.infinity,
                center: CGPoint? = nil, centeringStrength: CGFloat = 0.0002) {
        self.centeringStrength = centeringStrength
        self.theta = theta
        self.minDistance = min
        self.maxDistance = max
        self.center = center
        self.nodes = []
        self.nodes.reserveCapacity(nodes.count)
        self.toRestructure = []
        self.toRestructure.reserveCapacity(nodes.count)
        for n in nodes {
            self.nodes.append(ForceBodyNode(data: n))
        }
        quadTree = QuadTree(bounds: bounds, bodies: self.nodes)
    }
    
    public func update () {

        quadTree.computeCenters()
        runBarnesHut()
        
        toRestructure.removeAll(keepingCapacity: true)
        quadTree.forEach { (node: ForceBodyNode, quad: Quad<ForceBodyNode>) in
            node.data.applyForce(force: node.force)
            if !quad.bounds.contains(node.position) {
                toRestructure.append(node)
            }
        }
        
        for node in toRestructure {
            quadTree.remove(element: node)
        }
        for node in toRestructure {
            quadTree.add(element: node)
        }
    }

    public func forEach (iterator: (ForceBody) -> Void) {
        for node in quadTree {
            let _ = iterator(node.data)
        }
    }

    private func runBarnesHut () {
        var db: CGVector
        var strength: CGFloat

        for node in nodes {
            node.force.dx = 0.0
            node.force.dy = 0.0
            runBarnesHut(node: node, quad: quadTree.root)

            if let center = self.center {
                db = center - node.position
                strength = self.centeringStrength
                if db.dx.isFinite {
                    node.force.dx +=  (0.5 * strength * (db.dx < 0.0 ? -1.0 : 1.0))
                }
                if db.dy.isFinite {
                    node.force.dy += (0.5 * strength * (db.dy < 0.0 ? -1.0 : 1.0))
                }
            }
        }
    }
    
    private func runBarnesHut<T: QuadTreeElement> (node: ForceBodyNode, quad: Quad<T>) {
        let s = (quad.bounds.width + quad.bounds.height) / 2
        let d = (quad.center - node.position).magnitude
        var db: CGVector
        var distance: CGFloat
        var direction: CGVector
        var strength: CGFloat
        
        if s / d > theta {
            if let children = quad.children {
                for child in children {
                    runBarnesHut(node: node, quad: child)
                }
            } else if let elem = quad.element as? ForceBodyNode {
                if elem == node {
                    // same node
                    return
                }
                db = node.position - elem.position // direction matters
                while db.dx <= ForceDirectedGraph.JIGGLE_THRESHOLD && db.dx >= -ForceDirectedGraph.JIGGLE_THRESHOLD ||
                        db.dy <= ForceDirectedGraph.JIGGLE_THRESHOLD && db.dy >= -ForceDirectedGraph.JIGGLE_THRESHOLD {
                    jiggle(vector: &db)
                }
                distance = db.magnitude
                direction = db.normalized

                if distance >= minDistance && distance <= maxDistance {
                    strength = (elem.charge * node.charge) / (distance * distance) // * 9e9
                    direction *= strength
                    node.force += direction
                }
            }
        } else {
            db = node.position - quad.center // direction matters
            while db.dx <= ForceDirectedGraph.JIGGLE_THRESHOLD && db.dx >= -ForceDirectedGraph.JIGGLE_THRESHOLD ||
                db.dy <= ForceDirectedGraph.JIGGLE_THRESHOLD && db.dy >= -ForceDirectedGraph.JIGGLE_THRESHOLD {
                jiggle(vector: &db)
            }
            distance = db.magnitude
            direction = db.normalized
            if distance >= minDistance && distance <= maxDistance {
                strength = (quad.charge * node.charge) / (distance * distance) // * 9e9
                direction *= strength
                node.force += direction
            }
        }
    }
    
    private func jiggle (vector: inout CGVector) {
        // exaggerate small differences
        if vector.dx < 0.0 {
            vector.dx += CGFloat.random(in: -1.0..<0.0)
        } else {
            vector.dx += CGFloat.random(in: 0.0..<1.0)
        }
        if vector.dy < 0.0 {
            vector.dy += CGFloat.random(in: -1.0..<0.0)
        } else {
            vector.dy += CGFloat.random(in: 0.0..<1.0)
        }
    }
}

public extension CGVector {
    internal var magnitude: CGFloat {
        return sqrt(dx*dx + dy*dy)
    }
    internal var normalized: CGVector {
        return CGVector(dx: dx, dy: dy) / sqrt(dx*dx + dy*dy)
    }
}

@inline(__always)
func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}
@inline(__always)
func - (lhs: CGPoint, rhs: CGPoint) -> CGVector {
    return CGVector(dx: lhs.x - rhs.x, dy: lhs.y - rhs.y)
}
@inline(__always)
func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}
@inline(__always)
func += (lhs: inout CGPoint, rhs: CGPoint) {
    lhs.x += rhs.x
    lhs.y += rhs.y
}
@inline(__always)
func / (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
    return CGPoint(x: lhs.x / rhs, y: lhs.y / rhs)
}
@inline(__always)
func /= (lhs: inout CGPoint, rhs: CGFloat) {
    lhs.x /= rhs
    lhs.y /= rhs
}
@inline(__always)
func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
    return CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
}

@inline(__always)
func + (lhs: CGVector, rhs: CGVector) -> CGVector {
    return CGVector(dx: lhs.dx + rhs.dx, dy: lhs.dy + rhs.dy)
}
@inline(__always)
func - (lhs: CGVector, rhs: CGVector) -> CGVector {
    return CGVector(dx: lhs.dx - rhs.dx, dy: lhs.dy - rhs.dy)
}
@inline(__always)
func / (lhs: CGVector, rhs: CGFloat) -> CGVector {
    return CGVector(dx: lhs.dx / rhs, dy: lhs.dy / rhs)
}
@inline(__always)
func * (lhs: CGVector, rhs: CGFloat) -> CGVector {
    return CGVector(dx: lhs.dx * rhs, dy: lhs.dy * rhs)
}
@inline(__always)
func += (lhs: inout CGVector, rhs: CGVector) {
    lhs.dx += rhs.dx
    lhs.dy += rhs.dy
}
@inline(__always)
func *= (lhs: inout CGVector, rhs: CGFloat) {
    lhs.dx *= rhs
    lhs.dy *= rhs
}
