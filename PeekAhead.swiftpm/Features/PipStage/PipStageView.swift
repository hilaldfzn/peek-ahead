import RealityKit
import SwiftUI

/// Pip in 3D on a rounded floor slab. Tapping Pip makes it wave.
///
/// This is the RealityKit spike: if loading fails (or is too slow on the target device), the view falls back
/// to the pre-rendered `pip_teal.png`, so the rest of the app never depends on 3D.
struct PipStageView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var puppet: PipPuppet?
    @State private var loadFailed = false

    var body: some View {
        ZStack {
            AppColor.primaryTint
            if let puppet {
                RealityView { content in
                    content.add(puppet.root)
                }
                .onTapGesture { wave() }
            } else if loadFailed {
                BundleImage(name: "pip_teal")
                    .scaledToFit()
                    .padding(AppSpace.lg)
            } else {
                ProgressView()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.slab, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Pip, a small robot friend"))
        .accessibilityAction(named: Text("Wave")) { wave() }
        .task { await load() }
        .onChange(of: reduceMotion) { applyMotion() }
    }

    private var motion: PipMotion? {
        PipMotion.forSettings(reduceMotion: reduceMotion)
    }

    private func load() async {
        guard puppet == nil, !loadFailed else { return }
        do {
            let loaded = try await PipPuppet.load()
            puppet = loaded
            applyMotion()
            if let motion {
                await loaded.wave(motion)
            }
        } catch {
            Log.stage.error("Pip failed to load: \(String(describing: error), privacy: .public)")
            loadFailed = true
        }
    }

    private func applyMotion() {
        guard let puppet else { return }
        puppet.stopMotion()
        if let motion {
            puppet.startBobbing(motion)
        }
    }

    private func wave() {
        guard let puppet, let motion else { return }
        Task { await puppet.wave(motion) }
    }
}
