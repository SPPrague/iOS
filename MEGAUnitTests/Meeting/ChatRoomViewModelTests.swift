import XCTest
@testable import MEGA
import MEGADomain
import MEGADomainMock

final class ChatRoomViewModelTests: XCTestCase {
    
    func test_ScheduledMeetingManagementMessage_MeetingCreatedMyself() async throws {
        let chatListItemEntity = ChatListItemEntity(lastMessageType: .scheduledMeeting, lastMessageSender: 1001)
        let userUseCase = MockUserUseCase(handle: 1001)
        let viewModel = ChatRoomViewModel(chatListItem: chatListItemEntity, userUseCase: userUseCase)
        try await viewModel.updateDescription()
        XCTAssertTrue(viewModel.description == Strings.Localizable.Chat.Listing.Description.MeetingCreated.message("Me"))
    }
    
    func test_ScheduledMeetingManagementMessage_MeetingCreatedByOthers() async throws {
        let chatListItemEntity = ChatListItemEntity(lastMessageType: .scheduledMeeting, lastMessageSender: 1002)
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNamesCompletion: .success([(handle: 1002, name: "Bob")]))
        let viewModel = ChatRoomViewModel(chatListItem: chatListItemEntity, chatRoomUseCase: chatRoomUseCase)
        try await viewModel.updateDescription()
        XCTAssertTrue(viewModel.description == Strings.Localizable.Chat.Listing.Description.MeetingCreated.message("Bob"))
    }
}


