//
//  SlideInPresentationManager.swift
//  MobileCelestia
//
//  Created by 李林峰 on 2020/2/23.
//  Copyright © 2020 李林峰. All rights reserved.
//

import UIKit

final class SlideInPresentationAnimator: NSObject {
    // MARK: - Properties
    let direction: SlideInPresentationManager.PresentationDirection
    let isPresentation: Bool

    // MARK: - Initializers
    init(direction: SlideInPresentationManager.PresentationDirection, isPresentation: Bool) {
        self.direction = direction
        self.isPresentation = isPresentation
        super.init()
    }
}

extension SlideInPresentationAnimator: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let key: UITransitionContextViewControllerKey = isPresentation ? .to : .from

        guard let controller = transitionContext.viewController(forKey: key)
            else { return }

        if isPresentation {
            transitionContext.containerView.addSubview(controller.view)
        }

        let presentedFrame = transitionContext.finalFrame(for: controller)
        var dismissedFrame = presentedFrame
        switch direction {
        case .left:
            dismissedFrame.origin.x = -presentedFrame.width
        case .right:
            dismissedFrame.origin.x = transitionContext.containerView.frame.size.width
        case .top:
            dismissedFrame.origin.y = -presentedFrame.height
        case .bottom, .bottomLeft, .bottomRight:
            dismissedFrame.origin.y = transitionContext.containerView.frame.size.height
        }

        let initialFrame = isPresentation ? dismissedFrame : presentedFrame
        let finalFrame = isPresentation ? presentedFrame : dismissedFrame

        let animationDuration = transitionDuration(using: transitionContext)
        controller.view.frame = initialFrame
        UIView.animate(withDuration: animationDuration, animations: {
            controller.view.frame = finalFrame
        }, completion: { finished in
            if !self.isPresentation {
                controller.view.removeFromSuperview()
            }
            transitionContext.completeTransition(finished)
        })
    }
}

class SlideInPresentationManager: NSObject {
    enum PresentationDirection {
        case left
        case top
        case right
        case bottom
        case bottomLeft
        case bottomRight
    }

    private let direction: PresentationDirection
    private let usesFormSheetForRegular: Bool

    private var currentTraitCollection: UITraitCollection?

    init(direction: PresentationDirection, usesFormSheetForRegular: Bool = false) {
        self.direction = direction
        self.usesFormSheetForRegular = usesFormSheetForRegular
        super.init()
    }
}

extension UIViewController {
    private struct AssociatedKeys {
        static var formSheetPreferredContentSize: UInt8 = 0
        static var regularPreferredContentSize: UInt8 = 0
    }

    var formSheetPreferredContentSize: CGSize {
        get { return objc_getAssociatedObject(self, &AssociatedKeys.formSheetPreferredContentSize) as? CGSize ?? regularPreferredContentSize }
        set { objc_setAssociatedObject(self, &AssociatedKeys.formSheetPreferredContentSize, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    var regularPreferredContentSize: CGSize {
        get { return objc_getAssociatedObject(self, &AssociatedKeys.regularPreferredContentSize) as? CGSize ?? preferredContentSize }
        set { objc_setAssociatedObject(self, &AssociatedKeys.regularPreferredContentSize, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

extension SlideInPresentationManager: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let pc = SlideInPresentationController(presentedViewController: presented, presenting: presenting, direction: direction)
        pc.delegate = self
        return pc
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if #available(iOS 13.0, *), currentTraitCollection?.verticalSizeClass == .regular && currentTraitCollection?.horizontalSizeClass == .regular && usesFormSheetForRegular {
            return nil
        }
        return SlideInPresentationAnimator(direction: direction, isPresentation: true)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if #available(iOS 13.0, *), currentTraitCollection?.verticalSizeClass == .regular && currentTraitCollection?.horizontalSizeClass == .regular && usesFormSheetForRegular {
            return nil
        }
        return SlideInPresentationAnimator(direction: direction, isPresentation: false)
    }
}

extension SlideInPresentationManager: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        if #available(iOS 13.0, *), traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular && usesFormSheetForRegular {
            currentTraitCollection = traitCollection
            controller.presentedViewController.preferredContentSize = controller.presentedViewController.formSheetPreferredContentSize
            return .formSheet
        }
        currentTraitCollection = traitCollection
        controller.presentedViewController.preferredContentSize = controller.presentedViewController.regularPreferredContentSize
        return .none
    }
}
