////
////  ShareSheetSubView.swift
////  Teleprompter
////
////  Created by abaig on 17/01/2025.
////
//
//import SwiftUI
//
//struct ShareSheet: UIViewControllerRepresentable {
//    var activityItems: [Any]
//
//    func makeUIViewController(context: Context) -> UIActivityViewController {
//        return UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
//    }
//
//    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
//}
import SwiftUI

#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct ShareSheet: View {
    var activityItems: [Any]

    var body: some View {
        #if os(macOS)
        ShareSheetMac(activityItems: activityItems)
        #else
        ShareSheetiOS(activityItems: activityItems)
        #endif
    }
}

#if os(macOS)
// MARK: - macOS Share Sheet
struct ShareSheetMac: NSViewControllerRepresentable {
    var activityItems: [Any]

    func makeNSViewController(context: Context) -> NSViewController {
        return ShareViewControllerMac(activityItems: activityItems)
    }

    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {}
}

class ShareViewControllerMac: NSViewController {
    let activityItems: [Any]

    init(activityItems: [Any]) {
        self.activityItems = activityItems
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        showShareSheet()
    }

    private func showShareSheet() {
        let picker = NSSharingServicePicker(items: activityItems)
        picker.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
    }
}

#else
// MARK: - iOS Share Sheet
struct ShareSheetiOS: UIViewControllerRepresentable {
    var activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        return UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif
