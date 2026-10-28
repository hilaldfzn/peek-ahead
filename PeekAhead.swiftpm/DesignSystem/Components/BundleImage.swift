import SwiftUI
import UIKit

/// A resizable picture loaded from a PNG in the app bundle, with a calm tinted fallback if it is missing.
struct BundleImage: View {
    let name: String

    var body: some View {
        if let image = AppResources.image(named: name) {
            Image(uiImage: image)
                .resizable()
        } else {
            Rectangle()
                .fill(AppColor.primaryTint)
        }
    }
}
