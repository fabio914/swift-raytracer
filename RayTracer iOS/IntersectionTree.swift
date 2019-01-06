//import Foundation
//
//protocol BoundedObject {
//    var boundingSphere: BoundingSphere { get }
//    func intersect(ray: Ray) -> Distance?
//}
//
//struct BoundingSphere {
//    let center: Point
//    let radius: Double
//    
//    init(center: Point, radius: Double) {
//        self.radius = max(0, radius)
//        self.center = center
//    }
//    
//    init(spheres: [BoundingSphere]) {
//        guard spheres.count > 0 else {
//            self.init(center: .zero, radius: 0)
//            return
//        }
//        
//        var minV = Vector.infinity
//        var maxV = Vector.negativeInfinity
//        
//        for sphere in spheres {
//            let localMin = sphere.center - Vector(all: sphere.radius)
//            let localMax = sphere.center + Vector(all: sphere.radius)
//            
//            minV.x = min(localMin.x, minV.x)
//            minV.y = min(localMin.y, minV.y)
//            minV.z = min(localMin.z, minV.z)
//            maxV.x = max(localMax.x, maxV.x)
//            maxV.y = max(localMax.y, maxV.y)
//            maxV.z = max(localMax.z, maxV.z)
//        }
//        
//        let center = (minV + maxV)/2.0
//        let radius = (maxV - center).norm
//        self.init(center: center, radius: radius)
//    }
//    
//    func intersect(ray: Ray) -> Distance? {
//        let diff = ray.origin - center
//        let d = diff * ray.direction
//        let t = (d * d) - diff.normSquared + (radius * radius)
//        
//        if t < 0 {
//            return nil
//        }
//        
//        let sa = (-d - sqrt(t))
//        if sa > 0 {
//            return sa
//        }
//        
//        let sb = (-d + sqrt(t))
//        if sb > 0 {
//            return sb
//        }
//        
//        return nil
//    }
//}
//
//struct IntersectionTree<T: BoundedObject> {
//    
//    enum Node {
//        case leaf(_ object: T)
//        case branch(_ boundingSphere: BoundingSphere, _ children: [Node])
//        
//        init(object: T) {
//            self = .leaf(object)
//        }
//        
//        init(left: T, right: T) {
//            self = .branch(
//                BoundingSphere(spheres: [left.boundingSphere, right.boundingSphere]),
//                [Node(object: left), Node(object: right)]
//            )
//        }
//        
//        init?(objects: [T]) {
//            guard objects.count > 0 else { return nil }
//            
//            if objects.count == 1, let first = objects.first {
//                self.init(object: first)
//            }
//                
//            else if objects.count == 2 {
//                self.init(left: objects[0], right: objects[1])
//            }
//            
//            else {
//                let boundingSphere = BoundingSphere(spheres: objects.map({ $0.boundingSphere }))
//                
//                // Minimize bounding spheres radii and tree depth?
//                // TODO
//            }
//        }
//        
//        func intersect(ray: Ray) -> (T, Distance)? {
//            switch self {
//            case .leaf(let object):
//                guard let distance = object.intersect(ray: ray) else {
//                    return nil
//                }
//                
//                return (object, distance)
//            case .branch(let sphere, let children):
//                guard let _ = sphere.intersect(ray: ray) else {
//                    return nil
//                }
//                
//                return children.compactMap({ $0.intersect(ray: ray) }).min(by: { $0.1 < $1.1 })
//            }
//        }
//    }
//    
//    let root: Node?
//    
//    init(objects: [T]) {
//        self.root = Node(objects: objects)
//    }
//    
//    func intersect(ray: Ray) -> (T, Distance)? {
//        return root?.intersect(ray: ray)
//    }
//}
