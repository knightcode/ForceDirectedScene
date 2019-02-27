//
//  QuadTree.swift
//  ForceDirectedScene
//
//  Created by PJ Dillon on 2/6/19.
//

import Foundation

public protocol QuadTreeElement: class {
    var position: CGPoint { get }
    var charge: CGFloat { get }
}

public class Quad<T: QuadTreeElement> {
    public let bounds: CGRect
    public var center: CGPoint
    public var charge: CGFloat

    private(set) public var count: Int

    var element: T?
    var children: Array<Quad>?

    public init (bounds: CGRect) {
        self.bounds = bounds
        self.center = bounds.midpoint
        self.count = 0
        self.charge = 0
    }

    public init (bounds: CGRect, element: T) {
        self.bounds = bounds
        self.center = element.position
        self.element = element
        self.count = 1
        self.charge = 0
    }

    public func add (element: T) {
        guard bounds.contains(element.position) else {
            print("trying add: element outside of my bounds: \(bounds), position: \(element.position)")
            return
        }
        if self.element == nil && self.children == nil {
            // empty node at the start
            self.element = element
            count = 1
            return
        }
        if let elem = self.element {
            subdivide()
            self.element = nil
            count = 0 // will be incremented in recursive call
            
            // recursively insert old, existing element, then continue adding new
            add(element: elem)
        }
        guard let children = self.children else { return }
        for child in children {
            if child.bounds.contains(element.position) {
                child.add(element: element)
                break
            }
        }
        count += 1
    }

    public func remove (element: T) -> Bool {
        if let elem = self.element, elem == element {
            self.element = nil
            count = 0
            return true
        }
        guard let children = self.children else { return false }
        var found = false
        for child in children {
            if child.remove(element: element) {
                count -= 1
                found = true
            }
        
        }
        if count == 1 {
            // consolidate
            for child in children {
                if child.element != nil {
                    self.element = child.element
                }
            }
            self.children = nil
        }
        return found
    }

    public func computeCenter () -> CGPoint {
        if let elem = self.element {
            center = elem.position // position may have changed from acting forces
            charge = elem.charge
            return center
        }
        guard let children = self.children else { return center }
        center.x = 0.0
        center.y = 0.0
        charge = 0.0
        for child in children {
            center += child.computeCenter()
            charge += child.charge
        }
        center /= CGFloat(count)
        return center
    }

    private func subdivide () {
        let midX = bounds.size.width / 2
        let midY = bounds.size.height / 2
        let nw = CGRect(
            x: bounds.origin.x,
            y: bounds.origin.y + midY,
            width: midX,
            height: midY)
        let ne = CGRect(
            x: bounds.origin.x + midX,
            y: bounds.origin.y + midY,
            width: midX,
            height: midY)
        let sw = CGRect(
            x: bounds.origin.x,
            y: bounds.origin.y,
            width: midX,
            height: midY)
        let se = CGRect(
            x: bounds.origin.x + midX,
            y: bounds.origin.y,
            width:midX,
            height: midY)
        self.children = [
            Quad(bounds: nw),
            Quad(bounds: ne),
            Quad(bounds: sw),
            Quad(bounds: se)
        ]
    }
}

public class QuadTree<T: QuadTreeElement>: Sequence {
    let root: Quad<T>
    
    public init(bounds: CGRect, bodies: [T]? = nil) {
        root = Quad(bounds: bounds)
        if let elems = bodies {
            for elem in elems {
                root.add(element: elem)
            }
        }
    }

    public func add (element: T) {
        root.add(element: element)
    }
    public func remove (element: T) {
        let _ = root.remove(element: element)
    }
    public func computeCenters () {
        let _ = root.computeCenter()
    }

    public func makeIterator() -> QuadTreeIterator<T> {
        return QuadTreeIterator(quad: root)
    }

    public func forEach(iter: (T, Quad<T>) -> Void) {
        recursiveforEach(node: root, iter: iter)
    }

    private func recursiveforEach(node: Quad<T>, iter: (T, Quad<T>) -> Void) {
        if node.element == nil && node.children == nil {
            return
        }
        if let elem = node.element {
            iter(elem, node)
            return
        }
        if let quads = node.children {
            for q in quads {
                recursiveforEach(node: q, iter: iter)
            }
        }
    }
}

public class QuadTreeIterator<T: QuadTreeElement>: IteratorProtocol {
    
    var stack: Array<Quad<T>>
    init (quad: Quad<T>) {
        stack = [quad]
    }
    public func next() -> T? {
        while let quad = stack.popLast() {
            if let elem = quad.element {
                return elem
            }
            if let children = quad.children {
                for child in children {
                    stack.append(child)
                }
            }
        }
        return nil
    }
}

public extension CGRect {
    public var midpoint: CGPoint{
        return CGPoint(x: midX, y: midY)
    }
}
