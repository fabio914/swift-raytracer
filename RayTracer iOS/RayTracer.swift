import Foundation

struct Definitions {
    static let infinity = Double.greatestFiniteMagnitude - 1.0
}

public struct Vector: Codable {
    var x: Double
    var y: Double
    var z: Double
    
    public static let zero = Vector()
    
    var norm: Double {
        return sqrt(normSquared)
    }
    
    var normSquared: Double {
        return self * self
    }
    
    var normalized: Vector {
        return self/norm
    }
    
    public init(x: Double = 0, y: Double = 0, z: Double = 0) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    init(start: Vector, end: Vector) {
        self = end - start
    }
    
    func cross(_ other: Vector) -> Vector {
        return .init(
            x: (y * other.z) - (z * other.y),
            y: (z * other.x) - (x * other.z),
            z: (x * other.y) - (y * other.x)
        )
    }
    
    static func +(lhs: Vector, rhs: Vector) -> Vector {
        return Vector(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
    }
    
    static func -(lhs: Vector, rhs: Vector) -> Vector {
        return Vector(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z)
    }
    
    static func *(lhs: Vector, rhs: Vector) -> Double {
        return lhs.x * rhs.x + lhs.y * rhs.y + lhs.z * rhs.z
    }
    
    static func *(lhs: Vector, rhs: Double) -> Vector {
        return Vector(x: lhs.x * rhs, y: lhs.y * rhs, z: lhs.z * rhs)
    }
    
    static func /(lhs: Vector, rhs: Double) -> Vector {
        guard rhs != 0 else { return .zero }
        return Vector(x: lhs.x/rhs, y: lhs.y/rhs, z: lhs.z/rhs)
    }
}

public typealias Point = Vector

struct Coordinates: Codable {
    let x: Double
    let y: Double
    
    static let origin = Coordinates()
    
    init(x: Double = 0, y: Double = 0) {
        self.x = x
        self.y = y
    }
    
    init(x: Int, y: Int) {
        self.x = Double(x)
        self.y = Double(y)
    }
}

public struct Camera: Codable {
    let eye: Point
    let lookAt: Point
    let viewUp: Vector
    let fov: Double
    let zvp: Double
    
    public init(eye: Point, lookAt: Point, viewUp: Vector, fov: Double, zvp: Double) {
        self.eye = eye
        self.lookAt = lookAt
        self.viewUp = viewUp
        self.fov = fov
        self.zvp = zvp
    }
}

public struct Dimensions: Codable {
    let width: Double
    let height: Double
    
    public init?(width: Double, height: Double) {
        guard width > 0, height > 0 else { return nil }
        self.width = width
        self.height = height
    }
    
    func contains(_ coordinates: Coordinates) -> Bool {
        return (coordinates.x >= 0 && coordinates.x < width) && (coordinates.y >= 0 && coordinates.y < height)
    }
}

public struct Component: Codable {
    let red: Double
    let green: Double
    let blue: Double
    
    public init(red: Double, green: Double, blue: Double) {
        self.red = min(1, max(0, red))
        self.green = min(1, max(0, green))
        self.blue = min(1, max(0, blue))
    }
}

public struct Color: Codable {
    let red: Double
    let green: Double
    let blue: Double
    
    public static let black = Color()
    public static let white = Color(red: 255, green: 255, blue: 255)
    
    var gammaCorrected: Color {
        let gamma = 1.1
        var red = max(min(self.red/255.0, 1.0), 0.0)
        var green = max(min(self.green/255.0, 1.0), 0.0)
        var blue = max(min(self.blue/255.0, 1.0), 0.0)
        
        red = exp(log(red)/gamma)
        green = exp(log(green)/gamma)
        blue = exp(log(blue)/gamma)
        
        red = ((red * 255) + 0.5)
        green = ((green * 255) + 0.5)
        blue = ((blue * 255) + 0.5)
        
        return .init(red: red, green: green, blue: blue)
    }
    
