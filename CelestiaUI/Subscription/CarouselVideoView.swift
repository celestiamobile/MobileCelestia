//
// CarouselVideoView.swift
//

import UIKit
import AVFoundation

class CarouselVideoView: UIView {
    private let player = AVQueuePlayer()
    private lazy var playerLayer = AVPlayerLayer(player: player)
    private var looper: AVPlayerLooper?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)

        player.isMuted = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }

    func load(videoName: String) {
        let url = Bundle.main.url(forResource: videoName, withExtension: "mp4")
        if let url {
            let item = AVPlayerItem(url: url)
            looper = AVPlayerLooper(player: player, templateItem: item)
            player.play()
        }
    }
}
