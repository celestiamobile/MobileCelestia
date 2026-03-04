//
// CarouselCollectionViewCell.swift
//

import UIKit

class CarouselCollectionViewCell: UICollectionViewCell {
    let videoView = CarouselVideoView()
    let supportView = UIView()
    let floatingIconsView = FloatingIconsView()
    let messageLabel = UILabel(textStyle: .body, weight: .medium)

    enum ItemType {
        case video(String, String)
        case support(String, String, AssetProvider)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        contentView.addSubview(videoView)
        contentView.addSubview(supportView)

        supportView.addSubview(floatingIconsView)
        supportView.addSubview(messageLabel)

        videoView.translatesAutoresizingMaskIntoConstraints = false
        supportView.translatesAutoresizingMaskIntoConstraints = false
        floatingIconsView.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        supportView.backgroundColor = .secondarySystemFill
        supportView.layer.cornerRadius = 24
        supportView.clipsToBounds = true
        videoView.layer.cornerRadius = 24
        videoView.clipsToBounds = true

        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.textColor = .label

        NSLayoutConstraint.activate([
            videoView.topAnchor.constraint(equalTo: contentView.topAnchor),
            videoView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            videoView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            videoView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            supportView.topAnchor.constraint(equalTo: contentView.topAnchor),
            supportView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            supportView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            supportView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            floatingIconsView.topAnchor.constraint(equalTo: supportView.topAnchor),
            floatingIconsView.leadingAnchor.constraint(equalTo: supportView.leadingAnchor),
            floatingIconsView.trailingAnchor.constraint(equalTo: supportView.trailingAnchor),
            floatingIconsView.bottomAnchor.constraint(equalTo: supportView.bottomAnchor),

            messageLabel.centerYAnchor.constraint(equalTo: supportView.centerYAnchor),
            messageLabel.leadingAnchor.constraint(equalTo: supportView.leadingAnchor, constant: GlobalConstants.pageMediumMarginHorizontal),
            messageLabel.trailingAnchor.constraint(equalTo: supportView.trailingAnchor, constant: -GlobalConstants.pageMediumMarginHorizontal)
        ])
    }

    func configure(with item: ItemType) {
        switch item {
        case .video(let videoName, _):
            videoView.isHidden = false
            supportView.isHidden = true
            videoView.load(videoName: videoName)
            floatingIconsView.stopAnimating()
        case .support(_, let message, let assetProvider):
            videoView.isHidden = true
            supportView.isHidden = false
            messageLabel.text = message
            floatingIconsView.startAnimating(assetProvider: assetProvider)
        }
    }
}