    public init(red: Double = 0, green: Double = 0, blue: Double = 0) {
        self.red = min(255, max(0, red))
        self.green = min(255, max(0, green))
        self.blue = min(255, max(0, blue))
    }
    
    func average(with color: Color) -> Color {
        return .init(red: (self.red + color.red)/2.0, green: (self.green + color.green)/2.0, blue: (self.blue + color.blue)/2.0)
    }
    
    static func *(lhs: Color, rhs: Double) -> Color {
        return .init(red: lhs.red * rhs, green: lhs.green * rhs, blue: lhs.blue * rhs)
    }
    
    static func +(lhs: Color, rhs: Color) -> Color {
        return .init(red: lhs.red + rhs.red, green: lhs.green + rhs.green, blue: lhs.blue + rhs.blue)
    }
    
    static func +=(lhs: inout Color, rhs: Color) {
        lhs = lhs + rhs
    }
    
    static func *(lhs: Color, rhs: Component) -> Color {
        return .init(red: lhs.red * rhs.red, green: lhs.green * rhs.green, blue: lhs.blue * rhs.blue)
    }
}

public final class Canvas {
    
    let dimensions: Dimensions
    
    let width: Int
    let height: Int
    
    private var pixels: [[Color]]
    
    init(dimensions: Dimensions) {
        self.dimensions = dimensions
        self.width = .init(floor(dimensions.width))
        self.height = .init(floor(dimensions.height))
        
        var pixels = [[Color]]()
        
        for _ in 0 ..< self.height {
            pixels.append([Color](repeating: .black, count: self.width))
        }
        
        self.pixels = pixels
    }
    
    func pixel(at coordinates: Coordinates) -> Color {
        guard dimensions.contains(coordinates) else { return .black }
        return pixels[Int(floor(coordinates.y))][Int(floor(coordinates.x))]
    }
    
    func set(pixel: Color, at coordinates: Coordinates) {
        guard dimensions.contains(coordinates) else { return }
        pixels[Int(floor(coordinates.y))][Int(floor(coordinates.x))] = pixel
    }
    
    func pixel(for direction: Vector) -> Color {
        let theta = atan2(direction.x, direction.z)
        let phi = (-Double.pi/2.0) + acos(direction.y/direction.norm)
        
        let coordinates = Coordinates(
            x: ((theta/Double.pi) + 1.0) * floor((dimensions.width - 1.0)/2.0),
            y: ((phi/(Double.pi/2.0)) + 1.0) * floor((dimensions.height - 1.0)/2.0)
        )
        
        return pixel(at: coordinates)
    }
}

public struct Light: Codable {
    let position: Point
    let ambient: Color
    let diffuse: Color
    let specular: Color
    
    public init(position: Point, ambient: Color, diffuse: Color, specular: Color) {
        self.position = position
        self.ambient = ambient
        self.diffuse = diffuse
        self.specular = specular
    }
}

public protocol Shader {
    var reflection: Double { get }
    var transparency: Double { get }
    
    func color(scene: Scene, normal: Vector, reflection: Vector, intersectionPoint: Point) -> Color
}

public struct Material: Codable {
    let ambient: Component
    let diffuse: Component
    let specular: Component
    
    let shininess: Double
    
    public init(
        ambient: Component,
        diffuse: Component,
        specular: Component,
        shininess: Double
    ) {
        self.ambient = ambient
        self.diffuse = diffuse
        self.specular = specular
        self.shininess = max(1, shininess)
    }
}

public struct Ray {
    let origin: Point
    let direction: Vector
    let energy: Double
    
    init(origin: Point, direction: Vector, energy: Double = 1.0) {
        self.origin = origin
        self.direction = direction
        self.energy = energy
    }
}

public typealias Distance = Double

public protocol SceneObject {
    var shader: Shader { get }
    var position: Point { get }
    
    func intersect(ray: Ray) -> Distance?
    func normal(for point: Point) -> Vector
}

public struct Box: SceneObject {
    public let shader: Shader
    public let position: Point
    let size: Vector
    
    public init(shader: Shader, position: Point, size: Vector) {
        self.shader = shader
        self.position = position
        self.size = size
    }
    
