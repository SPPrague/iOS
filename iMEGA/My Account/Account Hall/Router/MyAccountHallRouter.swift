import DeviceCenter
import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASDKRepo

public protocol MyAccountHallRouting: Routing {
    func navigateToDeviceCenter(deviceCenterBridge: DeviceCenterBridge, deviceCenterAssets: DeviceCenterAssets)
    func didTapCameraUploadsAction(statusChanged: @escaping () -> Void)
    func didTapRenameAction(_ renameEntity: RenameActionEntity)
    func didTapNodeAction(type: DeviceCenterActionType, node: NodeEntity)
    func showError(_ error: any Error)
}

final class MyAccountHallRouter: MyAccountHallRouting {
    private let myAccountHallUseCase: any MyAccountHallUseCaseProtocol
    private let purchaseUseCase: any AccountPlanPurchaseUseCaseProtocol
    private let shareUseCase: any ShareUseCaseProtocol
    private let networkMonitorUseCase: any NetworkMonitorUseCaseProtocol
    private let shouldOpenAchievements: Bool
    private weak var navigationController: UINavigationController?
    private weak var viewController: UIViewController?
    private let loadingPresenter: () -> Void
    private let actionSucceededPresenter: (String) -> Void
    private let dismissLoadingPresenter: () -> Void
    private let errorPresenter: (String) -> Void
    private let noInternetConnectionPresenter: (UIImage, String) -> Void
    
    init(
        myAccountHallUseCase: some MyAccountHallUseCaseProtocol,
        purchaseUseCase: some AccountPlanPurchaseUseCaseProtocol,
        shareUseCase: some ShareUseCaseProtocol,
        networkMonitorUseCase: some NetworkMonitorUseCaseProtocol,
        shouldOpenAchievements: Bool = false,
        navigationController: UINavigationController,
        loadingPresenter: @escaping () -> Void = { SVProgressHUD.show() },
        actionSucceededPresenter: @escaping (String) -> Void = { SVProgressHUD.showSuccess(withStatus: $0) },
        dismissLoadingPresenter: @escaping () -> Void = { SVProgressHUD.dismiss() },
        errorPresenter: @escaping (String) -> Void = { SVProgressHUD.showError(withStatus: $0) },
        noInternetConnectionPresenter: @escaping (UIImage, String) -> Void = { SVProgressHUD.show($0, status: $1) }
    ) {
        self.myAccountHallUseCase = myAccountHallUseCase
        self.purchaseUseCase = purchaseUseCase
        self.shareUseCase = shareUseCase
        self.networkMonitorUseCase = networkMonitorUseCase
        self.shouldOpenAchievements = shouldOpenAchievements
        self.navigationController = navigationController
        self.loadingPresenter = loadingPresenter
        self.actionSucceededPresenter = actionSucceededPresenter
        self.dismissLoadingPresenter = dismissLoadingPresenter
        self.errorPresenter = errorPresenter
        self.noInternetConnectionPresenter = noInternetConnectionPresenter
    }
    
    @MainActor
    private func pushCDViewController(_ node: NodeEntity, isBackup: Bool) {
        guard let viewController = self.createCloudDriveVCForNode(
            node,
            isBackup: isBackup
        ) else { return }
        
        self.navigationController?.pushViewController(viewController, animated: true)
    }

    private func didTapShowInBackupsAction(_ node: NodeEntity) {
        Task {
            await pushCDViewController(
                node,
                isBackup: true
            )
        }
    }

    private func didTapShowInCloudDriveAction(_ node: NodeEntity) {
        Task {
            await pushCDViewController(
                node,
                isBackup: false
            )
        }
    }
    
    private func createCloudDriveVCForNode(
        _ node: NodeEntity,
        isBackup: Bool
    ) -> UIViewController? {
        let factory = CloudDriveViewControllerFactory.make(nc: navigationController)
        
        return factory.buildBare(
            parentNode: node,
            options: .init(
                displayMode: isBackup ? .backup : .cloudDrive
            )
        )
    }
    
    private func setupContactsViewController(with node: NodeEntity, mode: ContactsMode) -> ContactsViewController? {
        guard let node = node.toMEGANode(in: MEGASdk.shared),
              let contactsVC = UIStoryboard(name: "Contacts", bundle: nil).instantiateViewController(identifier: "ContactsViewControllerID") as? ContactsViewController else {
            return nil
        }
        
        contactsVC.node = node
        contactsVC.contactsMode = mode
        return contactsVC
    }
    
    private func executeNodeAction(
        for node: NodeEntity,
        action: @escaping (UIViewController, NodeEntity) -> Void
    ) {
        guard networkMonitorUseCase.isConnected() else {
            noInternetConnectionPresenter(
                UIImage.hudForbidden,
                Strings.Localizable.noInternetConnection
            )
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let presenter = self.navigationController?.topViewController else { return }
            action(presenter, node)
        }
    }

    private func didTapShareLinkAction(
        _ node: NodeEntity
    ) {
        executeNodeAction(for: node) { presenter, node in
            guard let node = node.toMEGANode(in: MEGASdk.shared) else { return }
            GetLinkRouter(
                presenter: presenter,
                nodes: [node]
            ).start()
        }
    }

    private func didTapRemoveLinkAction(
        _ node: NodeEntity
    ) {
        executeNodeAction(for: node) { presenter, node in
            ActionWarningViewRouter(
                presenter: presenter,
                nodes: [node],
                actionType: .removeLink,
                onActionStart: { [weak self] in
                    self?.loadingPresenter()
                }, onActionFinish: { [weak self] in
                    switch $0 {
                    case .success(let message):
                        self?.actionSucceededPresenter(message)
                    case .failure:
                        self?.dismissLoadingPresenter()
                    }
                }
            ).start()
        }
    }
    
