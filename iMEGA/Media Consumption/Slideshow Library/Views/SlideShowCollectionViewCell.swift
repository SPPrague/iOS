import UIKit

final class SlideShowCollectionViewCell: UICollectionViewCell {
    let imageScrollView = ImageScrollView()
    private var slideshowInteraction: SlideShowInteraction?
    
    required init(coder aDecoder:NSCoder) {
        super.init(coder: aDecoder)!
        addSubview(imageScrollView)
        imageScrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageScrollView.topAnchor.constraint(equalTo: self.topAnchor),
            imageScrollView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            imageScrollView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            imageScrollView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
        
        imageScrollView.imageContentMode = .aspectFit
        imageScrollView.initialOffset = .center
        
        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(singleTapGestureRecognizer(_:)))
        addGestureRecognizer(singleTapGesture)
    }
    
    func update(withImage image: UIImage, andInteraction slideshowInteraction: SlideShowInteraction) {
        self.slideshowInteraction = slideshowInteraction
        imageScrollView.setup()
        
        imageScrollView.display(image: image)
    }
    
    func resetZoomScale() {
        imageScrollView.resetZoomScale()
    }
    
    @objc func singleTapGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        slideshowInteraction?.pausePlaying()
    }
}
