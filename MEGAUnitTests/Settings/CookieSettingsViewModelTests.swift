@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAPresentation
import MEGAPresentationMock
import XCTest

class CookieSettingsViewModelTests: XCTestCase {
    private let footersArray: [String] = [Strings.Localizable.Settings.Accept.Cookies.footer,
                                               Strings.Localizable.Settings.Cookies.Essential.footer,
                                               Strings.Localizable.Settings.Cookies.PerformanceAndAnalytics.footer]
    
    func testConfigViewTask_featureFlagEnabled_adsFlagsEnabled_shouldEnableAds() async {
        let sut = makeSUT(
            featureFlags: [.inAppAds: true],
            abTestProvider: MockABTestProvider(
                list: [
                    .ads: .variantA,
                    .externalAds: .variantA
                ]
            )
        )
        
        var commands = [CookieSettingsViewModel.Command]()
        sut.invokeCommand = { viewCommand in
            commands.append(viewCommand)
        }
        sut.dispatch(.configView)
        await sut.configViewTask?.value
        
        XCTAssertTrue(sut.isExternalAdsActive)
        XCTAssertEqual(sut.numberOfSection, CookieSettingsViewModel.SectionType.externalAdsActive.numberOfSections)
    }
    
    func testConfigViewTask_featureFlagEnabled_adsFlagsDisabled_shouldNotEnableAds() async {
        let sut = makeSUT(
            featureFlags: [.inAppAds: true],
            abTestProvider: MockABTestProvider(
                list: [
                    .ads: .variantA,
                    .externalAds: .baseline
                ]
            )
        )
        var commands = [CookieSettingsViewModel.Command]()
        sut.invokeCommand = { viewCommand in
            commands.append(viewCommand)
        }
        
        sut.dispatch(.configView)
        await sut.configViewTask?.value
        
        XCTAssertFalse(sut.isExternalAdsActive)
        XCTAssertEqual(sut.numberOfSection, CookieSettingsViewModel.SectionType.externalAdsInactive.numberOfSections)
    }
    
    func testConfigViewTask_featureFlagDisabled_adsFlagsDisabled_shouldNotEnableAds() async {
        let sut = makeSUT(
            featureFlags: [.inAppAds: false],
            abTestProvider: MockABTestProvider(list: [.ads: .baseline])
        )
        var commands = [CookieSettingsViewModel.Command]()
        sut.invokeCommand = { viewCommand in
            commands.append(viewCommand)
        }
        
        sut.dispatch(.configView)
        await sut.configViewTask?.value
        
        XCTAssertFalse(sut.isExternalAdsActive)
        XCTAssertEqual(sut.numberOfSection, CookieSettingsViewModel.SectionType.externalAdsInactive.numberOfSections)
    }
    
    func testActionConfigView_adsIsEnabled_adsCheckCookieNotYetSet_success() {
        var expectedFooters = footersArray
        expectedFooters.append(Strings.Localizable.Settings.Cookies.AdvertisingCookies.footer)
        var expectedCookiesBit = CookiesBitmap.all
        expectedCookiesBit.remove(.ads)
        
        let noAdsCheckCookieBit = CookiesBitmap.all
        let sut = makeSUT(cookieSettings: .success(noAdsCheckCookieBit.rawValue), featureFlags: [.inAppAds: true])
        
        test(viewModel: sut,
             action: .configView,
             expectedCommands: [.configCookieSettings(CookiesBitmap(rawValue: expectedCookiesBit.rawValue)), .updateFooters(expectedFooters)])
    }
    
    func testActionConfigView_adsIsEnabled_adsCheckCookieAlreadySet_success() {
        var expectedFooters = footersArray
        expectedFooters.append(Strings.Localizable.Settings.Cookies.AdvertisingCookies.footer)
        
        var withAdsCheckCookieBit = CookiesBitmap.all
        withAdsCheckCookieBit.insert(.adsCheckCookie)
        let sut = makeSUT(cookieSettings: .success(withAdsCheckCookieBit.rawValue), featureFlags: [.inAppAds: true])
        
        test(viewModel: sut,
             action: .configView,
             expectedCommands: [.configCookieSettings(CookiesBitmap(rawValue: withAdsCheckCookieBit.rawValue)), .updateFooters(expectedFooters)])
    }
    
    func testAction_configView_cookieSettings_success() {
        let sut = makeSUT(cookieSettings: .success(defaultCookieBits))
        
        test(viewModel: sut,
             action: .configView,
             expectedCommands: [.configCookieSettings(CookiesBitmap(rawValue: defaultCookieBits)), .updateFooters(footersArray)])
    }
    
    func testAction_configView_cookieSettings_fail_bitmapNotSet() {
        let sut = makeSUT(cookieSettings: .failure(.bitmapNotSet))
        
        test(viewModel: sut,
             action: .configView,
             expectedCommands: [.configCookieSettings(CookiesBitmap.essential), .updateFooters(footersArray)])
    }
    
