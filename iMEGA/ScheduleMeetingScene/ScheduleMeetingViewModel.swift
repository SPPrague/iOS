import MEGADomain

protocol ScheduleMeetingRouting {
    func showSpinner()
    func hideSpinner()
    func discardChanges()
    func showAddParticipants(alreadySelectedUsers: [UserEntity], newSelectedUsers: @escaping (([UserEntity]?) -> Void))
    func showMeetingInfo(for scheduledMeeting: ScheduledMeetingEntity)
}

final class ScheduleMeetingViewModel: ObservableObject {
    
    enum Constants {
        static let meetingNameMaxLenght: Int = 30
        static let meetingDescriptionMaxLenght: Int = 3000
        static let minDurationFiveMinutes: TimeInterval = 300
        static let defaultDurationHalfHour: TimeInterval = 1800
    }
    
    private let router: ScheduleMeetingRouting
    private let scheduledMeetingUseCase: ScheduledMeetingUseCaseProtocol
    private var chatLinkUseCase: ChatLinkUseCaseProtocol
    private var chatRoomUseCase: ChatRoomUseCaseProtocol

    @Published var startDate = Date() {
        didSet {
            startDateUpdated()
        }
    }
    @Published var startDatePickerVisible = false
    lazy var startDateFormatted = formatDate(startDate)
    @Published var endDate = Date() {
        didSet {
            endDateFormatted = formatDate(endDate)
        }
    }
    @Published var endDatePickerVisible = false
    lazy var endDateFormatted = formatDate(endDate)
    var minimunEndDate = Date()

    @Published var meetingName = "" {
        didSet {
            meetingNameTooLong = meetingName.count > Constants.meetingNameMaxLenght
            configureCreateButton()
        }
    }
    @Published var meetingNameTooLong = false

    @Published var meetingDescription = "" {
        didSet {
            meetingDescriptionTooLong = meetingDescription.count > Constants.meetingDescriptionMaxLenght
            configureCreateButton()
        }
    }
    @Published var meetingDescriptionTooLong = false
    
    @Published var meetingLinkEnabled = false
    @Published var calendarInviteEnabled = false
    @Published var allowNonHostsToAddParticipantsEnabled = true

    @Published var showDiscardAlert = false
    @Published var createButtonEnabled = false

    let timeFormatter = DateFormatter.timeShort()
    let dateFormatter = DateFormatter.dateMedium()
    
    private var participants = [UserEntity]() {
        didSet {
            participantsCount = participants.count
        }
    }
    @Published var participantsCount = 0 

    init(router: ScheduleMeetingRouting,
         scheduledMeetingUseCase: ScheduledMeetingUseCaseProtocol,
         chatLinkUseCase: ChatLinkUseCaseProtocol,
         chatRoomUseCase: ChatRoomUseCaseProtocol) {
        self.router = router
        self.scheduledMeetingUseCase = scheduledMeetingUseCase
        self.chatLinkUseCase = chatLinkUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.startDate = nextDateMinutesIsFiveMultiple(startDate)
        self.endDate = startDate.addingTimeInterval(Constants.defaultDurationHalfHour)
    }
    
    //MARK: - Public
    func createDidTap() {
        createScheduleMeeting()
    }
    
    func startsDidTap() {
        startDatePickerVisible.toggle()
        endDatePickerVisible = false
    }
    
    func endsDidTap() {
        endDatePickerVisible.toggle()
        startDatePickerVisible = false
    }
    
    func cancelDidTap() {
        showDiscardAlert = true
    }
    
    func discardChangesTap() {
        router.discardChanges()
    }
    
    func keepEditingTap() {
        showDiscardAlert = false
    }
    
    func addParticipantsTap() {
        router.showAddParticipants(alreadySelectedUsers: participants) { [weak self] userEntities in
            self?.participants = userEntities ?? []
        }
    }
    
    //MARK: - Private
    private func formatDate(_ date: Date) -> String {
        dateFormatter.localisedString(from: date) + " " + timeFormatter.localisedString(from: date)
    }
    
    private func configureCreateButton() {
        createButtonEnabled = meetingName.count > 0 && !meetingNameTooLong && !meetingDescriptionTooLong
    }
    
    private func nextDateMinutesIsFiveMultiple(_ date: Date) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.hour, .minute, .day, .month, .year], from: date)
        guard let minutes = components.minute else {
            return date
        }
        components.minute = (minutes + 4) / 5 * 5
        return calendar.date(from: components) ?? date
    }
    
    private func startDateUpdated() {
        if endDate <= startDate {
            endDate = startDate.addingTimeInterval(Constants.defaultDurationHalfHour)
            endDateFormatted = formatDate(endDate)
        }
        minimunEndDate = startDate.addingTimeInterval(Constants.minDurationFiveMinutes)
        startDateFormatted = formatDate(startDate)
    }
    
    private func createScheduleMeeting() {
        let createScheduleMeeting = CreateScheduleMeetingEntity(title: meetingName, description: meetingDescription, participants: participants, calendarInvite: calendarInviteEnabled, openInvite: allowNonHostsToAddParticipantsEnabled, startDate: startDate, endDate: endDate)
        router.showSpinner()
        Task { [weak self] in
            guard let self else { return }
            do {
                let scheduledMeeting = try await scheduledMeetingUseCase.createScheduleMeeting(createScheduleMeeting)
                await createLinkIfNeeded(chatId: scheduledMeeting.chatId)
                await scheduleMeetingCreationComplete(scheduledMeeting)
            } catch {
                router.hideSpinner()
                MEGALogDebug("Failed to create scheduled meeting with \(error)")
            }
         }
    }
    
    private func createLinkIfNeeded(chatId: ChatIdEntity) async {
        if meetingLinkEnabled {
            do {
                guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatId) else { return }
                _ = try await chatLinkUseCase.createChatLink(for: chatRoom)
            } catch {
                router.hideSpinner()
                MEGALogDebug("Failed to create link meeting with \(error)")
            }
        }
    }
    
    @MainActor
    private func scheduleMeetingCreationComplete(_ scheduledMeeting: ScheduledMeetingEntity) {
        self.router.showMeetingInfo(for: scheduledMeeting)
    }
}
