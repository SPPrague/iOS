import UIKit

public extension UITextField {

    func setLeftImage(_ image: UIImage, padding: CGFloat = 8, tintColor: UIColor? = nil) {
        self.leftView = imageIconView(with: image, padding: padding, tintColor: tintColor)
        leftViewMode = .always
    }
    
    private func imageIconView(with image: UIImage, padding: CGFloat = 8, tintColor: UIColor? = nil) -> UIView {
        var imageview: UIImageView {
            let imageview = UIImageView(image: image)
            if let tintColor {
                imageview.renderImage(withColor: tintColor)
            }
            imageview.translatesAutoresizingMaskIntoConstraints = false
            return imageview
        }

        var stackView: UIStackView {
            let stackView = UIStackView()
            stackView.axis = .horizontal
            stackView.alignment = .center
            stackView.distribution = .fill
            stackView.translatesAutoresizingMaskIntoConstraints = false
            return stackView
        }

        var paddingView: UIView {
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.widthAnchor.constraint(equalToConstant: padding).isActive = true
            view.heightAnchor.constraint(equalToConstant: padding).isActive = true
            return view
        }

        let theStackView = stackView
        theStackView.addArrangedSubview(paddingView)
        theStackView.addArrangedSubview(imageview)
        theStackView.addArrangedSubview(paddingView)
        return theStackView
    }
}
