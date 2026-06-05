import CoreImage.CIFilterBuiltins
import SwiftUI

struct QRCodeView: View {
    let url: String

    var body: some View {
        if let image = generateQR(url) {
            Image(nsImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: "qrcode")
                .font(.system(size: 84, weight: .light))
                .foregroundStyle(PraxisPalette.subtleText)
        }
    }

    private func generateQR(_ string: String) -> NSImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return NSImage(cgImage: cgImage, size: .zero)
    }
}
