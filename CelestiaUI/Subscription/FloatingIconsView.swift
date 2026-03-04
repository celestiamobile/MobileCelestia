//
// FloatingIconsView.swift
//

import UIKit

class FloatingIconsView: UIView {
    private var isAnimating = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        clipsToBounds = true
    }

    func startAnimating(assetProvider: AssetProvider) {
        guard !isAnimating else { return }
        isAnimating = true
        spawnIcon(assetProvider: assetProvider)
    }

    func stopAnimating() {
        isAnimating = false
        subviews.forEach { $0.removeFromSuperview() }
    }

    private func spawnIcon(assetProvider: AssetProvider) {
        guard isAnimating else { return }

        // Average 2 items per second (500ms delay) -> 0.3 to 0.7s
        let delay = Double.random(in: 0.3...0.7)

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self, self.isAnimating else { return }
            self.createAndAnimateIcon(assetProvider: assetProvider)
            self.spawnIcon(assetProvider: assetProvider)
        }
    }

    private func createAndAnimateIcon(assetProvider: AssetProvider) {
        let size = CGFloat.random(in: 24...36)
        let isHeart = Bool.random()

        let iconView: UIView
        if isHeart {
            let label = UILabel()
            label.text = "❤️"
            label.font = .systemFont(ofSize: size)
            label.sizeToFit()
            iconView = label
        } else {
            let imageView = UIImageView(image: assetProvider.image(for: .loadingIcon))
            imageView.contentMode = .scaleAspectFit
            imageView.frame = CGRect(x: 0, y: 0, width: size, height: size)
            iconView = imageView
        }

        let width = bounds.width
        let height = bounds.height
        guard width > 0, height > 0 else { return }

        let startX = CGFloat.random(in: 0...width)
        let angleRad = Double.random(in: -30...30) * .pi / 180.0
        let endX = startX + CGFloat((height + 50) * tan(angleRad))
        let duration = Double.random(in: 8...12)

        let angularSpeed = Double.random(in: 20...40)
        let rotTarget = angularSpeed * duration * (Bool.random() ? 1.0 : -1.0)

        iconView.center = CGPoint(x: startX, y: height + 50)
        iconView.alpha = 0.4
        addSubview(iconView)

        UIView.animate(withDuration: duration, delay: 0, options: [.curveLinear]) {
            iconView.center = CGPoint(x: endX, y: -50)
            iconView.transform = CGAffineTransform(rotationAngle: rotTarget * .pi / 180.0)
            iconView.alpha = 0.1
        } completion: { _ in
            iconView.removeFromSuperview()
        }
    }
}
