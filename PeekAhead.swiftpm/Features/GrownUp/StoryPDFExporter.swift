import SwiftUI

/// A printable PDF of a story: one A4 page per story page, for teachers without an iPad and for the fridge.
/// The file is written to the app's temporary folder and shared with the system share sheet; nothing is uploaded.
@MainActor
enum StoryPDFExporter {
    enum ExportError: Error {
        case cannotCreateContext
    }

    /// A4 in points.
    static let pageSize = CGSize(width: 595, height: 842)

    static func export(_ story: Story) throws -> URL {
        let safeName = story.title.components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: "-")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(
            "\(safeName.isEmpty ? "story" : safeName).pdf")
        var mediaBox = CGRect(origin: .zero, size: pageSize)
        guard let context = CGContext(url as CFURL, mediaBox: &mediaBox, nil) else {
            throw ExportError.cannotCreateContext
        }
        for (index, page) in story.pages.enumerated() {
            let renderer = ImageRenderer(
                content: PrintPage(story: story, page: page, number: index + 1)
                    .frame(width: pageSize.width, height: pageSize.height)
            )
            renderer.render { _, draw in
                context.beginPDFPage(nil)
                draw(context)
                context.endPDFPage()
            }
        }
        context.closePDF()
        return url
    }
}

private struct PrintPage: View {
    let story: Story
    let page: StoryPage
    let number: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            Text(verbatim: story.title)
                .font(.custom("Fredoka", size: 22).weight(.semibold))
                .foregroundStyle(AppColor.inkMuted)
            BundleImage(name: page.scene.imageName)
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: 380)
                .background(AppColor.primaryTint, in: RoundedRectangle(cornerRadius: 28))
            Text(verbatim: page.sentence)
                .font(.custom("Andika", size: 34))
                .lineSpacing(12)
                .foregroundStyle(AppColor.ink)
            if let note = page.sometimesNote {
                Text(verbatim: note)
                    .font(.custom("Andika", size: 20))
                    .foregroundStyle(AppColor.sky)
            }
            Spacer()
            Text(verbatim: "\(number) / \(story.pages.count)")
                .font(.custom("Fredoka", size: 16))
                .foregroundStyle(AppColor.inkMuted)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(48)
        .background(Color.white)
    }
}
