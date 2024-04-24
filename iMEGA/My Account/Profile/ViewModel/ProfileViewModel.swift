import Combine
import Foundation
import MEGADomain
import MEGAPresentation
import MEGASDKRepo

enum TwoFactorAuthStatus: Int {
    case unknown
    case querying
    case disabled
    case enabled
}

enum ProfileAction: ActionType {
    case onViewDidLoad
    case invalidateSections
    case changeEmail
    case changePassword
}

final class ProfileViewModel: ViewModelType {
    
    enum Command: CommandType, Equatable {
        case changeProfile(requestedChangeType: ChangeType, isTwoFactorAuthenticationEnabled: Bool)
    }
    
    struct SectionCellDataSource: Equatable {
        let sectionOrder: [ProfileSection]
        let sectionRows: [ProfileSection: [ProfileSectionRow]]
        
        /// Boolen to indicate, if the current datasource does not contain any elements in any all sections
        var isEmpty: Bool { sectionRows.allSatisfy { $0.value.isEmpty } }
    }
    
    @Published private(set) var sectionCells: SectionCellDataSource = .init(sectionOrder: [], sectionRows: [:])
    
    private(set) lazy var sectionCellsPublisher: AnyPublisher<SectionCellDataSource, Never> = $sectionCells
        .drop(while: \.isEmpty)
        .share()
        .eraseToAnyPublisher()
    
    var invokeCommand: ((Command) -> Void)?
    
    // Internal State
    private let accountUseCase: any AccountUseCaseProtocol
    private let requestedChangeTypeValueSubject = CurrentValueSubject<ChangeType?, Never>(nil)
    private let twoFactorAuthStatusValueSubject = CurrentValueSubject<TwoFactorAuthStatus, Never>(.unknown)
    private let invalidateSectionsValueSubject = PassthroughSubject<Void, Never>()
    private var subscriptions = Set<AnyCancellable>()
    
    init(accountUseCase: some AccountUseCaseProtocol) {
        self.accountUseCase = accountUseCase
        bindToSubscriptions()
    }
    
    private func bindToSubscriptions() {
        
        let sections: [ProfileSection] = shouldShowPlanSection ? [.profile, .security, .plan, .session] : [.profile, .security, .session]
        
        invalidateSectionsValueSubject
            .map { [weak self] _ -> AnyPublisher<SectionCellDataSource, Never> in
                guard let self else {
                    return Empty().eraseToAnyPublisher()
                }
                
                return requestedChangeTypeValueSubject
                    .combineLatest(twoFactorAuthStatusValueSubject)
                    .map { [weak self] requestedChangeType, twoFactorAuthStatus -> SectionCellDataSource in
                        
                        guard let self else {
                            return SectionCellDataSource(sectionOrder: [], sectionRows: [:])
                        }
                        
                        return makeSectionCellDataSource(
                            sections: sections,
                            requestedChangeType: requestedChangeType,
                            twoFactorAuthStatus: twoFactorAuthStatus)
                    }
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .removeDuplicates()
            .assign(to: \.sectionCells, on: self)
            .store(in: &subscriptions)
    }
    
    private var shouldShowPlanSection: Bool {
        accountUseCase.isAccountType(.proFlexi) || accountUseCase.isAccountType(.business) || accountUseCase.isMasterBusinessAccount
    }
}

// MARK: ViewModelType - Command/Actions
extension ProfileViewModel {
    
    func dispatch(_ action: ProfileAction) {
        switch action {
        case .onViewDidLoad, .invalidateSections:
            invalidateSectionsValueSubject.send()
        case .changeEmail:
            handleChangeProfileAction(requestedChangeType: .email)
        case .changePassword:
            handleChangeProfileAction(requestedChangeType: .password)
        }
    }
    
    private func handleChangeProfileAction(requestedChangeType: ChangeType) {
        
        requestedChangeTypeValueSubject.send(requestedChangeType)
        
        switch requestedChangeType {
        case .password, .email:
            let _twoFactorAuthStatus = twoFactorAuthStatusValueSubject.value
            switch _twoFactorAuthStatus {
            case .unknown:
                break
            case .querying:
                return
            case .disabled, .enabled:
                invokeCommand?(.changeProfile(
                    requestedChangeType: requestedChangeType,
                    isTwoFactorAuthenticationEnabled: _twoFactorAuthStatus == .enabled))
                return
            }
            
            guard let myEmail = accountUseCase.myEmail else {
                return
            }
            
            twoFactorAuthStatusValueSubject.send(.querying)
            Task { @MainActor in
                let isFlagEnabled = try await self.accountUseCase.multiFactorAuthCheck(email: myEmail)
                twoFactorAuthStatusValueSubject.send(isFlagEnabled ? .enabled : .disabled)
                invokeCommand?(.changeProfile(requestedChangeType: requestedChangeType, isTwoFactorAuthenticationEnabled: isFlagEnabled))
            }
        case .resetPassword, .parkAccount, .passwordFromLogout:
            break
        @unknown default:
            break
        }
    }
}

// MARK: Section Cell Structure Builders
extension ProfileViewModel {
    private func makeSectionCellDataSource(sections: [ProfileSection], requestedChangeType: ChangeType?, twoFactorAuthStatus: TwoFactorAuthStatus) -> SectionCellDataSource {
        let sectionRows = sections
            .reduce([ProfileSection: [ProfileSectionRow]](), { result, sectionKey in
                var mutableResult = result
                switch sectionKey {
                case .profile:
                    mutableResult[sectionKey] = makeRowsForProfileSection(requestedChangeType, twoFactorAuthStatus: twoFactorAuthStatus)
                case .security:
                    mutableResult[sectionKey] = makeRowsForSecuritySection()
                case .plan:
                    mutableResult[sectionKey] = makeRowsForPlanSection()
                case .session:
                    mutableResult[sectionKey] = makeRowsForSessionSection()
                }
                return mutableResult
            })
        
        return SectionCellDataSource(sectionOrder: sections, sectionRows: sectionRows)
    }
    
    private func makeRowsForProfileSection(_ requestedChangeType: ChangeType?, twoFactorAuthStatus: TwoFactorAuthStatus) -> [ProfileSectionRow] {
        let isBusiness = accountUseCase.isAccountType(.business)
        let isMasterBusiness = accountUseCase.isMasterBusinessAccount
        
        var profileRows = [ProfileSectionRow]()
        
        if !isBusiness || isMasterBusiness {
            profileRows.append(.changeName)
        }
        
        profileRows.append(.changePhoto)
        
        if !isBusiness || isMasterBusiness {
            profileRows.append(.changeEmail(isLoading: requestedChangeType == .email ? twoFactorAuthStatus == .querying : false))
        }
        
        profileRows.append(.changePassword(isLoading: requestedChangeType == .password ? twoFactorAuthStatus == .querying : false))
        
        if accountUseCase.isSmsAllowed {
            profileRows.append(.phoneNumber)
        }
        
        return profileRows
    }
    
    private func makeRowsForSecuritySection() -> [ProfileSectionRow] {
        [.recoveryKey]
    }
    
    private func makeRowsForPlanSection() -> [ProfileSectionRow] {
        accountUseCase.isAccountType(.business) ? [.upgrade, .role] : [.upgrade]
    }
    
    private func makeRowsForSessionSection() -> [ProfileSectionRow] {
        [.logout]
    }
}
