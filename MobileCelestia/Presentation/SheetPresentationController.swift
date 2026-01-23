// SheetPresentationController.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

#if !targetEnvironment(macCatalyst)
import CelestiaUI
import UIKit

class Grabber: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerCurve = .continuous
        backgroundColor = .tertiaryLabel

        addInteraction(UIPointerInteraction(delegate: self))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }
}

extension Grabber: UIPointerInteractionDelegate {
    func pointerInteraction(_ interaction: UIPointerInteraction, regionFor request: UIPointerRegionRequest, defaultRegion: UIPointerRegion) -> UIPointerRegion? {
        return defaultRegion
    }

    func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
        return UIPointerStyle(effect: .highlight(UITargetedPreview(view: self)))
    }
}

class SheetPresentationController: UIPresentationController {
    private enum Constants {
        static let sheetHandleBaseHeight: CGFloat = 6
        static let sheetHandleBaseWidth: CGFloat = 35
        static let sheetHandleContainerCornerRadius: CGFloat = 6
        static let sheetCloseButtonPadding: CGFloat = 5
        static let sheetMaxHeightRatio: CGFloat = 0.9
        static let sheetMinWidthRatio: CGFloat = 0.3
        static let sheetMaxWidthRatio: CGFloat = 0.5
    }

    private lazy var closeButton: UIButton = {
        var configuration: UIButton.Configuration = .plain()
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(textStyle: .footnote)
        configuration.image = UIImage(systemName: "xmark")
        configuration.contentInsets = NSDirectionalEdgeInsets(top: Constants.sheetCloseButtonPadding, leading: Constants.sheetCloseButtonPadding, bottom: Constants.sheetCloseButtonPadding, trailing: Constants.sheetCloseButtonPadding)
        let button = StandardButton(configuration: configuration)
        button.adjustsImageSizeForAccessibilityContentSizeCategory = true
        button.tintColor = .secondaryLabel
        button.addTarget(self, action: #selector(dismissPresentedViewController), for: .touchUpInside)
        return button
    }()

    private class SheetHandle: UIView, UIContentSizeCategoryAdjusting {
        var adjustsFontForContentSizeCategory = true
    }

    private lazy var sheetHandle: UIView = {
        let handleView = SheetHandle()
        let grabber = AnyAutoSizingView(viewBuilder: Grabber(), baseSize: CGSize(width: Constants.sheetHandleBaseWidth, height: Constants.sheetHandleBaseHeight))
        handleView.addSubview(grabber)
        let closeButtonContainer = UIView()
        closeButtonContainer.translatesAutoresizingMaskIntoConstraints = false
        handleView.addSubview(closeButtonContainer)
        closeButtonContainer.addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        grabber.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            grabber.centerXAnchor.constraint(equalTo: handleView.centerXAnchor),
            grabber.centerYAnchor.constraint(equalTo: handleView.centerYAnchor),
            closeButtonContainer.heightAnchor.constraint(equalTo: handleView.heightAnchor),
            closeButtonContainer.widthAnchor.constraint(equalTo: closeButtonContainer.heightAnchor),
            closeButtonContainer.leadingAnchor.constraint(equalTo: handleView.leadingAnchor),
            closeButtonContainer.centerYAnchor.constraint(equalTo: handleView.centerYAnchor),

            closeButton.heightAnchor.constraint(equalTo: closeButtonContainer.heightAnchor),
            closeButton.widthAnchor.constraint(equalTo: closeButtonContainer.widthAnchor),
            closeButton.centerXAnchor.constraint(equalTo: closeButtonContainer.centerXAnchor),
            closeButton.centerYAnchor.constraint(equalTo: closeButtonContainer.centerYAnchor),
        ])
        handleView.maximumContentSizeCategory = .extraExtraExtraLarge
        return handleView
    }()

    private lazy var sheetContainer: UIView = {
        let sheetContainer = UIView()
        sheetContainer.backgroundColor = .secondarySystemBackground
        sheetContainer.addSubview(sheetHandle)
        sheetContainer.layer.cornerRadius = Constants.sheetHandleContainerCornerRadius
        sheetContainer.clipsToBounds = true
        sheetHandle.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sheetHandle.leadingAnchor.constraint(equalTo: sheetContainer.leadingAnchor),
            sheetHandle.trailingAnchor.constraint(equalTo: sheetContainer.trailingAnchor),
            sheetHandle.topAnchor.constraint(equalTo: sheetContainer.topAnchor),
        ])
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        sheetHandle.addGestureRecognizer(gesture)
        return sheetContainer
    }()

    private var sheetHandleContainerHeight: CGFloat {
        return sheetHandle.systemLayoutSizeFitting(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)).height
    }

    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)

        if #available(iOS 17, *) {
            sheetHandle.registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { [weak self] (_: UIView, _) in
                guard let self else { return }
                self.preferredContentSizeCategoryChanged()
            }
        }
    }

    override func containerViewWillLayoutSubviews() {
        guard let presented = presentedView else { return }

        let viewFrame = frameOfPresentedViewInContainerView
        presented.frame = viewFrame

        let handleHeight = sheetHandleContainerHeight
        sheetContainer.frame = CGRect(origin: CGPoint(x: viewFrame.minX, y: viewFrame.minY - handleHeight), size: CGSize(width: viewFrame.width, height: viewFrame.height + handleHeight))
    }

    override func size(forChildContentContainer container: UIContentContainer,
                       withParentContainerSize parentSize: CGSize) -> CGSize {
        var size: CGSize = .zero
        let safeAreaInsets = containerView?.safeAreaInsets ?? .zero
        let height = min(parentSize.height - safeAreaInsets.top, parentSize.height * Constants.sheetMaxHeightRatio) - sheetHandleContainerHeight
        if presentingViewController.traitCollection.horizontalSizeClass == .compact && presentingViewController.traitCollection.verticalSizeClass == .regular {
            size = CGSize(width: parentSize.width, height: height)
        } else {
            let containerWidth = parentSize.width
            var widthUpperBound = containerWidth - safeAreaInsets.left - safeAreaInsets.right - 2 * GlobalConstants.pageMediumMarginHorizontal
            widthUpperBound = min(widthUpperBound, containerWidth * Constants.sheetMaxWidthRatio)
            let widthLowerBound = min(widthUpperBound, containerWidth * Constants.sheetMinWidthRatio)
            let width = max(widthLowerBound, min(widthUpperBound, presentedViewController.preferredContentSize.width))
            size = CGSize(width: width, height: height)
        }
        return size
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        var frame: CGRect = .zero
        frame.size = size(forChildContentContainer: presentedViewController,
                          withParentContainerSize: containerView!.bounds.size)
        if presentingViewController.traitCollection.horizontalSizeClass == .compact && presentingViewController.traitCollection.verticalSizeClass == .regular {
            frame.origin = CGPoint(x: 0, y: containerView!.frame.height - frame.height)
        } else {
            if presentingViewController.traitCollection.layoutDirection == .rightToLeft {
                frame.origin = CGPoint(x: containerView!.frame.width - containerView!.safeAreaInsets.right - frame.width - GlobalConstants.pageMediumMarginHorizontal, y: containerView!.frame.height - frame.height)
            } else {
                frame.origin = CGPoint(x: containerView!.safeAreaInsets.left + GlobalConstants.pageMediumMarginHorizontal, y: containerView!.frame.height - frame.height)
            }
        }
        return frame
    }

    override func presentationTransitionWillBegin() {
        containerView?.insertSubview(sheetContainer, at: 0)
        if let container = containerView, container.responds(to: NSSelectorFromString("setIgnoreDirectTouchEvents:")) {
            container.setValue(true, forKey: "ignoreDirectTouchEvents")
        }

        let viewFrame = frameOfPresentedViewInContainerView

        let handleHeight = sheetHandleContainerHeight
        let sheetContainerFrameFrom = CGRect(x: viewFrame.minX, y: containerView!.frame.height - handleHeight, width: viewFrame.width, height: viewFrame.height + handleHeight)
        let sheetContainerFrameTo = CGRect(x: viewFrame.minX, y: containerView!.frame.height - handleHeight - viewFrame.height, width: viewFrame.width, height: viewFrame.height + handleHeight)

        sheetContainer.frame = sheetContainerFrameFrom

        guard let transitionCoordinator = presentedViewController.transitionCoordinator else {
            sheetContainer.frame = sheetContainerFrameTo
            return
        }

        transitionCoordinator.animate(alongsideTransition: { [weak self] _ in
            self?.sheetContainer.frame = sheetContainerFrameTo
        })
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 17, *) {
        } else {
            if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
                preferredContentSizeCategoryChanged()
            }
        }
    }

    override func dismissalTransitionWillBegin() {
        let viewFrame = frameOfPresentedViewInContainerView
        let handleHeight = sheetHandle.frame.height
        let sheetContainerFrameTo = CGRect(x: viewFrame.minX, y: containerView!.frame.height - handleHeight, width: viewFrame.width, height: viewFrame.height + handleHeight)

        guard let coordinator = presentedViewController.transitionCoordinator else {
            sheetContainer.frame = sheetContainerFrameTo
            return
        }

        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.sheetContainer.frame = sheetContainerFrameTo
        })
    }
}

