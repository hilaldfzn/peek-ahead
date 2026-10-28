import SwiftUI

/// Pip's room: everything the child has chosen, on Pip's floor slab.
/// (A 3D room comes later, once the RealityKit spike holds up on device.)
struct PipRoomView: View {
    let items: [RoomItem]
    let onHome: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpace.lg) {
            HStack(spacing: AppSpace.md) {
                CircleIconButton(title: "Home", systemImage: "house.fill", action: onHome)
                Text("Pip's room")
                    .font(AppFont.title)
                    .foregroundStyle(AppColor.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)
                NeedCardButton()
            }
            ScrollView {
                VStack(spacing: AppSpace.lg) {
                    BundleImage(name: "pip_teal")
                        .scaledToFit()
                        .frame(height: 180)
                        .accessibilityLabel(Text("Pip"))
                    if items.isEmpty {
                        Text("Finish a story to choose the first thing for Pip's room.")
                            .font(AppFont.labelChild)
                            .foregroundStyle(AppColor.inkMuted)
                            .multilineTextAlignment(.center)
                    } else {
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 150), spacing: AppSpace.lg)], spacing: AppSpace.lg
                        ) {
                            ForEach(items) { item in
                                VStack(spacing: AppSpace.xs) {
                                    BundleImage(name: item.imageName)
                                        .scaledToFit()
                                        .frame(height: 110)
                                    Text(item.title)
                                        .font(AppFont.labelChild)
                                        .foregroundStyle(AppColor.ink)
                                }
                                .accessibilityElement(children: .combine)
                            }
                        }
                    }
                }
                .padding(AppSpace.xl)
                .frame(maxWidth: .infinity)
                .background(
                    AppColor.primaryTint, in: RoundedRectangle(cornerRadius: AppRadius.slab, style: .continuous)
                )
            }
        }
        .padding(AppSpace.xl)
        .background(AppColor.paper)
        .toolbar(.hidden, for: .navigationBar)
    }
}
