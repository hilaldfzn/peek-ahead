import RealityKit
import UIKit

enum PipStageError: Error {
    case modelMissing
}

/// Loads Pip (`Pip_teal.usdz`) into a small stage and drives its calm animations.
///
/// Pip's parts keep their names from the USDZ (`LegLeft`, `LegRight`, `Torso`, `ArmLeft`, `ArmRight`,
/// `Antenna`), so they can be animated one by one in code.
@MainActor
final class PipPuppet {
    /// Add this entity to a `RealityView`. It holds Pip, the floor slab, a camera and the lights.
    let root = Entity()
    private let pip: Entity
    private let arm: Entity?
    private let armRest: Transform?

    static func load() async throws -> PipPuppet {
        guard let bundle = AppResources.bundle(containing: "Pip_teal", withExtension: "usdz") else {
            throw PipStageError.modelMissing
        }
        let pip = try await Entity(named: "Pip_teal", in: bundle)
        return PipPuppet(pip: pip)
    }

    private init(pip: Entity) {
        self.pip = pip
        arm = pip.findEntity(named: "ArmRight")
        armRest = arm?.transform

        // The camera sits at the world origin and the stage is moved in front of it. This framing holds
        // whether the view renders through the PerspectiveCamera below or through its own default camera.
        let stage = Entity()
        stage.position = [0, -0.85, -2.9]
        stage.addChild(pip)
        stage.addChild(Self.makeFloor())
        root.addChild(stage)
        root.addChild(Self.makeCamera())
        root.addChild(Self.makeLight(intensity: 2_500, from: [1.5, 3, 1]))
        root.addChild(Self.makeLight(intensity: 800, from: [-2, 2, 1]))
    }

    /// Floats Pip gently up and down until `stopMotion()`.
    func startBobbing(_ motion: PipMotion) {
        var raised = pip.transform
        raised.translation.y += motion.bobHeight
        let bob = FromToByAnimation(
            from: pip.transform,
            to: raised,
            duration: motion.bobPeriod / 2,
            timing: .easeInOut,
            bindTarget: .transform,
            repeatMode: .autoReverse
        )
        do {
            pip.playAnimation(try AnimationResource.generate(with: bob))
        } catch {
            Log.stage.error("Bob animation failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func stopMotion() {
        pip.stopAllAnimations()
        if let arm, let armRest {
            arm.stopAllAnimations()
            arm.transform = armRest
        }
    }

    /// Waves the right arm. The axis and angle are a first guess; tune them after looking at Pip in
    /// Reality Composer Pro (see qa/USDZ_QA.md in the design kit).
    func wave(_ motion: PipMotion) async {
        guard let arm, let rest = armRest else { return }
        var raised = rest
        raised.rotation = rest.rotation * simd_quatf(angle: .pi / 5, axis: [0, 0, 1])
        for _ in 0..<motion.waveCount {
            arm.move(to: raised, relativeTo: arm.parent, duration: motion.waveStepDuration, timingFunction: .easeInOut)
            try? await Task.sleep(for: .seconds(motion.waveStepDuration))
            arm.move(to: rest, relativeTo: arm.parent, duration: motion.waveStepDuration, timingFunction: .easeInOut)
            try? await Task.sleep(for: .seconds(motion.waveStepDuration))
        }
    }

    private static func makeFloor() -> Entity {
        let slab = ModelEntity(
            mesh: .generateBox(width: 2.2, height: 0.08, depth: 1.6, cornerRadius: 0.04),
            materials: [SimpleMaterial(color: UIColor(AppColor.primaryTint), roughness: 0.9, isMetallic: false)]
        )
        slab.position.y = -0.04
        return slab
    }

    private static func makeCamera() -> Entity {
        let camera = PerspectiveCamera()
        camera.camera.fieldOfViewInDegrees = 35
        camera.look(at: [0, -0.35, -2.9], from: [0, 0, 0], relativeTo: nil)
        return camera
    }

    private static func makeLight(intensity: Float, from position: SIMD3<Float>) -> Entity {
        let light = DirectionalLight()
        light.light.intensity = intensity
        light.look(at: [0, -0.85, -2.9], from: position, relativeTo: nil)
        return light
    }
}
