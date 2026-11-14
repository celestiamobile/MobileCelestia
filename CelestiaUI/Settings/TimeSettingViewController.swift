// TimeSettingViewController.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaCore
import SwiftUI
import UIKit

public struct TimeSettings: View {
    @State private var currentTime: Date?
    @State private var showTimeInputError = false
    @State private var showJulianDayInputError = false

    let dateInputHandler: (_ title: String, _ format: String) async -> Date?
    let textInputHandler: (_ title: String, _ keyboardType: UIKeyboardType) async -> String?

    public var body: some View {
        Form {
            Section {
                if let currentTime {
                    Button {
                        Task {
                            let preferredFormat = DateFormatter.dateFormat(fromTemplate: "yyyyMMddHHmmss", options: 0, locale: Locale.current) ?? "yyyy/MM/dd HH:mm:ss"

                            guard let time = await dateInputHandler(String.localizedStringWithFormat(CelestiaString("Please enter the time in \"%@\" format.", comment: ""), preferredFormat), preferredFormat) else {
                                showTimeInputError = true
                                return
                            }

                            let newTime = await Task.detached { @CelestiaActor in
                                let appCore = CelestiaActor.appCore
                                appCore.simulation.time = time
                                return appCore.simulation.time
                            }.value
                            self.currentTime = newTime
                        }
                    } label: {
                        LabeledContent(CelestiaString("Select Time", comment: "Select simulation time"), value: currentTime, format: .dateTime)
                    }
                    .foregroundStyle(.primary)

                    Button {
                        Task {
                            guard let text = await textInputHandler(CelestiaString("Please enter Julian day.", comment: "In time settings, enter Julian day for the simulation"), .decimalPad) else {
                                return
                            }

                            let numberFormatter = NumberFormatter()
                            numberFormatter.usesGroupingSeparator = false
                            guard let value = numberFormatter.number(from: text)?.doubleValue else {
                                showJulianDayInputError = true
                                return
                            }

                            let newTime = await Task.detached { @CelestiaActor in
                                let appCore = CelestiaActor.appCore
                                appCore.simulation.julianDay = value
                                return appCore.simulation.time
                            }.value
                            self.currentTime = newTime
                        }
                    } label: {
                        LabeledContent(CelestiaString("Julian Day", comment: "Select time via entering Julian day"), value: (currentTime as NSDate).julianDay, format: .number)
                    }
                    .foregroundStyle(.primary)
                }

                Button(CelestiaString("Set to Current Time", comment: "Set simulation time to device")) {
                    Task {
                        let time = await Task { @CelestiaActor in
                            let appCore = CelestiaActor.appCore
                            appCore.receive(.currentTime)
                            return appCore.simulation.time
                        }.value
                        currentTime = time
                    }
                }
            }
        }
        .alert(CelestiaString("Unrecognized time string.", comment: "String not in correct format"), isPresented: $showTimeInputError) {}
        .alert(CelestiaString("Invalid Julian day string.", comment: "The input of julian day is not valid"), isPresented: $showJulianDayInputError) {}
        .task {
            let current = await Task.detached { @CelestiaActor in
                CelestiaActor.appCore.simulation.time
            }.value
            currentTime = current
        }
    }
}

public class TimeSettingViewController: UIHostingController<TimeSettings> {
    private class Context {
        weak var viewController: UIViewController?
    }

    public init(
        dateInputHandler: @escaping (_ viewController: UIViewController, _ title: String, _ format: String) async -> Date?,
        textInputHandler: @escaping (_ viewController: UIViewController, _ title: String, _ keyboardType: UIKeyboardType) async -> String?
    ) {
        let context = Context()
        super.init(rootView: TimeSettings(dateInputHandler: { title, format in
            guard let vc = context.viewController else { return nil }
            return await dateInputHandler(vc, title, format)
        }, textInputHandler: { title, keyboardType in
            guard let vc = context.viewController else { return nil }
            return await textInputHandler(vc, title, keyboardType)
        }))
        context.viewController = self
        title = CelestiaString("Current Time", comment: "")
        windowTitle = title
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
