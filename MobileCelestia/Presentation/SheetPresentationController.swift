//
// SheetPresentationController.swift
//
// Copyright © 2021 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

class SheetPresentationController: UIPresentationController {
    private enum Constants {
        static let sheetHandleHeight: CGFloat = 30
        static let sheetMaxHeightRatio: CGFloat = 0.9
        static let sheetPaddingHorizontal: CGFloat = 16
        static let sheetMinWidthRatio: CGFloat = 0.3
        static let sheetMaxWidthRatio: CGFloat = 0.5
    }

    private lazy var sheetHandle: UIView = {
        let handleView = UIView()
        let grabber = UIView()
        let closeButton = StandardButton(type: .system)
        if #available(iOS 13.0, *) {
            grabber.backgroundColor = .tertiaryLabel
            closeButton.tintColor = .secondaryLabel
        } else {
            grabber.backgroundColor = .darkTertiaryLabel
            closeButton.tintColor = .darkSecondaryLabel
        }
        closeButton.setImage(UIImage(named: "accessory_close"), for: .normal)
        closeButton.addTarget(self, action: #selector(dismissPresentedViewController), for: .touchUpInside)
        handleView.addSubview(grabber)
        handleView.addSubview(closeButton)
        grabber.layer.cornerRadius = 3
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        grabber.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            grabber.centerXAnchor.constraint(equalTo: handleView.centerXAnchor),
            grabber.centerYAnchor.constraint(equalTo: handleView.centerYAnchor),
            grabber.widthAnchor.constraint(equalToConstant: 35),
            grabber.heightAnchor.constraint(equalToConstant: 6),
            closeButton.leadingAnchor.constraint(equalTo: handleView.leadingAnchor),
            closeButton.centerYAnchor.constraint(equalTo: handleView.centerYAnchor)
        ])
        return handleView
    }()

    private lazy var sheetContainer: UIView = {
        let sheetContainer = UIView()
        if #available(iOS 13.0, *) {
            sheetContainer.backgroundColor = .secondarySystemBackground
        } else {
            sheetContainer.backgroundColor = .darkSecondaryBackground
        }
        sheetContainer.addSubview(sheetHandle)
        sheetContainer.layer.cornerRadius = 6
        sheetContainer.clipsToBounds = true
        sheetHandle.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sheetHandle.leadingAnchor.constraint(equalTo: sheetContainer.leadingAnchor),
            sheetHandle.trailingAnchor.constraint(equalTo: sheetContainer.trailingAnchor),
            sheetHandle.topAnchor.constraint(equalTo: sheetContainer.topAnchor),
            sheetHandle.heightAnchor.constraint(equalToConstant: Constants.sheetHandleHeight)
        ])
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        sheetHandle.addGestureRecognizer(gesture)
        return sheetContainer
    }()

    override func containerViewWillLayoutSubviews() {
        guard let presented = presentedView else { return }

        let viewFrame = frameOfPresentedViewInContainerView
        presented.frame = viewFrame

        sheetContainer.frame = CGRect(origin: CGPoint(x: viewFrame.minX, y: viewFrame.minY - Constants.sheetHandleHeight), size: CGSize(width: viewFrame.width, height: viewFrame.height + Constants.sheetHandleHeight))
    }

    override func size(forChildContentContainer container: UIContentContainer,
                       withParentContainerSize parentSize: CGSize) -> CGSize {
        var size: CGSize = .zero
        let height = min(parentSize.height - containerView!.safeAreaInsets.top, parentSize.height * Constants.sheetMaxHeightRatio) - Constants.sheetHandleHeight
        if traitCollection.horizontalSizeClass == .compact && traitCollection.verticalSizeClass == .regular {
            size = CGSize(width: parentSize.width, height: height)
        } else {
            let containerWidth = parentSize.width
            var widthUpperBound = containerWidth - containerView!.safeAreaInsets.left - containerView!.safeAreaInsets.right - 2 * Constants.sheetPaddingHorizontal
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
        if traitCollection.horizontalSizeClass == .compact && traitCollection.verticalSizeClass == .regular {
            frame.origin = CGPoint(x: 0, y: containerView!.frame.height - frame.height)
        } else {
            if traitCollection.layoutDirection == .rightToLeft {
                frame.origin = CGPoint(x: containerView!.frame.width - containerView!.safeAreaInsets.right - frame.width - Constants.sheetPaddingHorizontal, y: containerView!.frame.height - frame.height)
            } else {
                frame.origin = CGPoint(x: containerView!.safeAreaInsets.left + Constants.sheetPaddingHorizontal, y: containerView!.frame.height - frame.height)
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

        let sheetContainerFrameFrom = CGRect(x: viewFrame.minX, y: containerView!.frame.height - Constants.sheetHandleHeight, width: viewFrame.width, height: viewFrame.height + Constants.sheetHandleHeight)
        let sheetContainerFrameTo = CGRect(x: viewFrame.minX, y: containerView!.frame.height - Constants.sheetHandleHeight - viewFrame.height, width: viewFrame.width, height: viewFrame.height + Constants.sheetHandleHeight)

        sheetContainer.frame = sheetContainerFrameFrom

        guard let transitionCoordinator = presentedViewController.transitionCoordinator else {
            sheetContainer.frame = sheetContainerFrameTo
            return
        }

        transitionCoordinator.animate(alongsideTransition: { [weak self] _ in
            self?.sheetContainer.frame = sheetContainerFrameTo
        })
    }

    override func dismissalTransitionWillBegin() {
        let viewFrame = frameOfPresentedViewInContainerView
        let sheetContainerFrameTo = CGRect(x: viewFrame.minX, y: containerView!.frame.height - Constants.sheetHandleHeight, width: viewFrame.width, height: viewFrame.height + Constants.sheetHandleHeight)

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
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let presented = presentedView else { return }
        guard let containerView = containerView else { return }

        switch gesture.state {
        case .began, .changed:
            var y = sheetContainer.frame.minY + gesture.translation(in: sheetHandle).y
            y = min(
                max(
                    containerView.frame.height * (1 - Constants.sheetMaxHeightRatio),
                    containerView.safeAreaInsets.top,
                    y
                ),
                containerView.frame.height - Constants.sheetHandleHeight - containerView.safeAreaInsets.bottom
            )
            presented.frame.origin = CGPoint(x: presented.frame.minX, y: y + Constants.sheetHandleHeight)
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
