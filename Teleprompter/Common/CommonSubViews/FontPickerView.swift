////
////  FontPickerView.swift
////  Teleprompter
////
////  Created by abaig on 18/12/2024.
////

import SwiftUI

#if os(macOS)
// MARK: - macOS Font Picker
struct FontPickerView: NSViewControllerRepresentable {
    @Binding var fontName: String
    @Binding var fontSize: CGFloat

    func makeNSViewController(context: Context) -> NSFontPickerController {
        let controller = NSFontPickerController()
        controller.coordinator = context.coordinator
        return controller
    }

    func updateNSViewController(_ nsViewController: NSFontPickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator {
        var parent: FontPickerView

        init(_ parent: FontPickerView) {
            self.parent = parent
        }
    }

    class NSFontPickerController: NSViewController, NSFontChanging {
        var coordinator: Coordinator?

        override func viewDidAppear() {
            super.viewDidAppear()
            showFontPanel()
        }

        func showFontPanel() {
            let fontManager = NSFontManager.shared
            fontManager.target = self
            fontManager.action = #selector(changeFont(_:))
            fontManager.orderFrontFontPanel(self)

            if let parent = coordinator?.parent {
                let font = NSFont(name: parent.fontName, size: parent.fontSize) ?? NSFont.systemFont(ofSize: parent.fontSize)
                fontManager.setSelectedFont(font, isMultiple: false)
            }
        }

        @objc func changeFont(_ sender: NSFontManager?) {
            guard let sender = sender, let parent = coordinator?.parent else { return }

            let newFont = sender.convert(
                NSFont(name: parent.fontName, size: parent.fontSize) ?? NSFont.systemFont(ofSize: parent.fontSize)
            )

            parent.fontName = newFont.fontName
            parent.fontSize = newFont.pointSize
        }
    }
}
#else
// MARK: - iOS Font Picker
struct FontPickerView: UIViewControllerRepresentable {
    @Binding var fontName: String
    @Binding var fontSize: CGFloat

    func makeUIViewController(context: Context) -> UIFontPickerViewController {
        let picker = UIFontPickerViewController()
        picker.delegate = context.coordinator

        let descriptor = UIFontDescriptor(name: fontName, size: fontSize)
        picker.selectedFontDescriptor = descriptor

        return picker
    }

    func updateUIViewController(_ uiViewController: UIFontPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIFontPickerViewControllerDelegate {
        var parent: FontPickerView

        init(_ parent: FontPickerView) {
            self.parent = parent
        }

        func fontPickerViewControllerDidPickFont(_ viewController: UIFontPickerViewController) {
            if let descriptor = viewController.selectedFontDescriptor {
                parent.fontName = descriptor.postscriptName
            }
        }
    }
}
#endif
