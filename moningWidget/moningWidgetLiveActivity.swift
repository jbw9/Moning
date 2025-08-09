//
//  moningWidgetLiveActivity.swift
//  moningWidget
//
//  Created by Jonathan Bernard Widjajakusuma on 8/9/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct moningWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct moningWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: moningWidgetAttributes.self) { context in
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

extension moningWidgetAttributes {
    fileprivate static var preview: moningWidgetAttributes {
        moningWidgetAttributes(name: "World")
    }
}

extension moningWidgetAttributes.ContentState {
    fileprivate static var smiley: moningWidgetAttributes.ContentState {
        moningWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: moningWidgetAttributes.ContentState {
         moningWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: moningWidgetAttributes.preview) {
   moningWidgetLiveActivity()
} contentStates: {
    moningWidgetAttributes.ContentState.smiley
    moningWidgetAttributes.ContentState.starEyes
}
