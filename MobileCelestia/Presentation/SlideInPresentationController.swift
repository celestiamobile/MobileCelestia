//
// SlideInPresentationController.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

#if !targetEnvironment(macCatalyst)
import UIKit

class SlideInPresentationController: UIPresentationController {
    private var direction: PresentationManager.PresentationDirection
    private var dimmingView: UIView?

    init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?, direction: PresentationManager.PresentationDirection) {
        self.direction = direction
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)

        if #available(iOS 17, visionOS 1, *) {
            traitOverrides.userInterfaceLevel = .base
            traitOverrides.horizontalSizeClass = .compact
        } else {
            overrideTraitCollection = UITraitCollection(traitsFrom: [UITraitCollection(userInterfaceLevel: .base), UITraitCollection(horizontalSizeClass: .compact)])
        }

        setupDimmingViewIfNeeded()
    }

    override func containerViewWillLayoutSubviews() {
        presentedView?.frame = frameOfPresentedViewInContainerView
    }

    override func size(forChildContentContainer container: UIContentContainer,
                       withParentContainerSize parentSize: CGSize) -> CGSize {
        var size: CGSize = .zero
        let preferredSize = presentedViewController.preferredContentSize
        switch direction {
        case .left, .right:
            size = CGSize(width: min(preferredSize.width, parentSize.width * 0.6), height: parentSize.height)
        case .bottom, .top:
            size = CGSize(width: parentSize.width, height: preferredSize.height)
        case .bottomRight, .bottomLeft:
            size = CGSize(width: min(preferredSize.width, parentSize.width * 0.8), height: preferredSize.height)
        }
        if let safeAreaInset = containerView?.safeAreaInsets {
            switch direction {
            case .top:
                size.height += safeAreaInset.top
            case .bottom:
                size.height += safeAreaInset.bottom
            case .left:
                size.width += safeAreaInset.left
            case .right:
                size.width += safeAreaInset.right
            case .bottomLeft:
                size.width += safeAreaInset.left
                size.height += safeAreaInset.bottom
            case .bottomRight:
                size.width += safeAreaInset.right
                size.height += safeAreaInset.bottom
            }
        }
        return size
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        var frame: CGRect = .zero
        frame.size = size(forChildContentContainer: presentedViewController,
                          withParentContainerSize: containerView!.bounds.size)

        switch direction {
        case .right:
            frame.origin.x = containerView!.frame.width - frame.width
        case .bottom, .bottomLeft:
            frame.origin.y = containerView!.frame.height - frame.height
        case .bottomRight:
            frame.origin.x = containerView!.frame.width - frame.width
            frame.origin.y = containerView!.frame.height - frame.height
        default:
            frame.origin = .zero
        }
        return frame
    }

    override func presentationTransitionWillBegin() {
        guard let dimmingView = dimmingView else { return }

        containerView?.insertSubview(dimmingView, at: 0)

        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "V:|[dimmingView]|",
                                           options: [], metrics: nil, views: ["dimmingView": dimmingView]))
        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "H:|[dimmingView]|",
                                           options: [], metrics: nil, views: ["dimmingView": dimmingView]))

        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.alpha = 1.0
            return
        }

        coordinator.animate(alongsideTransition: { _ in
            self.dimmingView?.alpha = 1.0
        })
    }

    override func dismissalTransitionWillBegin() {
        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView?.alpha = 0.0
            return
        }

        coordinator.animate(alongsideTransition: { _ in
            self.dimmingView?.alpha = 0.0
        })
    }
}

private extension SlideInPresentationController {
    func setupDimmingViewIfNeeded() {
        setupDimmingView()
    }

    func setupDimmingView() {
        let dimmingView = UIView()
        dimmingView.translatesAutoresizingMaskIntoConstraints = false
        dimmingView.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
        dimmingView.alpha = 0.0
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        dimmingView.addGestureRecognizer(recognizer)

        self.dimmingView = dimmingView
    }

    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        presentingViewController.dismiss(animated: true)
    }
}
#endif