    private var sx: Double {
        return size.x + 0.001
    }
    
    private var sy: Double {
        return size.y + 0.001
    }
    
    private var sz: Double {
        return size.z + 0.001
    }
    
    public func intersect(ray: Ray) -> Distance? {
        let initialSS = Definitions.infinity
        
        var hit = Vector.zero
        var ss = initialSS
        let adj = ray.origin - position
        
        if ray.direction.x != 0 {
            let sa = (sx/2.0 - adj.x)/ray.direction.x
            
            if sa > 0 && sa < ss {
                hit.y = fabs(adj.y + sa * ray.direction.y)
                hit.z = fabs(adj.z + sa * ray.direction.z)
                
                if (hit.y < sy/2.0) && (hit.z < sz/2.0) {
                    ss = sa
                }
            }
            
            let sb = (-sx/2.0 - adj.x)/ray.direction.x
            
            if sb > 0 && sb < ss {
                hit.y = fabs(adj.y + sb * ray.direction.y)
                hit.z = fabs(adj.z + sb * ray.direction.z)
                
                if (hit.y < sy/2.0) && (hit.z < sz/2.0) {
                    ss = sb
                }
            }
        }
        
        if ray.direction.y != 0 {
            let sa = (sy/2.0 - adj.y)/ray.direction.y
            
            if sa > 0 && sa < ss {
                hit.x = fabs(adj.x + sa * ray.direction.x)
                hit.z = fabs(adj.z + sa * ray.direction.z)
                
                if (hit.x < sx/2.0) && (hit.z < sz/2.0) {
                    ss = sa
                }
            }
            
            let sb = (-sy/2.0 - adj.y)/ray.direction.y
            
            if sb > 0 && sb < ss {
                hit.x = fabs(adj.x + sb * ray.direction.x)
                hit.z = fabs(adj.z + sb * ray.direction.z)
                
                if (hit.x < sx/2.0) && (hit.z < sz/2.0) {
                    ss = sb
                }
            }
        }
        
        if ray.direction.z != 0 {
            let sa = (sz/2.0 - adj.z)/ray.direction.z
            
            if sa > 0 && sa < ss {
                hit.x = fabs(adj.x + sa * ray.direction.x)
                hit.y = fabs(adj.y + sa * ray.direction.y)
                
                if (hit.x < sx/2.0) && (hit.y < sy/2.0) {
                    ss = sa
                }
            }
            
            let sb = (-sz/2.0 - adj.z)/ray.direction.z
            
            if sb > 0 && sb < ss {
                hit.x = fabs(adj.x + sb * ray.direction.x)
                hit.y = fabs(adj.y + sb * ray.direction.y)
                
                if (hit.x < sx/2.0) && (hit.y < sy/2.0) {
                    ss = sb
                }
            }
        }
        
        if ss == initialSS {
            return nil
        }
        
        return ss
    }
    
    public func normal(for point: Point) -> Vector {
        var face = 0
        var diff = 0.0
        var ss = Definitions.infinity
        
        diff = fabs((position.x + sx/2.0) - point.x)
        if ss > diff {
            ss = diff
            face = 0
        }
        
        diff = fabs((position.x - sx/2.0) - point.x)
        if ss > diff {
            ss = diff
            face = 1
        }
        
        diff = fabs((position.y + sy/2.0) - point.y)
        if ss > diff {
            ss = diff
            face = 2
        }
        
        diff = fabs((position.y - sy/2.0) - point.y)
        if ss > diff {
            ss = diff
            face = 3
        }
        
        diff = fabs((position.z + sz/2.0) - point.z)
        if ss > diff {
            ss = diff
            face = 4
        }
        
        diff = fabs((position.z - sz/2.0) - point.z)
        if ss > diff {
            ss = diff
            face = 5
        }
        
        switch face {
        case 0:
            return .init(x: 1)
        case 1:
            return .init(x: -1)
        case 2:
            return .init(y: 1)
        case 3:
            return .init(y: -1)
        case 4:
            return .init(z: 1)
        case 5:
            return .init(z: -1)
        default:
            return .zero
        }
    }
}

public struct Sphere: SceneObject {
    public let shader: Shader
    public let position: Point
    let radius: Double
    
