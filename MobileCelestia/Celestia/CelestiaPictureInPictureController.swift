// Copyright (C) 2026, Celestia Development Team
// Licensed under the GNU General Public License, version 2 or later.

#if os(iOS) && !targetEnvironment(macCatalyst)
import AsyncGL
import AVKit
import CelestiaCore
import CelestiaFoundation
import UIKit

private final class PictureInPictureVideoView: UIView {
    override class var layerClass: AnyClass { AVSampleBufferDisplayLayer.self }

    var displayLayer: AVSampleBufferDisplayLayer {
        guard let displayLayer = layer as? AVSampleBufferDisplayLayer else {
            preconditionFailure("Unexpected picture-in-picture backing layer")
        }
        return displayLayer
    }
}

// The render-thread producer owns at most one waiting frame, even when main is busy.
private final class PictureInPictureSampleSink: @unchecked Sendable {
    private let lock = NSLock()
    private var sample: CMSampleBuffer?
    private var scheduled = false
    private var stopped = false
    private let displayLayer: AVSampleBufferDisplayLayer
    private let failure: @MainActor (Error?) -> Void

    @MainActor init(displayLayer: AVSampleBufferDisplayLayer, failure: @escaping @MainActor (Error?) -> Void) {
        self.displayLayer = displayLayer
        self.failure = failure
    }

    func receive(_ sample: CMSampleBuffer) {
        let shouldSchedule = lock.withLock {
            guard !stopped else { return false }
            self.sample = sample
            guard !scheduled else { return false }
            scheduled = true
            return true
        }
        if shouldSchedule {
            DispatchQueue.main.async { [weak self] in self?.deliver() }
        }
    }

    @MainActor private func deliver() {
        let sample = lock.withLock {
            let pending = self.sample
            self.sample = nil
            scheduled = false
            return stopped ? nil : pending
        }
        guard let sample else { return }
        if displayLayer.status == .failed {
            failure(displayLayer.error)
        } else if displayLayer.isReadyForMoreMediaData {
            displayLayer.enqueue(sample)
        }
    }

    @MainActor func stop() {
        lock.withLock {
            stopped = true
            sample = nil
        }
        displayLayer.flushAndRemoveImage()
    }
}

@MainActor
final class CelestiaPictureInPictureController: NSObject {
    private weak var displayController: AsyncGLViewController?
    private weak var sourceView: UIView?
    private let userDefaults: UserDefaults
    private var controller: AVPictureInPictureController?
    private var videoView: PictureInPictureVideoView?
    private var sink: PictureInPictureSampleSink?
    private var enabled = false
    private var failed = false
    private var starting = false
    private var stopping = false
    private var shutDown = false
    private var hasAudioSessionLease = false

    init(displayController: AsyncGLViewController, sourceView: UIView, userDefaults: UserDefaults) {
        self.displayController = displayController
        self.sourceView = sourceView
        self.userDefaults = userDefaults
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(preferencesDidChange), name: UserDefaults.didChangeNotification, object: userDefaults)
        NotificationCenter.default.addObserver(self, selector: #selector(becameActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        preferencesChanged()
    }

    @objc nonisolated private func preferencesDidChange() {
        Task { @MainActor [weak self] in self?.preferencesChanged() }
    }

    private func preferencesChanged() {
        guard !shutDown else { return }
        let enabled = userDefaults[.automaticPictureInPicture] == true
        guard self.enabled != enabled else { return }
        self.enabled = enabled
        failed = false
        if enabled {
            if controller == nil { prepare() }
        } else {
            stop()
        }
    }

    private func prepare() {
        guard !shutDown, enabled, !failed, controller == nil,
              let displayController, let glView = displayController.glView,
              let sourceView else { return }
        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            NSLog("Picture in Picture is not supported on this device.")
            return
        }

        do {
            if !hasAudioSessionLease {
                try AppCore.acquirePictureInPictureAudioSession()
                hasAudioSessionLease = true
            }
        } catch {
            NSLog("Could not activate audio for Picture in Picture: %@", error.localizedDescription)
            tearDown()
            return
        }

        let videoView = PictureInPictureVideoView(frame: sourceView.bounds)
        videoView.isUserInteractionEnabled = false
        videoView.accessibilityElementsHidden = true
        videoView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        videoView.displayLayer.videoGravity = .resizeAspect
        sourceView.insertSubview(videoView, at: 0)
        self.videoView = videoView

