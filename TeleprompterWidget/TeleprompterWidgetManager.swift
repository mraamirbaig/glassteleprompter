//
//  TeleprompterWidgetManager.swift
//  Teleprompter
//
//  Created by abaig on 28/08/2025.
//

import ActivityKit
import UIKit

class TeleprompterWidgetManager {
    static let shared = TeleprompterWidgetManager()
    private init() {}

    private let imageCacheFolder: URL = {
           guard let folder = FileManager.default.containerURL(
               forSecurityApplicationGroupIdentifier: "group.com.hct.teleprompter"
           )?.appendingPathComponent("TeleprompterImages") else {
               fatalError("App Group container not found")
           }

           if !FileManager.default.fileExists(atPath: folder.path) {
               try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
           }
           return folder
       }()

    var currentActivity: Activity<TeleprompterAttributes>?

    func show(image: UIImage, text: String, isGlassesConnected: Bool) {
        if currentActivity == nil {
            start(image: image, text: text, isGlassesConnected: isGlassesConnected)
        } else {
            update(image: image, text: text, isGlassesConnected: isGlassesConnected)
        }
    }

    private func start(image: UIImage, text: String, isGlassesConnected: Bool) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = TeleprompterAttributes(scriptTitle: "Teleprompter")
        guard let imageID = saveImageToCache(image) else { return }

        let contentState = TeleprompterAttributes.ContentState(
            text: text,
            imageID: imageID,
            isGlassesConnected: isGlassesConnected
        )

        Task {
            do {
                currentActivity = try Activity<TeleprompterAttributes>.request(
                    attributes: attributes,
                    contentState: contentState
                )
            } catch {
                print("Failed to start Live Activity: \(error)")
            }
        }
    }

    private func update(image: UIImage, text: String, isGlassesConnected: Bool) {
        guard let activity = currentActivity else { return }
        guard let imageID = saveImageToCache(image) else { return }

        let contentState = TeleprompterAttributes.ContentState(
            text: text,
            imageID: imageID,
            isGlassesConnected: isGlassesConnected
        )

        Task {
            await activity.update(using: contentState)
        }
    }

    func end() {
        guard let activity = currentActivity else { return }
        Task {
            await activity.end(dismissalPolicy: .immediate)
            currentActivity = nil
        }
    }

    private func saveImageToCache(_ image: UIImage) -> String? {
        let imageID = "widget_image"
        let url = imageCacheFolder.appendingPathComponent("\(imageID).png") // ✅ use png
        print("url.path11111......")
        print(url.path)
        guard let data = image.pngData() else { return nil }
        do {
            try data.write(to: url)
            return imageID
        } catch {
            print("Failed to save image: \(error)")
            return nil
        }
    }

    func loadImageFromCache(imageID: String) -> UIImage? {
        print("url.path2222......")
        let url = imageCacheFolder.appendingPathComponent("\(imageID).png") // ✅ match extension
        print("url.path3333......")
        print(url.path)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }
}
