//
// CelestiaWidget.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import WidgetKit
import SwiftUI
import Intents

extension Object {
    var url: String {
        switch self {
        case .sun:
            return "cel://Follow/Sol/2020-11-13T14:38:58.46727?x=AEAOHPIoVYQ&y=yGngbcm5/f///////////w&z=AGC54K0DQlr//////////w&ow=0.330553&ox=-7.15294e-06&oy=-0.943787&oz=1.96857e-05&select=Sol&fov=18.0409&ts=1&ltd=0&p=0&rf=17047538583&lm=0&tsrc=0&ver=4"
        case .mercury:
            return "cel://Follow/Sol:Mercury/2020-11-13T14:39:31.26669?x=sK66FQFyZQ&y=1QxElap38v///////////w&z=9hIJmWdWMg&ow=0.848367&ox=-0.0508207&oy=-0.526063&oz=0.0308157&select=Sol:Mercury&fov=18.0409&ts=1&ltd=0&p=0&rf=17047538583&lm=0&tsrc=0&ver=4"
        case .venus:
            return "cel://Follow/Sol:Venus/2020-11-13T14:39:49.44885?x=wIrUQ9pEGwE&y=6KWtooMS&z=7IJOA3llXQ&ow=0.810253&ox=-0.005209&oy=-0.586011&oz=-0.00740915&select=Sol:Venus&fov=18.0409&ts=1&ltd=0&p=0&rf=17047538583&lm=0&tsrc=0&ver=4"
        case .mars:
            return "cel://Follow/Sol:Mars/2020-11-13T14:40:14.13256?x=GPrTOTfwav///////////w&y=bUxJhHY3BA&z=aOc3Y/nwMQ&ow=0.81154&ox=0.00668523&oy=0.584099&oz=0.013664&select=Sol:Mars&fov=18.0409&ts=1&ltd=0&p=0&rf=17047538583&lm=0&tsrc=0&ver=4"
        case .jupiter:
            return "cel://Follow/Sol:Jupiter/2020-11-13T14:40:34.56504?x=hD6uUzibDfz//////////w&y=JDHudmfNFQ&z=nt+mCrZWQvP//////////w&ow=-0.149667&ox=-0.0138925&oy=-0.988638&oz=-0.00112605&select=Sol:Jupiter&fov=18.0409&ts=1&ltd=0&p=0&rf=17047538583&lm=0&tsrc=0&ver=4"
        case .saturn:
            return "cel://Follow/Sol:Saturn/2020-11-13T14:40:55.39824?x=ExVXAYHVoPb//////////w&y=PYcu+LQCEg&z=MzRtACxGjPD//////////w&ow=-0.269233&ox=-0.0124565&oy=-0.962993&oz=0.00146129&select=Sol:Saturn&fov=18.0409&ts=1&ltd=0&p=0&rf=17047538583&lm=0&tsrc=0&ver=4"
        case .uranus:
            return "cel://Follow/Sol:Uranus/2020-11-13T14:41:05.29841?x=7PAQcMaCXf3//////////w&y=H7f1+1cZBg&z=TC/2cqtuYAU&ow=0.974122&ox=5.78597e-05&oy=0.225862&oz=0.00855889&select=Sol:Uranus&fov=18.0409&ts=1&ltd=0&p=0&rf=17047538583&lm=0&tsrc=0&ver=4"
        case .neptune:
            return "cel://Follow/Sol:Neptune/2020-11-13T14:41:23.98107?x=jL2HEVOHafz//////////w&y=JOh0/48oGw&z=yI1m0kmkc/v//////////w&ow=-0.3278&ox=-0.00809666&oy=-0.944687&oz=-0.00688155&select=Sol:Neptune&fov=18.0409&ts=1&ltd=0&p=0&rf=17047538583&lm=0&tsrc=0&ver=4"
        case .moon:
            return "cel://Follow/Sol:Earth:Moon/2020-11-13T14:41:44.38056?x=SV4gMt4XZA&y=OQAC+zkH/v///////////w&z=bkCDi0VeFQ&ow=0.777401&ox=-0.008553&oy=-0.628929&oz=0.00474078&select=Sol:Earth:Moon&fov=18.0409&ts=1&ltd=0&p=0&rf=17047538583&lm=0&tsrc=0&ver=4"
        case .unknown:
            fallthrough
        case .earth:
            return "cel://Follow/Sol:Earth/2020-11-13T14:38:31.20031?x=AD8t+DIZOf///////////w&y=JDPFsX/7/////////////w&z=OP4pDRi8/Q&ow=0.945255&ox=-2.57756e-05&oy=0.326333&oz=-8.89859e-06&select=Sol:Earth&fov=18.0409&ts=1&ltd=0&p=0&rf=17047538583&lm=0&tsrc=0&ver=4"
        }
    }
}

struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), image: UIImage(), configuration: ConfigurationIntent())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), image: UIImage(), configuration: configuration)
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let nextUpdateTime = Date().addingTimeInterval(3 * 60 * 60)
        let scale = context.environmentVariants.displayScale?.first ?? 1
        let image = Renderer.render(size: context.displaySize, scale: scale, url: configuration.object.url)

        let entry = SimpleEntry(date: Date(), image: image, configuration: configuration)
        completion(.init(entries: [entry], policy: .after(nextUpdateTime)))
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let image: UIImage?
    let configuration: ConfigurationIntent
}

struct CelestiaWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        if let image = entry.image {
            Image(uiImage: image).resizable()
        } else {
            Text("Failed to load")
        }
    }
}

@main
struct CelestiaWidget: Widget {
    let kind: String = "CelestiaWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            CelestiaWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

struct CelestiaWidget_Previews: PreviewProvider {
    static var previews: some View {
        CelestiaWidgetEntryView(entry: SimpleEntry(date: Date(), image: UIImage(), configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
