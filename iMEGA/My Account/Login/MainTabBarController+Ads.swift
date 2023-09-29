import Accounts
import MEGADomain

extension MainTabBarController: AdsSlotViewControllerProtocol {
    public func currentAdsSlotType() -> AdsSlotEntity? {
        switch selectedIndex {
        case TabType.cloudDrive.rawValue: return .files
        case TabType.cameraUploads.rawValue: return .photos
        case TabType.home.rawValue: return .home
        case TabType.chat.rawValue: return nil
        case TabType.sharedItems.rawValue: return nil
        default: return nil
        }
    }
}