        let sink = PictureInPictureSampleSink(displayLayer: videoView.displayLayer) { [weak self] error in
            NSLog("Picture in Picture sample display failed: %@", error?.localizedDescription ?? "No display-layer error supplied")
            self?.failed = true
            self?.sink?.stop()
            self?.stop()
        }
        self.sink = sink
        do {
            try glView.startSampleBufferOutput(withMaximumSize: CGSize(width: 1024, height: 1024)) { @Sendable sample in
                sink.receive(sample)
            }
        } catch {
            NSLog("Could not start Picture in Picture sample output: %@", error.localizedDescription)
            tearDown()
            return
        }

        let contentSource = AVPictureInPictureController.ContentSource(sampleBufferDisplayLayer: videoView.displayLayer, playbackDelegate: self)
        let controller = AVPictureInPictureController(contentSource: contentSource)
        controller.delegate = self
        controller.requiresLinearPlayback = true
        controller.canStartPictureInPictureAutomaticallyFromInline = true
        self.controller = controller
    }

    @objc private func becameActive() {
        if starting || controller?.isPictureInPictureActive == true {
            stop()
        }
    }

    private func stop() {
        controller?.canStartPictureInPictureAutomaticallyFromInline = false
        if controller?.isPictureInPictureActive == true || starting {
            stopping = true
            controller?.stopPictureInPicture()
        } else {
            tearDown()
        }
    }

    private func tearDown() {
        displayController?.rendersWhileOffscreen = false
        sink?.stop()
        if sink != nil {
            displayController?.glView?.stopSampleBufferOutput()
        }
        let previousController = controller
        controller = nil
        previousController?.delegate = nil
        previousController?.canStartPictureInPictureAutomaticallyFromInline = false
        previousController?.stopPictureInPicture()
        sink = nil
        videoView?.removeFromSuperview()
        videoView = nil
        stopping = false
        starting = false
        if hasAudioSessionLease {
            hasAudioSessionLease = false
            do {
                try AppCore.releasePictureInPictureAudioSession()
            } catch {
                NSLog("Could not restore audio after Picture in Picture: %@", error.localizedDescription)
            }
        }
    }

    private func finishPictureInPicture() {
        starting = false
        displayController?.rendersWhileOffscreen = false
        if stopping || !enabled {
            tearDown()
            prepare()
        }
    }

    func shutdown() {
        guard !shutDown else { return }
        shutDown = true
        NotificationCenter.default.removeObserver(self)
        controller?.canStartPictureInPictureAutomaticallyFromInline = false
        controller?.stopPictureInPicture()
        tearDown()
    }
}

extension CelestiaPictureInPictureController: @preconcurrency AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        guard pictureInPictureController === controller else { return }
        starting = true
        guard enabled, !shutDown, !failed, !stopping else {
            stop()
            return
        }
        displayController?.rendersWhileOffscreen = true
    }

    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        guard pictureInPictureController === controller else { return }
        starting = false
        if !enabled || stopping || shutDown || UIApplication.shared.applicationState == .active {
            stop()
        }
    }

    func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        guard pictureInPictureController === controller else { return }
        starting = false
        displayController?.rendersWhileOffscreen = false
    }

    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        guard pictureInPictureController === controller else { return }
        finishPictureInPicture()
    }

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        guard pictureInPictureController === controller else { return }
        NSLog("Could not start Picture in Picture: %@", error.localizedDescription)
        finishPictureInPicture()
    }

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        completionHandler(sourceView?.window != nil)
    }
}

extension CelestiaPictureInPictureController: AVPictureInPictureSampleBufferPlaybackDelegate {
    nonisolated func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, setPlaying playing: Bool) {
        // This is a live simulation, not seekable media; PiP must not pause its renderer.
    }

    nonisolated func pictureInPictureControllerTimeRangeForPlayback(_ pictureInPictureController: AVPictureInPictureController) -> CMTimeRange {
        CMTimeRange(start: .negativeInfinity, duration: .positiveInfinity)
    }

    nonisolated func pictureInPictureControllerIsPlaybackPaused(_ pictureInPictureController: AVPictureInPictureController) -> Bool { false }

    nonisolated func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, didTransitionToRenderSize newRenderSize: CMVideoDimensions) {}

    nonisolated func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, skipByInterval skipInterval: CMTime, completion completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}
#endif
