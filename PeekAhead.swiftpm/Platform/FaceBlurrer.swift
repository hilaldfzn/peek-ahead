import CoreImage
import UIKit
import Vision

/// Prepares a grown-up's photo before it is saved: upright, at most 1600 px, and every detected face blurred, so
/// bystanders in a photo of the real place can't be identified. All of it runs on the device.
enum FaceBlurrer {
    static let maxDimension: CGFloat = 1600

    static func prepare(_ image: UIImage) -> UIImage {
        let upright = redrawn(image, maxDimension: maxDimension)
        return blurFaces(in: upright) ?? upright
    }

    /// Redraws the image upright (orientation applied) and no larger than `maxDimension`.
    static func redrawn(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        let scale = longest > 0 ? min(1, maxDimension / longest) : 1
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    /// The image with faces blurred, the same image when no face is found, or `nil` if detection failed.
    static func blurFaces(in image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let request = VNDetectFaceRectanglesRequest()
        do {
            try VNImageRequestHandler(cgImage: cgImage).perform([request])
        } catch {
            return nil
        }
        guard let faces = request.results, !faces.isEmpty else { return image }

        let source = CIImage(cgImage: cgImage)
        let extent = source.extent
        let blurred =
            source
            .clampedToExtent()
            .applyingGaussianBlur(sigma: max(extent.width, extent.height) / 40)
            .cropped(to: extent)
        var output = source
        for face in faces {
            // Vision rects are normalised with the origin at the bottom left, like Core Image.
            let rect = VNImageRectForNormalizedRect(face.boundingBox, Int(extent.width), Int(extent.height))
            let padded = rect.insetBy(dx: -rect.width * 0.25, dy: -rect.height * 0.25).intersection(extent)
            output = blurred.cropped(to: padded).composited(over: output)
        }
        guard let result = CIContext().createCGImage(output, from: extent) else { return nil }
        return UIImage(cgImage: result)
    }
}
