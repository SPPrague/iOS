import Accounts
import MEGADomain
import MEGAPresentation
import MEGASDKRepo
import SwiftUI

extension AppDelegate {
    @objc func isAdsMainTabBarRootView() -> Bool {
        window.rootViewController?.isKind(of: UIHostingController<AdsSlotView<MainTabBarWrapper>>.self) ?? false
    }

    @objc func adsMainTabBarController(_ tabBar: MainTabBarController, onViewFirstAppeared: (() -> Void)?) -> UIViewController {
        AdsSlotRouter(
            adsSlotViewController: tabBar,
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
            purchaseUseCase: AccountPlanPurchaseUseCase(repository: AccountPlanPurchaseRepository.newRepo),
            contentView: MainTabBarWrapper(mainTabBar: tabBar)
        ).build(
            onViewFirstAppeared: onViewFirstAppeared,
            adsFreeViewProPlanAction: { [weak self] in
                self?.showUpgradePlanPageFromAds()
            }
        )
    }
    
    @objc func showUpgradePlanPageFromAds() {
        let accountUseCase = AccountUseCase(repository: AccountRepository.newRepo)
        guard let accountDetails = accountUseCase.currentAccountDetails else { return }
        UpgradeAccountPlanRouter(
            presenter: UIApplication.mnz_visibleViewController(),
            accountDetails: accountDetails,
            isFromAds: true
        ).start()
    }
    
    func showAdMobConsentIfNeeded(isFromCookieDialog: Bool = false) async {
        guard DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .externalAds) else { return }
        do {
            try await GoogleMobileAdsConsentManager.shared.gatherConsent()
            await GoogleMobileAdsConsentManager.shared.initializeGoogleMobileAdsSDK()
            NotificationCenter.default.post(name: .startAds, object: nil)
        } catch {
            MEGALogError("[AdMob] Google Ads consent manager \(isFromCookieDialog ? "with": "without") cookie dialog received error: \(error)")
        }
    }
}