    private func didTapShareFolderAction(
        _ node: NodeEntity
    ) {
        executeNodeAction(for: node) { [weak self] presenter, node in
            BackupNodesValidator(presenter: presenter, nodes: [node]).showWarningAlertIfNeeded {
                guard let self,
                      let contactsVC = self.setupContactsViewController(with: node, mode: .shareFoldersWith),
                      let node = node.toMEGANode(in: MEGASdk.shared) else { return }
                contactsVC.nodesArray = [node]
                let navigation = MEGANavigationController(rootViewController: contactsVC)
                presenter.present(navigation, animated: true, completion: nil)
            }
        }
    }
    
    private func didTapManageShareAction(
        _ node: NodeEntity
    ) {
        executeNodeAction(for: node) { [weak self] presenter, node in
            BackupNodesValidator(presenter: presenter, nodes: [node]).showWarningAlertIfNeeded {
                guard let self,
                      let contactsVC = self.setupContactsViewController(with: node, mode: .folderSharedWith) else { return }
                self.navigationController?.pushViewController(contactsVC, animated: true)
            }
        }
    }
    
    private func didTapCopyAction(
        _ node: NodeEntity
    ) {
        executeNodeAction(for: node) { presenter, node in
            guard let node = node.toMEGANode(in: MEGASdk.shared),
                  let navigationController = UIStoryboard(name: "Cloud", bundle: nil).instantiateViewController(withIdentifier: "BrowserNavigationControllerID") as? MEGANavigationController,
                  let browserViewController = navigationController.viewControllers.first as? BrowserViewController else {
                return
            }
            browserViewController.browserAction = .copy
            browserViewController.selectedNodesArray = [node]

            presenter.present(navigationController, animated: true)
        }
    }
    
    private func didTapDownloadAction(
        _ node: NodeEntity
    ) {
        executeNodeAction(for: node) { presenter, node in
            let transfer = CancellableTransfer(handle: node.handle, name: nil, appData: nil, priority: false, isFile: node.isFile, type: .download)
            CancellableTransferRouter(presenter: presenter, transfers: [transfer], transferType: .download).start()
        }
    }
    
    func build() -> UIViewController {
        guard let myAccountViewController = UIStoryboard(name: "MyAccount", bundle: nil)
                .instantiateViewController(withIdentifier: "MyAccountHall") as? MyAccountHallViewController else {
            return UIViewController()
        }
        
        let viewModel = MyAccountHallViewModel(
            myAccountHallUseCase: myAccountHallUseCase,
            purchaseUseCase: purchaseUseCase, 
            shareUseCase: shareUseCase,
            deviceCenterBridge: DeviceCenterBridge(),
            router: self
        )
        
        myAccountViewController.viewModel = viewModel
        
        if shouldOpenAchievements {
            myAccountViewController.openAchievements()
        }
        
        viewController = myAccountViewController
        
        return myAccountViewController
    }
    
    func start() {
        navigationController?.pushViewController(build(), animated: true)
    }
    
    func navigateToDeviceCenter(
        deviceCenterBridge: DeviceCenterBridge,
        deviceCenterAssets: DeviceCenterAssets
    ) {
        DeviceListViewRouter(
            navigationController: navigationController,
            deviceCenterBridge: deviceCenterBridge,
            deviceCenterUseCase:
                DeviceCenterUseCase(
                    deviceCenterRepository:
                        DeviceCenterRepository.newRepo
                ),
            nodeUseCase:
                NodeUseCase(
                    nodeDataRepository: NodeDataRepository.newRepo,
                    nodeValidationRepository: NodeValidationRepository.newRepo,
                    nodeRepository: NodeRepository.newRepo
                ),
            networkMonitorUseCase: NetworkMonitorUseCase(repo: NetworkMonitorRepository.newRepo),
            notificationCenter: NotificationCenter.default,
            deviceCenterAssets: deviceCenterAssets
        ).start()
    }
    
    func didTapCameraUploadsAction(
        statusChanged: @escaping () -> Void
    ) {
        guard let presenter = self.navigationController else { return }

        CameraUploadsSettingsViewRouter(
            presenter: presenter,
            closure: {
                statusChanged()
        }).start()
    }
    
    func didTapRenameAction(
        _ renameEntity: RenameActionEntity
    ) {
        guard let presenter = self.navigationController else { return }
        
        RenameRouter(
            presenter: presenter,
            type: .device(
                renameEntity: renameEntity
            ),
            renameUseCase:
                RenameUseCase(
                    renameRepository: RenameRepository.newRepo
                )
        ).start()
    }
    
    func didTapNodeAction(
        type: DeviceCenterActionType,
        node: NodeEntity
    ) {
        switch type {
        case .showInCloudDrive: didTapShowInCloudDriveAction(node)
        case .showInBackups: didTapShowInBackupsAction(node)
        case .shareLink, .manageLink: didTapShareLinkAction(node)
        case .removeLink: didTapRemoveLinkAction(node)
        case .shareFolder: didTapShareFolderAction(node)
        case .manageShare: didTapManageShareAction(node)
        case .copy: didTapCopyAction(node)
        case .download: didTapDownloadAction(node)
        default: break
        }
    }
    
    func showError(_ error: any Error) {
        errorPresenter(error.localizedDescription)
    }
}