    public init(shader: Shader, position: Point, radius: Double) {
        self.shader = shader
        self.position = position
        self.radius = max(0.001, radius)
    }
    
    public func intersect(ray: Ray) -> Distance? {
        let diff = ray.origin - position
        let d = diff * ray.direction
        let t = (d * d) - diff.normSquared + (radius * radius)
        
        if t < 0 {
            return nil
        }
        
        let sa = (-d - sqrt(t))
        if sa > 0 {
            return sa
        }
        
        let sb = (-d + sqrt(t))
        if sb > 0 {
            return sb
        }
        
        return nil
    }
    
    public func normal(for point: Point) -> Vector {
        return (point - position)/radius
    }
}

public protocol Background {
    func color(for: Ray) -> Color
}

public struct ColorBackground: Background {
    let color: Color
    
    public init(color: Color) {
        self.color = color
    }
    
    public func color(for ray: Ray) -> Color {
        return color * ray.energy
    }
}

public struct CanvasBackground: Background {
    let canvas: Canvas
    
    public init(canvas: Canvas) {
        self.canvas = canvas
    }
    
    public func color(for ray: Ray) -> Color {
        return canvas.pixel(for: ray.direction) * ray.energy
    }
}

struct Intersection {
    let object: SceneObject
    let distance: Distance
}

public struct Scene {
    let background: Background
    let camera: Camera
    let objects: [SceneObject]
    let lights: [Light]
    
    public init(background: Background, camera: Camera, objects: [SceneObject], lights: [Light]) {
        self.background = background
        self.camera = camera
        self.objects = objects
        self.lights = lights
    }
    
    func intersect(ray: Ray) -> Intersection? {
        var minDist = Definitions.infinity
        var object: SceneObject? = nil
        
        for currentObject in objects {
            if let distance = currentObject.intersect(ray: ray), distance > 0, minDist > distance {
                minDist = distance
                object = currentObject
            }
        }
        
        if let object = object {
            return Intersection(object: object, distance: minDist)
        }
        
        return nil
    }
}

public struct PhongShader: Shader {
    let material: Material
    public let reflection: Double
    public let transparency: Double
    
    public init(material: Material, reflection: Double, transparency: Double) {
        self.material = material
        self.reflection = max(0, min(1, reflection))
        self.transparency = max(0, min(1, transparency))
    }
    
    public func color(scene: Scene, normal: Vector, reflection: Vector, intersectionPoint: Point) -> Color {
        var color = Color.black
        
        for light in scene.lights {
            
            color += light.ambient * material.ambient
            let lightDir = Vector(start: intersectionPoint, end: light.position).normalized
            let shadowRay = Ray(origin: intersectionPoint, direction: lightDir)
            
            if let _ = scene.intersect(ray: shadowRay) {
                continue
            }
            
            let diff = normal * lightDir
            
            if diff > 0 {
                
                color += (light.diffuse * material.diffuse) * diff
                
                var spec = reflection * lightDir
                
                if spec > 0 {
                    
                    spec = max(0, pow(spec, material.shininess))
                    color += (light.specular * material.specular) * spec
                }
            }
        }
        
        return color
    }
}

public struct SphericalTextureShader: Shader {
    public let reflection: Double
    public let transparency: Double
    let canvas: Canvas
    
    public init(canvas: Canvas, reflection: Double, transparency: Double) {
        self.canvas = canvas
        self.reflection = reflection
        self.transparency = transparency
    }
    
    public func color(scene: Scene, normal: Vector, reflection: Vector, intersectionPoint: Point) -> Color {
        return canvas.pixel(for: normal)
    }
}

struct RayShooter {
    let eye: Point
    let xDir: Vector
    let yDir: Vector
    let fRay: Vector
    
