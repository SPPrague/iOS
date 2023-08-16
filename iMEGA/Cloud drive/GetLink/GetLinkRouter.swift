import MEGADomain
import MEGAPresentation
import MEGASDKRepo
import SwiftUI

struct GetLinkRouter: Routing {
    private weak var presenter: UIViewController?
    private let nodes: [MEGANode]
    
    init(presenter: UIViewController,
         nodes: [MEGANode]) {
        self.presenter = presenter
        self.nodes = nodes
    }
    
    func build() -> UIViewController {
        let copyrightUseCase = CopyrightUseCase(
            shareUseCase: ShareUseCase(repo: ShareRepository.newRepo),
            userAlbumRepository: UserAlbumRepository.newRepo)
        let viewModel = EnforceCopyrightWarningViewModel(preferenceUseCase: PreferenceUseCase.default,
                                                         copyrightUseCase: copyrightUseCase)
        
        let view = EnforceCopyrightWarningView(viewModel: viewModel) {
            GetLinkView(nodes: nodes)
                .ignoresSafeArea(edges: .bottom)
        }
        return UIHostingController(rootView: view)
    }
    
    func start() {
        presenter?.present(build(), animated: true)
    }
}
