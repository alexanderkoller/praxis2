import AppKit
import PDFKit
import SwiftUI

final class PDFWindowController: NSWindowController, NSWindowDelegate {
    var onClose: (() -> Void)?

    init(document: PDFDocument, filename: String) {
        let content = PDFViewerContent(document: document)
        let hosting = NSHostingController(rootView: content)
        let window = NSWindow(contentViewController: hosting)
        window.title = filename
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 720, height: 880))
        window.minSize = NSSize(width: 400, height: 500)
        window.center()
        super.init(window: window)
        window.delegate = self
    }

    required init?(coder: NSCoder) { fatalError() }

    func windowWillClose(_ notification: Notification) {
        onClose?()
    }
}

struct PDFViewerContent: View {
    let document: PDFDocument
    @State private var pdfView: PDFView? = nil

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Spacer()
                Button(action: zoomOut) {
                    Image(systemName: "minus.magnifyingglass")
                }
                .buttonStyle(.borderless)
                Button(action: zoomFit) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                }
                .buttonStyle(.borderless)
                Button(action: zoomIn) {
                    Image(systemName: "plus.magnifyingglass")
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            PDFKitView(document: document, pdfView: $pdfView)
        }
        .frame(minWidth: 400, minHeight: 500)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func zoomIn() {
        guard let view = pdfView else { return }
        view.scaleFactor = min(view.scaleFactor * 1.25, view.maxScaleFactor)
    }

    private func zoomOut() {
        guard let view = pdfView else { return }
        view.scaleFactor = max(view.scaleFactor / 1.25, view.minScaleFactor)
    }

    private func zoomFit() {
        pdfView?.autoScales = true
    }
}

private struct PDFKitView: NSViewRepresentable {
    let document: PDFDocument
    @Binding var pdfView: PDFView?

    func makeNSView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.document = document
        DispatchQueue.main.async { pdfView = view }
        return view
    }

    func updateNSView(_ view: PDFView, context: Context) {
        if view.document !== document {
            view.document = document
        }
    }
}
