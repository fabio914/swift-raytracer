import UIKit

extension Coordinates {
    var cgPoint: CGPoint {
        return .init(x: x, y: y)
    }
}

extension Dimensions {
    var cgSize: CGSize {
        return .init(width: width, height: height)
    }
}

public extension Color {
    var uiColor: UIColor {
        return .init(red: CGFloat(red/255.0), green: CGFloat(green/255.0), blue: CGFloat(blue/255.0), alpha: CGFloat(1.0))
    }
    
    public init(uiColor: UIColor) {
        var red = CGFloat(0)
        var green = CGFloat(0)
        var blue = CGFloat(0)
        var alpha = CGFloat(0)
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        self.init(red: Double(red) * 255.0, green: Double(green) * 255.0, blue: Double(blue) * 255.0)
    }
}

extension CGImage {
    
    var pixels: [UIColor]? {
        
        let bytesPerPixel = 4
        let rawData = UnsafeMutablePointer<UInt8>.allocate(capacity: width * height * bytesPerPixel)
        
        guard let context = CGContext(
            data: rawData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerPixel * width,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)
        else {
            return nil
        }
        
        context.draw(self, in: .init(origin: .zero, size: .init(width: width, height: height)))
        
        let count = (width * height)
        var result = [UIColor](repeating: .black, count: count)
        
        for i in 0 ..< count {
            let byteIndex = (i * bytesPerPixel)
            
            result[i] = .init(
                red: CGFloat(rawData[byteIndex])/CGFloat(255),
                green: CGFloat(rawData[byteIndex + 1])/CGFloat(255),
                blue: CGFloat(rawData[byteIndex + 2])/CGFloat(255),
                alpha: 1.0
            )
        }
        
        rawData.deallocate()
        return result
    }
}

public extension Canvas {
    
    public var uiImage: UIImage? {
        UIGraphicsBeginImageContext(dimensions.cgSize)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        
        for i in 0 ..< height {
            for j in 0 ..< width {
                let coordinates = Coordinates(x: j, y: i)
                context.setFillColor(pixel(at: coordinates).uiColor.cgColor)
                context.fill(.init(origin: coordinates.cgPoint, size: .init(width: 1, height: 1)))
            }
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    convenience init?(cgImage: CGImage) {
        
        guard let pixels = cgImage.pixels,
            let dimensions = Dimensions(width: Double(cgImage.width), height: Double(cgImage.height))
        else {
            return nil
        }
        
        self.init(dimensions: dimensions)
        
        for i in 0 ..< height {
            for j in 0 ..< width {
                self.set(pixel: Color(uiColor: pixels[(i * width) + j]), at: .init(x: j, y: i))
            }
        }
    }
    
    convenience init?(uiImage: UIImage) {
        guard let cgImage = uiImage.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}


