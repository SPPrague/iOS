import XCTest
import MEGASdk
import MEGADataMock
import MEGAData

final class CurrentUserSourceTests: XCTestCase {
    func testUserFields_init_empty() {
        let source = CurrentUserSource(sdk: MockSdk())
        XCTAssertNil(source.currentUserHandle)
        XCTAssertNil(source.currentUserEmail)
        XCTAssertTrue(source.isGuest)
    }
    
    func testUserFields_init_nonEmpty() {
        let source = CurrentUserSource(sdk: MockSdk(myUser: MockUser(handle: 5, email: "abc@mega.nz")))
        XCTAssertEqual(source.currentUserEmail, "abc@mega.nz")
        XCTAssertEqual(source.currentUserHandle, 5)
        XCTAssertFalse(source.isGuest)
    }
    
    func testUserFields_login_updateHandle() {
        let sdk = MockSdk()
        let source = CurrentUserSource(sdk: sdk)
        XCTAssertNil(source.currentUserHandle)
        XCTAssertNil(source.currentUserEmail)
        XCTAssertTrue(source.isGuest)
        
        sdk._myUser = MockUser(handle: 10, email: "hello@mega.nz")
        XCTAssertNil(source.currentUserHandle)
        XCTAssertNil(source.currentUserEmail)
        XCTAssertTrue(source.isGuest)
        
        NotificationCenter.default.post(name: .accountDidLogin, object: nil)
        let exp = expectation(description: "login")
        _ = XCTWaiter.wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(source.currentUserHandle, 10)
        XCTAssertNil(source.currentUserEmail)
        XCTAssertTrue(source.isGuest)
    }
    
    func testUserFields_fetchNodes_updateEmail() {
        let sdk = MockSdk()
        let source = CurrentUserSource(sdk: sdk)
        XCTAssertNil(source.currentUserHandle)
        XCTAssertNil(source.currentUserEmail)
        XCTAssertTrue(source.isGuest)
        
        sdk._myUser = MockUser(handle: 10, email: "hello@mega.nz")
        XCTAssertNil(source.currentUserHandle)
        XCTAssertNil(source.currentUserEmail)
        XCTAssertTrue(source.isGuest)
        
        NotificationCenter.default.post(name: .accountDidFinishFetchNodes, object: nil)
        let exp = expectation(description: "login")
        _ = XCTWaiter.wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(source.currentUserEmail, "hello@mega.nz")
        XCTAssertNil(source.currentUserHandle)
        XCTAssertFalse(source.isGuest)
    }
    
    func testUserFields_logout_empty() {
        let source = CurrentUserSource(sdk: MockSdk(myUser: MockUser(handle: 5, email: "abc@mega.nz")))
        XCTAssertEqual(source.currentUserEmail, "abc@mega.nz")
        XCTAssertEqual(source.currentUserHandle, 5)
        XCTAssertFalse(source.isGuest)
        
        NotificationCenter.default.post(name: .accountDidLogout, object: nil)
        let exp = expectation(description: "logout")
        _ = XCTWaiter.wait(for: [exp], timeout: 1.0)
        XCTAssertNil(source.currentUserHandle)
        XCTAssertNil(source.currentUserEmail)
        XCTAssertTrue(source.isGuest)
    }
    
    func testChangeEmail_notCurrentUser_noEmailChange() {
        let source = CurrentUserSource(sdk: MockSdk(myUser: MockUser(handle: 5, email: "abc@mega.nz")))
        XCTAssertEqual(source.currentUserEmail, "abc@mega.nz")
        XCTAssertEqual(source.currentUserHandle, 5)
        XCTAssertFalse(source.isGuest)
        
        NotificationCenter.default.post(name: .accountEmailDidChange, object: nil, userInfo: ["user": MockUser(handle: 4, email: "4@mega.nz")])
        let exp = expectation(description: "email")
        _ = XCTWaiter.wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(source.currentUserEmail, "abc@mega.nz")
        XCTAssertEqual(source.currentUserHandle, 5)
        XCTAssertFalse(source.isGuest)
    }
    
    func testChangeEmail_currentUser_emailIsChanged() {
        let source = CurrentUserSource(sdk: MockSdk(myUser: MockUser(handle: 5, email: "abc@mega.nz")))
        XCTAssertEqual(source.currentUserEmail, "abc@mega.nz")
        XCTAssertEqual(source.currentUserHandle, 5)
        XCTAssertFalse(source.isGuest)
        
        NotificationCenter.default.post(name: .accountEmailDidChange, object: nil, userInfo: ["user": MockUser(handle: 5, email: "5@mega.nz")])
        let exp = expectation(description: "email")
        _ = XCTWaiter.wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(source.currentUserEmail, "5@mega.nz")
        XCTAssertEqual(source.currentUserHandle, 5)
        XCTAssertFalse(source.isGuest)
    }
}
