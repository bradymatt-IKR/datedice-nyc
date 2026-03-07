import SwiftUI
import SceneKit

/// A single 3D dice rendered with SceneKit — gold-textured cube with dark dots,
/// continuous spin while rolling, spring-settle to final face when done.
/// Matches the web app's Dice3D component.
struct SceneKitDice: UIViewRepresentable {
    let value: Int
    let rolling: Bool

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var wasRolling = false
        var lastValue = 0
    }

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .clear
        scnView.isOpaque = false
        scnView.allowsCameraControl = false
        scnView.antialiasingMode = .multisampling4X
        scnView.isUserInteractionEnabled = false

        let scene = SCNScene()
        scnView.scene = scene

        // Camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 28
        cameraNode.position = SCNVector3(0, 0, 5)
        scene.rootNode.addChildNode(cameraNode)

        // Warm key light (top-right-front)
        let keyLight = SCNNode()
        keyLight.light = SCNLight()
        keyLight.light?.type = .omni
        keyLight.light?.intensity = 900
        keyLight.light?.color = UIColor(red: 1.0, green: 0.97, blue: 0.92, alpha: 1)
        keyLight.position = SCNVector3(2, 3, 4)
        scene.rootNode.addChildNode(keyLight)

        // Warm ambient fill
        let ambientNode = SCNNode()
        ambientNode.light = SCNLight()
        ambientNode.light?.type = .ambient
        ambientNode.light?.intensity = 450
        ambientNode.light?.color = UIColor(red: 0.95, green: 0.92, blue: 0.85, alpha: 1)
        scene.rootNode.addChildNode(ambientNode)

        // Dice cube
        let box = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0.12)
        box.materials = Self.faceMaterials()

        let diceNode = SCNNode(geometry: box)
        diceNode.name = "dice"
        diceNode.eulerAngles = Self.eulerAngles(for: value)
        scene.rootNode.addChildNode(diceNode)

        context.coordinator.lastValue = value
        return scnView
    }

    func updateUIView(_ scnView: SCNView, context: Context) {
        guard let node = scnView.scene?.rootNode.childNode(withName: "dice", recursively: false) else { return }
        let coord = context.coordinator

        if rolling && !coord.wasRolling {
            // Start spinning — matches web's diceRotate keyframes
            node.removeAllActions()
            node.removeAllAnimations()   // Clear SCNTransaction settle animations
            let spin = SCNAction.repeatForever(
                SCNAction.rotateBy(
                    x: CGFloat.pi * 4,       // 720°
                    y: CGFloat.pi * 2.56,    // ~460°
                    z: CGFloat.pi * 1.11,    // ~200°
                    duration: 0.65
                )
            )
            node.runAction(spin, forKey: "roll")

        } else if !rolling && (coord.wasRolling || coord.lastValue != value) {
            // Settle to final face — matches web's diceSettle cubic-bezier
            node.removeAction(forKey: "roll")
            let target = Self.eulerAngles(for: value)
            let duration = coord.wasRolling ? 1.15 : 0.3
            SCNTransaction.begin()
            SCNTransaction.animationDuration = duration
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(controlPoints: 0.12, 0, 0.2, 1)
            node.eulerAngles = target
            SCNTransaction.commit()
        }

        coord.wasRolling = rolling
        coord.lastValue = value
    }

    // MARK: - Materials

    /// Creates 6 materials for the SCNBox faces.
    /// SCNBox order: +X(right=2), -X(left=5), +Y(top=3), -Y(bottom=4), +Z(front=1), -Z(back=6)
    static func faceMaterials() -> [SCNMaterial] {
        [2, 5, 3, 4, 1, 6].map { faceValue in
            let mat = SCNMaterial()
            mat.diffuse.contents = renderFace(faceValue, size: 256)
            mat.locksAmbientWithDiffuse = true
            return mat
        }
    }

    // MARK: - Render Face Texture

    /// Renders a single dice face as a UIImage: gold gradient background + dark dots.
    /// Matches web app's DiceFaceSVG colors exactly.
    static func renderFace(_ value: Int, size: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { ctx in
            let gc = ctx.cgContext

            // Gold gradient background (web: #fffdeb → #f2e6c3)
            let colors = [
                UIColor(red: 1.0, green: 0.99, blue: 0.92, alpha: 1).cgColor,
                UIColor(red: 0.95, green: 0.90, blue: 0.76, alpha: 1).cgColor,
            ]
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors as CFArray,
                locations: [0, 1]
            )!
            gc.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size, y: size), options: [])

            // Dots (web: #1b1408 with rgba(0,0,0,0.18) shadow)
            let dotR = size * 0.09
            let dotColor = UIColor(red: 27/255, green: 20/255, blue: 8/255, alpha: 1)
            let shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.18)

            let positions: [Int: [(CGFloat, CGFloat)]] = [
                1: [(0.5, 0.5)],
                2: [(0.33, 0.33), (0.67, 0.67)],
                3: [(0.33, 0.33), (0.5, 0.5), (0.67, 0.67)],
                4: [(0.33, 0.33), (0.67, 0.33), (0.33, 0.67), (0.67, 0.67)],
                5: [(0.33, 0.33), (0.67, 0.33), (0.5, 0.5), (0.33, 0.67), (0.67, 0.67)],
                6: [(0.33, 0.25), (0.67, 0.25), (0.33, 0.5), (0.67, 0.5), (0.33, 0.75), (0.67, 0.75)],
            ]

            for pos in positions[value] ?? [] {
                let cx = pos.0 * size
                let cy = pos.1 * size

                // Drop shadow
                gc.setFillColor(shadowColor.cgColor)
                gc.fillEllipse(in: CGRect(x: cx - dotR, y: cy - dotR + 1, width: dotR * 2, height: dotR * 2))

                // Dot
                gc.setFillColor(dotColor.cgColor)
                gc.fillEllipse(in: CGRect(x: cx - dotR, y: cy - dotR, width: dotR * 2, height: dotR * 2))
            }
        }
    }

    // MARK: - Face Rotation

    /// Euler angles to orient the cube so the given face value points toward the camera (+Z).
    static func eulerAngles(for face: Int) -> SCNVector3 {
        let pi = Float.pi
        switch face {
        case 1: return SCNVector3(0, 0, 0)
        case 2: return SCNVector3(0, -pi / 2, 0)
        case 3: return SCNVector3(pi / 2, 0, 0)
        case 4: return SCNVector3(-pi / 2, 0, 0)
        case 5: return SCNVector3(0, pi / 2, 0)
        case 6: return SCNVector3(0, pi, 0)
        default: return SCNVector3(0, 0, 0)
        }
    }
}
