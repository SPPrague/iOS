
final class AudioPlayerFileToolbarConfigurator {
    typealias ButtonAction = (UIBarButtonItem) -> Void
    let importAction : ButtonAction
    let sendToContactAction: ButtonAction
    let shareAction: ButtonAction
    
    lazy var flexibleItem = UIBarButtonItem(
        barButtonSystemItem: .flexibleSpace,
        target: nil,
        action: nil
    )
    
    lazy var importItem = UIBarButtonItem(
        image: UIImage(named: "import"),
        style: .plain,
        target: self,
        action: #selector(buttonPressed(_:))
    )
    
    lazy var sendToContactItem = UIBarButtonItem(
        image: UIImage(named: "sendMessage"),
        style: .plain,
        target: self,
        action: #selector(buttonPressed(_:))
    )
    
    lazy var shareItem = UIBarButtonItem(
        image: UIImage(named: "share"),
        style: .plain,
        target: self,
        action: #selector(buttonPressed(_:))
    )
    
    init(importAction: @escaping ButtonAction,
         sendToContactAction: @escaping ButtonAction,
         shareAction: @escaping ButtonAction) {
        self.importAction = importAction
        self.sendToContactAction = sendToContactAction
        self.shareAction = shareAction
    }
    
    @objc func buttonPressed(_ barButtonItem: UIBarButtonItem) {
        switch barButtonItem {
        case importItem:
            importAction(barButtonItem)
        case sendToContactItem:
            sendToContactAction(barButtonItem)
        case shareItem:
            shareAction(barButtonItem)
        default:
            break
        }
    }
    
    func toolbarItems() -> [UIBarButtonItem] {
        [importItem, flexibleItem, sendToContactItem, flexibleItem, shareItem]
    }
}