private extension SheetPresentationController {
    private func preferredContentSizeCategoryChanged() {
        if containerView != nil, let presented = presentedView {
            let viewFrame = frameOfPresentedViewInContainerView
            presented.frame = viewFrame

            let handleHeight = sheetHandleContainerHeight
            sheetContainer.frame = CGRect(origin: CGPoint(x: viewFrame.minX, y: viewFrame.minY - handleHeight), size: CGSize(width: viewFrame.width, height: viewFrame.height + handleHeight))
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let presented = presentedView else { return }
        guard let containerView = containerView else { return }

        switch gesture.state {
        case .began, .changed:
            let handleHeight = sheetHandle.frame.height
            var y = sheetContainer.frame.minY + gesture.translation(in: sheetHandle).y
            y = min(
                max(
                    containerView.frame.height * (1 - Constants.sheetMaxHeightRatio),
                    containerView.safeAreaInsets.top,
                    y
                ),
                containerView.frame.height - handleHeight - containerView.safeAreaInsets.bottom
            )
            presented.frame.origin = CGPoint(x: presented.frame.minX, y: y + handleHeight)
            sheetContainer.frame.origin = CGPoint(x: sheetContainer.frame.minX, y: y)
            gesture.setTranslation(.zero, in: sheetHandle)
        default:
            break
        }
    }

    @objc private func dismissPresentedViewController() {
        presentingViewController.dismiss(animated: true, completion: nil)
    }
}
#endif