    init(camera: Camera, dimensions: Dimensions) {
        self.eye = camera.eye
        let zDir = Vector(start: camera.eye, end: camera.lookAt).normalized
        let xDir = zDir.cross(camera.viewUp).normalized
        let yDir = xDir.cross(zDir).normalized
        
        let height = 2.0 * camera.zvp * tan((camera.fov * (Double.pi/180.0))/2.0)
        let width = (dimensions.width/dimensions.height) * height
        
        self.xDir = xDir * (width/dimensions.width)
        self.yDir = yDir * (height/dimensions.height)
        
        self.fRay = (zDir * camera.zvp) + (self.yDir * (dimensions.height/2.0)) - (self.xDir * (dimensions.width/2.0))
    }
    
    func ray(for coordinates: Coordinates) -> Ray {
        let direction = (fRay + (xDir * coordinates.x) - (yDir * coordinates.y)).normalized
        return Ray(origin: eye, direction: direction)
    }
}

public struct RayTracer {
    let scene: Scene
    let dimensions: Dimensions
    let antialiasing: Bool
    let depth: Int
    
    static let minEnergy = 0.001
    static let epsilon = 0.001
    
    public init(scene: Scene, dimensions: Dimensions, antialiasing: Bool = true, depth: Int = 5) {
        self.scene = scene
        self.dimensions = dimensions
        self.antialiasing = antialiasing
        self.depth = max(1, depth)
    }
    
    public func trace() -> Canvas {
        let canvas = Canvas(dimensions: dimensions)
        let shooter = RayShooter(camera: scene.camera, dimensions: dimensions)
        
        var y = 0.0
        var x = 0.0
        
        guard antialiasing else {
            
            while y < dimensions.height {
                while x < dimensions.width {
                    let coordinates = Coordinates(x: x, y: y)
                    let ray = shooter.ray(for: coordinates)
                    canvas.set(pixel: trace(ray: ray).gammaCorrected, at: coordinates)
                    x += 1.0
                }
                
                x = 0.0
                y += 1.0
            }
            
            return canvas
        }
        
        // TODO: Multi-thread
        
        while y <= dimensions.height {
            while x <= dimensions.width {
                
                let coordinates = Coordinates(x: x, y: y)
                var yPart = -0.75
                var xPart = -0.75
                var temporaryColor = Color.black
                
                while yPart < 1.0 {
                    while xPart < 1.0 {
                        let coordinates = Coordinates(x: x + xPart, y: y + yPart)
                        let ray = shooter.ray(for: coordinates)
                        temporaryColor = temporaryColor.average(with: trace(ray: ray))
                        xPart += 0.5
                    }
                    
                    yPart += 0.5
                }
                
                canvas.set(pixel: temporaryColor.gammaCorrected, at: coordinates)
                x += 1.0
            }
            
            x = 0.0
            y += 1.0
        }
        
        return canvas
    }
    
    private func trace(ray: Ray, step: Int = 0) -> Color {
        guard step < depth, ray.energy > RayTracer.minEnergy, let intersection = scene.intersect(ray: ray) else {
            return scene.background.color(for: ray)
        }
        
        let intersectionPoint = ray.origin + (ray.direction * intersection.distance)
        let normal = intersection.object.normal(for: intersectionPoint)
        
        let correctedIntersection = intersectionPoint + (normal * RayTracer.epsilon)
        let shader = intersection.object.shader
        
        /* Reflection */
        let k = 2.0 * (ray.direction * normal)
        let reflection = (ray.direction - (normal * k)).normalized
        
        let localColor = shader.color(
            scene: scene,
            normal: normal,
            reflection: reflection,
            intersectionPoint: correctedIntersection
        )
        
        let reflectedRay = Ray(origin: correctedIntersection, direction: reflection, energy: ray.energy * shader.reflection)
        let reflectionColor = trace(ray: reflectedRay, step: step + 1)
        
        /* Transparency */
        // TODO
        
        return (localColor * ray.energy) + (reflectionColor * reflectedRay.energy)
//        return (localColor * ray.energy).average(with: (reflectionColor * reflectedRay.energy))
    }
}
