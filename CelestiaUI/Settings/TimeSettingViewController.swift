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

@available(iOS 16, visionOS 1, *)
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
                                appCore.simulation.time = NSDate(julian: value) as Date
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

@available(iOS 16, visionOS 1, *)
public class TimeSettingSUIViewController: UIHostingController<TimeSettings> {
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

public class TimeSettingViewController: UICollectionViewController {
    private enum Section {
        case time
    }

    private enum Item {
        case selectTime
        case julianDay
        case setToCurrent
    }

    private let core: AppCore
    private let executor: AsyncProviderExecutor
    private let dateInputHandler: (_ viewController: UIViewController, _ title: String, _ format: String) async -> Date?
    private let textInputHandler: (_ viewController: UIViewController, _ title: String, _ keyboardType: UIKeyboardType) async -> String?

    private lazy var dataSource: UICollectionViewDiffableDataSource<Section, Item> = {
        let displayDateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter
        }()
        let displayNumberFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 4
            formatter.usesGroupingSeparator = false
            return formatter
        }()
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { [weak self] cell, indexPath, itemIdentifier in
            var contentConfiguration = UIListContentConfiguration.celestiaValueCell()
            let text: String
            var secondaryText: String?
            switch itemIdentifier {
            case .selectTime:
                text = CelestiaString("Select Time", comment: "Select simulation time")
                if let self {
                    secondaryText = displayDateFormatter.string(from: self.core.simulation.time)
                }
            case .julianDay:
                text = CelestiaString("Julian Day", comment: "Select time via entering Julian day")
                if let self {
                    secondaryText = displayNumberFormatter.string(from: (self.core.simulation.time as NSDate).julianDay)
                }
            case .setToCurrent:
                text = CelestiaString("Set to Current Time", comment: "Set simulation time to device")
                secondaryText = nil
            }
            contentConfiguration.text = text
            contentConfiguration.secondaryText = secondaryText
            cell.contentConfiguration = contentConfiguration
        }
        let dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
        return dataSource
    }()

    public init(
        core: AppCore,
        executor: AsyncProviderExecutor,
        dateInputHandler: @escaping (_ viewController: UIViewController, _ title: String, _ format: String) async -> Date?,
        textInputHandler: @escaping (_ viewController: UIViewController, _ title: String, _ keyboardType: UIKeyboardType) async -> String?
    ) {
        self.core = core
        self.executor = executor
        self.dateInputHandler = dateInputHandler
        self.textInputHandler = textInputHandler
        super.init(collectionViewLayout: UICollectionViewCompositionalLayout.list(using: UICollectionLayoutListConfiguration(appearance: .defaultGrouped)))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        setUp()
    }
}

private extension TimeSettingViewController {
    func setUp() {
        title = CelestiaString("Current Time", comment: "")
        windowTitle = title

        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.time])
        snapshot.appendItems([.selectTime, .julianDay, .setToCurrent], toSection: .time)
        dataSource.applySnapshotUsingReloadData(snapshot)
    }
}

extension TimeSettingViewController {
    public override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        switch item {
        case .selectTime:
            let preferredFormat = DateFormatter.dateFormat(fromTemplate: "yyyyMMddHHmmss", options: 0, locale: Locale.current) ?? "yyyy/MM/dd HH:mm:ss"
            let title = String.localizedStringWithFormat(CelestiaString("Please enter the time in \"%@\" format.", comment: ""), preferredFormat)
            Task {
                guard let date = await dateInputHandler(self, title, preferredFormat) else {
                    self.showError(CelestiaString("Unrecognized time string.", comment: "String not in correct format"))
                    return
                }
                await self.executor.run { core in
                    core.simulation.time = date
                }
                var snapshot = dataSource.snapshot()
                snapshot.reloadItems([.selectTime, .julianDay])
                await self.dataSource.apply(snapshot)
            }
        case .julianDay:
            Task {
                guard let text = await textInputHandler(self, CelestiaString("Please enter Julian day.", comment: "In time settings, enter Julian day for the simulation"), .decimalPad) else {
                    return
                }
                let numberFormatter = NumberFormatter()
                numberFormatter.usesGroupingSeparator = false
                guard let value = numberFormatter.number(from: text)?.doubleValue else {
                    self.showError(CelestiaString("Invalid Julian day string.", comment: "The input of julian day is not valid"))
                    return
                }
                await self.executor.run { core in
                    core.simulation.time = NSDate(julian: value) as Date
                }
                var snapshot = dataSource.snapshot()
                snapshot.reloadItems([.selectTime, .julianDay])
                await self.dataSource.apply(snapshot)
            }
        case .setToCurrent:
            Task {
                await executor.run {
                    $0.receive(.currentTime)
                }
                var snapshot = dataSource.snapshot()
                snapshot.reloadItems([.selectTime, .julianDay])
                await self.dataSource.apply(snapshot)
            }
        }
    }
}
