import MEGADesignToken
import MEGADomain
import MEGAPresentation
import MEGASDKRepo
import SwiftUI
import UIKit

extension FileManagementTableViewController {
    @objc func updateLabelAppearance() {
        clearOfflineFilesLabel.textColor = TokenColors.Text.primary
        clearCacheLabel.textColor = TokenColors.Text.primary
        fileVersioningLabel.textColor = TokenColors.Text.primary
        fileVersioningDetail.textColor = TokenColors.Text.primary
        useMobileDataLabel.textColor = TokenColors.Text.primary
    }
    
    open override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let headerFooterView = view as? UITableViewHeaderFooterView else { return }
        
        headerFooterView.textLabel?.textColor = TokenColors.Text.secondary
    }
    
    open override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        guard let headerFooterView = view as? UITableViewHeaderFooterView else { return }
        
        headerFooterView.textLabel?.textColor = TokenColors.Text.secondary
    }
    
    @objc func isNewFileManagementSettingsEnabled() -> Bool {
        DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .newFileManagementSettings)
    }
    
    @objc func showRubbishBinSettings() {
        guard isNewFileManagementSettingsEnabled() else { return }
        
        let accountUseCase = AccountUseCase(repository: AccountRepository.newRepo)
        let rubbishBinRepo = RubbishBinRepository.newRepo
        let rubbishBinSettingsUpdatesProvider = RubbishBinSettingsUpdateProvider(isProUser: accountUseCase.isProAccount, serverSideRubbishBinAutopurgeEnabled: rubbishBinRepo.serverSideRubbishBinAutopurgeEnabled())
        let rubbishBinSettingRepo = RubbishBinSettingsRepository(rubbishBinSettingsUpdatesProvider: rubbishBinSettingsUpdatesProvider)
        let rubbishBinSettingsUseCase = RubbishBinSettingsUseCase(rubbishBinSettingsRepository: rubbishBinSettingRepo)
        let hostingVC = UIHostingController(rootView: RubbishBinSettingView(viewModel: RubbishBinSettingViewModel(accountUseCase: accountUseCase, rubbishBinSettingsUseCase: rubbishBinSettingsUseCase)))
        hostingVC.title = "Rubbish Bin Settings"
        navigationController?.pushViewController(hostingVC, animated: true)
    }
}
