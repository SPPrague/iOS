import Foundation
import MEGADomain
import MEGAPresentation
import MEGASDKRepo

@MainActor
protocol CookieSettingsRouting: Routing, Sendable {
    func didTap(on source: CookieSettingsSource)
}

enum CookieSettingsSource {
    case showCookiePolicy(url: URL)
    case showPrivacyPolicy
}

@MainActor
final class CookieSettingsRouter: NSObject, CookieSettingsRouting {
    private weak var navigationController: UINavigationController?
    private weak var presenter: UIViewController?
    
    @objc init(presenter: UIViewController?) {
        self.presenter = presenter
    }
    
    func build() -> UIViewController {
        guard let cookieSettingsTVC = UIStoryboard(name: "CookieSettings", bundle: nil).instantiateViewController(withIdentifier: "CookieSettingsTableViewControllerID") as? CookieSettingsTableViewController else {
            fatalError("Could not instantiate CookieSettingsTableViewController")
        }

        let viewModel = CookieSettingsViewModel(
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
            cookieSettingsUseCase: CookieSettingsUseCase(repository: CookieSettingsRepository.newRepo),
            router: self
        )
        
        cookieSettingsTVC.router = self
        cookieSettingsTVC.viewModel = viewModel
        
        return cookieSettingsTVC
    }
    
    @objc func start() {
        let navigationController = MEGANavigationController(rootViewController: build())
        self.navigationController = navigationController
        
        presenter?.present(navigationController, animated: true, completion: nil)
    }
    
    func didTap(on source: CookieSettingsSource) {
        switch source {
            
        case .showCookiePolicy(let url):
            NSURL(string: url.absoluteString)?.mnz_presentSafariViewController()
            
        case .showPrivacyPolicy:
            NSURL(string: "https://mega.nz/privacy")?.mnz_presentSafariViewController()
        }
    }
    
    func dismiss() {
        navigationController?.dismiss(animated: true, completion: nil)
    }
}