    func testAction_configView_cookieSettings_fail_generic() {
        let sut = makeSUT(cookieSettings: .failure(.generic))
        
        test(viewModel: sut,
             action: .configView,
             expectedCommands: [.updateFooters(footersArray)])
    }
    
    func testAction_configView_cookieSettings_fail_invalidBitmap() {
        let sut = makeSUT(cookieSettings: .failure(.invalidBitmap))
        
        test(viewModel: sut,
             action: .configView,
             expectedCommands: [.updateFooters(footersArray)])
    }
    
    func testAction_save_setCookieSettings_success() {
        let sut = makeSUT(cookieSettings: .success(defaultCookieBits))
        
        test(viewModel: sut,
             action: .save,
             expectedCommands: [.cookieSettingsSaved])
    }
    
    // MARK: Cookie Policy
    func testAction_showCookiePolicy_sessionTransferSuccess_showPolicyWithSession() async throws {
        let expectedURL = try XCTUnwrap(URL(string: "https://mega.nz/testCookie"))
        let mockRouter = MockCookieSettingsRouter()
        let sut = makeSUT(
            sessionTransferURLResult: .success(expectedURL),
            featureFlags: [.inAppAds: true],
            abTestProvider: MockABTestProvider(
                list: [
                    .ads: .variantA,
                    .externalAds: .variantA
                ]
            ),
            mockRouter: mockRouter
        )
        
        try await checkCookiePolicyDispatchResult(
            sut: sut,
            mockRouter: mockRouter,
            expectedURL: expectedURL
        )
    }
    
    func testAction_showCookiePolicy_extenalAdsIsFalse_showPolicyWithoutSession() async throws {
        let expectedURL = try XCTUnwrap(URL(string: "https://mega.nz/cookie"))
        let mockRouter = MockCookieSettingsRouter()
        let sut = makeSUT(
            featureFlags: [.inAppAds: true],
            abTestProvider: MockABTestProvider(
                list: [.externalAds: .baseline]
            ),
            mockRouter: mockRouter
        )
        
        try await checkCookiePolicyDispatchResult(
            sut: sut,
            mockRouter: mockRouter,
            expectedURL: expectedURL
        )
    }
    
    private func checkCookiePolicyDispatchResult(
        sut: CookieSettingsViewModel,
        mockRouter: MockCookieSettingsRouter,
        expectedURL: URL,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        var commands = [CookieSettingsViewModel.Command]()
        sut.invokeCommand = { viewCommand in
            commands.append(viewCommand)
        }
        sut.dispatch(.configView)
        await sut.configViewTask?.value
        sut.dispatch(.showCookiePolicy)
        await sut.showCookiePolicyURLTask?.value
        
        let source = try XCTUnwrap(mockRouter.source)
        if case let CookieSettingsSource.showCookiePolicy(url) = source {
            XCTAssertEqual(url, expectedURL, file: file, line: line)
        } else {
            XCTFail("Received incorrect tap source \(source)", file: file, line: line)
        }
    }
    
    // MARK: Helper
    // All Cookie bits: .essential, .preference, .analytics, .ads, .thirdparty
    private let defaultCookieBits = CookiesBitmap.all.rawValue // 31
    
    private func makeSUT(
        cookieBannerEnable: Bool = true,
        cookieSettings: Result<Int, CookieSettingsErrorEntity> = .success(31),
        sessionTransferURLResult: Result<URL, AccountErrorEntity> = .failure(.generic),
        featureFlags: [FeatureFlagKey: Bool] = [FeatureFlagKey.inAppAds: false],
        abTestProvider: MockABTestProvider = MockABTestProvider(list: [.ads: .variantA, .externalAds: .variantA]),
        mockRouter: CookieSettingsRouting = MockCookieSettingsRouter(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> CookieSettingsViewModel {
        let featureFlagProvider = MockFeatureFlagProvider(list: featureFlags)
        let accountUseCase = MockAccountUseCase(sessionTransferURLResult: sessionTransferURLResult)
        let cookieSettingsUseCase = MockCookieSettingsUseCase(cookieBannerEnable: cookieBannerEnable, cookieSettings: cookieSettings)
        
        let sut = CookieSettingsViewModel(accountUseCase: accountUseCase,
                                          cookieSettingsUseCase: cookieSettingsUseCase,
                                          router: mockRouter,
                                          featureFlagProvider: featureFlagProvider,
                                          abTestProvider: abTestProvider)
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}

final class MockCookieSettingsRouter: CookieSettingsRouting {
    private(set) var source: CookieSettingsSource?
    
    func didTap(on source: CookieSettingsSource) {
        self.source = source
    }
}
