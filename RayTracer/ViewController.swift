import UIKit
import RayTracer_iOS

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let background = UIImage(named: "nightsky"),
            let backgroundCanvas = Canvas(uiImage: background),
            let dimensions = Dimensions(width: 500, height: 500)
        else {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            let backgroundCanvas = CanvasBackground(canvas: backgroundCanvas)
            self.render(angle: 1, background: backgroundCanvas, dimensions: dimensions, canvas: self.render(background: backgroundCanvas))
        }
    }
    
    // MARK: Inner scene
    
    func render(background: Background) -> Canvas {
        
        let scene = Scene(
            background: background,
            camera: .init(
                eye: .init(x: -5, y: 8, z: 5),
                lookAt: .init(y: 5),
                viewUp: .init(y: 1),
                fov: 60,
                zvp: 0.1
            ),
            objects: [
                Sphere(
                    shader: PhongShader(
                        material: .init(
                            ambient: .init(red: 0.1, green: 0.1, blue: 0.1),
                            diffuse: .init(red: 0.8, green: 0.8, blue: 0.08),
                            specular: .init(red: 0.98, green: 0.98, blue: 0.8),
                            shininess: 100
                        ),
                        reflection: 0.75,
                        transparency: 0
                    ),
                    position: .init(y: 5),
                    radius: 1
                ),
                Box(
                    shader: PhongShader(
                        material: .init(
                            ambient: .init(red: 0.1, green: 0.1, blue: 0.1),
                            diffuse: .init(red: 0.5, green: 0.5, blue: 0.5),
                            specular: .init(red: 0.8, green: 0.8, blue: 0.8),
                            shininess: 50
                        ),
                        reflection: 0.5,
                        transparency: 0
                    ),
                    position: .init(y: 4),
                    size: .init(x: 3, y: 0.5, z: 3)
                )
            ],
            lights: [
                .init(
                    position: .init(x: 2, y: 11, z: 6),
                    ambient: .white,
                    diffuse: .white,
                    specular: .white
                )
            ]
        )
        
        return RayTracer(scene: scene, dimensions: Dimensions(width: 360, height: 180)!).trace()
    }
    
    // Using first scene as a texture of the second
    
    func render(angle: Int, background: Background, dimensions: Dimensions, canvas: Canvas) {
        
        let radAngle = Double(angle) * (Double.pi/180.0)
        
        let scene = Scene(
            background: background,
            camera: .init(
                eye: .init(x: -5 * cos(radAngle), y: 8, z: 5 * sin(radAngle)),
                lookAt: .init(y: 5),
                viewUp: .init(y: 1),
                fov: 45,
                zvp: 0.1
            ),
            objects: [
                Sphere(
                    shader: SphericalTextureShader(
                        canvas: canvas,
                        reflection: 0,
                        transparency: 0
                    ),
                    position: .init(y: 5),
                    radius: 1
                ),
                Box(
                    shader: PhongShader(
                        material: .init(
                            ambient: .init(red: 0.1, green: 0.1, blue: 0.1),
                            diffuse: .init(red: 0.5, green: 0.5, blue: 0.5),
                            specular: .init(red: 0.8, green: 0.8, blue: 0.8),
                            shininess: 50
                        ),
                        reflection: 0.5,
                        transparency: 0
                    ),
                    position: .init(y: 4),
                    size: .init(x: 3, y: 0.5, z: 3)
                )
            ],
            lights: [
                .init(
                    position: .init(x: 2, y: 11, z: 6),
                    ambient: .white,
                    diffuse: .white,
                    specular: .white
                )
            ]
        )
        
        let image = RayTracer(scene: scene, dimensions: dimensions).trace().uiImage
        imageView.image = image
        
        DispatchQueue.main.async { [weak self] in
            self?.render(angle: (angle + 30), background: background, dimensions: dimensions, canvas: canvas)
        }
    }
}

