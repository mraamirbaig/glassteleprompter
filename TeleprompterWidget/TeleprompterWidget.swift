//
//  TeleprompterWidget.swift
//  TeleprompterWidget
//
//  Created by abaig on 21/08/2025.
//
//
//  TeleprompterWidget.swift
//  TeleprompterWidget
//
//  Created by abaig on 21/08/2025.
//

import WidgetKit
import SwiftUI
import ActivityKit

struct TeleprompterWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TeleprompterAttributes.self) { context in
            // Lock Screen / Standalone
            ZStack {
                Color.black
                VStack {
                    HStack {Text(context.state.text)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(1)               // allow only 1 line
                            .truncationMode(.tail)
                        Spacer()
                        Image(systemName: "eyeglasses")
                            .foregroundColor(context.state.isGlassesConnected ? .green : .red)
                    }
                    if let image = TeleprompterWidgetManager.shared.loadImageFromCache(imageID: context.state.imageID) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                    }
                }
                .padding()
            }
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    VStack {
                        if let image = TeleprompterWidgetManager.shared.loadImageFromCache(imageID: context.state.imageID) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: 150)
                        }
                        Text(context.state.text)
                            .font(.headline)
                    }
                }
            } compactLeading: {
                Text("Teleprompter")
            } compactTrailing: {
                Text("Live")
            } minimal: {
                Image(systemName: "photo")
            }
            .widgetURL(URL(string: "teleprompter://live"))
            .keylineTint(.red)
        }
    }
}
