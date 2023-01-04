//
// TimelineControlViewController.swift
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaCore
import UIKit

final class TimelineControlViewController: UIViewController {
    private let timePoints: [Date]
    private let startTime: Date
    private let endTime: Date

    private let core = AppCore.shared

    override func loadView() {
        let container = UIView()
        if #available(iOS 15, *) {
            container.maximumContentSizeCategory = .extraExtraExtraLarge
        }
        let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(backgroundView)

        NSLayoutConstraint.activate([
            backgroundView.trailingAnchor.constraint(equalTo: container.safeAreaLayoutGuide.trailingAnchor, constant: -GlobalConstants.pageMediumMarginHorizontal),
            backgroundView.topAnchor.constraint(equalTo: container.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: container.safeAreaLayoutGuide.leadingAnchor, constant: GlobalConstants.pageMediumMarginHorizontal),
            backgroundView.bottomAnchor.constraint(equalTo: container.safeAreaLayoutGuide.bottomAnchor, constant: -GlobalConstants.pageMediumMarginVertical)
        ])

        backgroundView.layer.masksToBounds = true
        backgroundView.layer.cornerRadius = GlobalConstants.bottomControlContainerCornerRadius
        backgroundView.layer.cornerCurve = .continuous

        let contentView = backgroundView.contentView
        let hideButton = ToolbarImageButton(image: UIImage(systemName: "chevron.down")?.withConfiguration(UIImage.SymbolConfiguration(weight: .black)), touchDownHandler: nil) { [weak self] _, inside in
            if inside, let self {
                self.presentedViewController?.dismiss(animated: true)
            }
        }

        let buttonContainer = AnyAutoSizingView(viewBuilder: {
            let view = UIView()
            view.addSubview(hideButton)
            hideButton.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                hideButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                hideButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            ])
            return view
        }(), baseSize: CGSize(width: GlobalConstants.bottomControlViewDimension, height: GlobalConstants.bottomControlViewDimension))

        contentView.addSubview(buttonContainer)
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            buttonContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -GlobalConstants.bottomControlViewMarginHorizontal),
            buttonContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])

        let slider = TimelineSlider()
        slider.valueFrom = startTime.timeIntervalSince1970
        slider.valueTo = endTime.timeIntervalSince1970
        slider.value = slider.valueFrom
        slider.ticks = timePoints.map { CGFloat($0.timeIntervalSince1970) }
        let sliderContainer = AnyAutoSizingView(viewBuilder: slider, baseSize: CGSize(width: 1, height: GlobalConstants.timeSliderViewBaseHeight))
        contentView.addSubview(sliderContainer)
        sliderContainer.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            sliderContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: GlobalConstants.bottomControlViewMarginHorizontal + GlobalConstants.timeSliderViewMarginHorizontal),
            sliderContainer.trailingAnchor.constraint(equalTo: buttonContainer.leadingAnchor, constant: -GlobalConstants.timeSliderViewMarginHorizontal),
            sliderContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
        sliderContainer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        sliderContainer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        // buttons and spacers should keep their sizes
        buttonContainer.setContentHuggingPriority(.required, for: .horizontal)
        buttonContainer.setContentCompressionResistancePriority(.required, for: .horizontal)
        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)

        core.run { core in
            let time = core.simulation.time
            DispatchQueue.main.async {
                slider.value = time.timeIntervalSince1970
            }
        }
        view = container
    }

    @objc private func sliderValueChanged(_ sender: TimelineSlider) {
        let date = Date(timeIntervalSince1970: sender.value)
        core.run { core in
            core.simulation.time = date
        }
    }

    init(startTime: Date, endTime: Date, timePoints: [Date]) {
        self.startTime = startTime
        self.endTime = endTime
        self.timePoints = timePoints
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredContentSize: CGSize {
        get {
            let scaling = view.textScaling * GlobalConstants.preferredUIElementScaling(for: view.traitCollection)
            return CGSize(
                width: 0,
                height: (GlobalConstants.bottomControlViewDimension * scaling + GlobalConstants.bottomControlViewMarginVertical * 2 + GlobalConstants.pageMediumMarginVertical).rounded(.up)
            )
        }
        set {}
    }
}
