// AboutViewController.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaCore
import CelestiaFoundation
import UIKit

public final class AboutViewController: UIViewController {
    private enum Constants {
        static let appIconDimension: CGFloat = 128
    }

    private let bundle: Bundle
    private let assetProvider: AssetProvider

    private var topMarginConstraint: NSLayoutConstraint?
    private var bottomMarginConstraint: NSLayoutConstraint?
    private var leadingMarginConstraint: NSLayoutConstraint?
    private var trailingMarginConstraint: NSLayoutConstraint?

    public init(bundle: Bundle, assetProvider: AssetProvider) {
        self.bundle = bundle
        self.assetProvider = assetProvider

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        let scrollView = UIScrollView()
        scrollView.contentInsetAdjustmentBehavior = .never

        let contentView = UIView()
        let scaling = GlobalConstants.preferredUIElementScaling(for: contentView.traitCollection)
        let iconView = IconView(image: assetProvider.image(for: .loadingIcon), baseSize: CGSize(width: Constants.appIconDimension * scaling, height: Constants.appIconDimension * scaling)) { imageView in
            imageView.contentMode = .scaleAspectFit
        }

        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        NSLayoutConstraint.activate([
            scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            scrollView.contentLayoutGuide.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.heightAnchor),
        ])

        topMarginConstraint = contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor)
        bottomMarginConstraint = contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor)
        leadingMarginConstraint = contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor)
        trailingMarginConstraint = contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor)

        NSLayoutConstraint.activate([topMarginConstraint, bottomMarginConstraint, leadingMarginConstraint, trailingMarginConstraint].compactMap({ $0 }))

        let optionalConstraint = scrollView.contentLayoutGuide.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        optionalConstraint.priority = .defaultLow
        optionalConstraint.isActive = true

        let versionLabel = UILabel(textStyle: .body)
        versionLabel.text = "Celestia \(bundle.shortVersion) (\(self.bundle.build))"

        var links = [
            LinkTextConfiguration.Link(text: "https://celestia.mobi", link: "https://celestia.mobi?lang=\(AppCore.language)")
        ]

#if !targetEnvironment(macCatalyst)
        let showICPC: Bool
        if #available(iOS 16, visionOS 1, *) {
            showICPC = Locale.current.region == .chinaMainland
        } else {
            showICPC = Locale.current.regionCode == "CN"
        }
#else
        let showICPC = false
#endif
        if showICPC {
            links.append(LinkTextConfiguration.Link(text: "苏ICP备2023039249号-4A", link: "https://beian.miit.gov.cn"))
        }

        let linksView = LinkTextConfiguration(info: LinkTextConfiguration.LinkInfo(text: links.map(\.text).joined(separator: " | "), links: links)).makeContentView()


        let topView = UIView()
        let bottomView = UIStackView(arrangedSubviews: [versionLabel, linksView])

        topView.setContentHuggingPriority(.defaultLow, for: .vertical)
        bottomView.setContentHuggingPriority(.required, for: .vertical)
        versionLabel.setContentHuggingPriority(.required, for: .vertical)
        linksView.setContentHuggingPriority(.required, for: .vertical)

        bottomView.axis = .vertical
        bottomView.spacing = GlobalConstants.pageSmallGapVertical
        bottomView.alignment = .center

        topView.translatesAutoresizingMaskIntoConstraints = false
        bottomView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(topView)
        contentView.addSubview(bottomView)

        iconView.translatesAutoresizingMaskIntoConstraints = false
        topView.addSubview(iconView)

        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(greaterThanOrEqualTo: topView.topAnchor, constant: GlobalConstants.pageMediumMarginVertical),

            iconView.centerXAnchor.constraint(equalTo: topView.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: topView.centerYAnchor),

            topView.topAnchor.constraint(equalTo: contentView.topAnchor),
            topView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            topView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            bottomView.topAnchor.constraint(equalTo: topView.bottomAnchor, constant: GlobalConstants.pageMediumGapVertical),
            bottomView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bottomView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bottomView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])

        let optionalIconViewConstraint = iconView.topAnchor.constraint(equalTo: topView.topAnchor, constant: GlobalConstants.pageMediumMarginVertical)
        optionalIconViewConstraint.priority = .defaultHigh
        optionalIconViewConstraint.isActive = true

        view = scrollView
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        setUp()
    }

    public override func updateViewConstraints() {
        let rtl = view.effectiveUserInterfaceLayoutDirection == .rightToLeft
        topMarginConstraint?.constant = GlobalConstants.pageMediumMarginVertical + view.safeAreaInsets.top
        bottomMarginConstraint?.constant = -(GlobalConstants.pageMediumMarginVertical + view.safeAreaInsets.bottom)
        leadingMarginConstraint?.constant = GlobalConstants.pageMediumMarginHorizontal + (rtl ? view.safeAreaInsets.right : view.safeAreaInsets.left)
        trailingMarginConstraint?.constant = -(GlobalConstants.pageMediumMarginHorizontal + (rtl ? view.safeAreaInsets.left : view.safeAreaInsets.right))

        super.updateViewConstraints()
    }

    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()

        view.setNeedsUpdateConstraints()
    }
}

private extension AboutViewController {
    func setUp() {
        title = CelestiaString("About", comment: "About Celestia")
        windowTitle = title
    }
}
