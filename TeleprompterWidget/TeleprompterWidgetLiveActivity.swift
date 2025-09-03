//
//  TeleprompterWidgetLiveActivity.swift
//  TeleprompterWidget
//
//  Created by abaig on 21/08/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct TeleprompterWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct TeleprompterWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TeleprompterWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension TeleprompterWidgetAttributes {
    fileprivate static var preview: TeleprompterWidgetAttributes {
        TeleprompterWidgetAttributes(name: "World")
    }
}

extension TeleprompterWidgetAttributes.ContentState {
    fileprivate static var smiley: TeleprompterWidgetAttributes.ContentState {
        TeleprompterWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: TeleprompterWidgetAttributes.ContentState {
         TeleprompterWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: TeleprompterWidgetAttributes.preview) {
   TeleprompterWidgetLiveActivity()
} contentStates: {
    TeleprompterWidgetAttributes.ContentState.smiley
    TeleprompterWidgetAttributes.ContentState.starEyes
}
