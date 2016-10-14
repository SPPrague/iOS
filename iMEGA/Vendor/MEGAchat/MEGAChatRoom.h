#import <Foundation/Foundation.h>
//#import "MEGAChatSdk.h"

typedef NS_ENUM (NSInteger, MEGAChatRoomChangeType) {
    MEGAChatRoomChangeTypeStatus      = 0x01,
    MEGAChatRoomChangeTypeUnreadCount = 0x02,
    MEGAChatRoomChangeTypeParticipans = 0x04,
    MEGAChatRoomChangeTypeTitle       = 0x08,
    MEGAChatRoomChangeTypeState       = 0x10,
};

typedef NS_ENUM (NSInteger, MEGAChatRoomPrivilege) {
    MEGAChatRoomPrivilegeUnknown   = -2,
    MEGAChatRoomPrivilegeRm        = -1,
    MEGAChatRoomPrivilegeRo        = 0,
    MEGAChatRoomPrivilegeStandard  = 1,
    MEGAChatRoomPrivilegeModerator = 2
};

typedef NS_ENUM (NSInteger, MEGAChatRoomState) {
    MEGAChatRoomStateOffline    = 0,
    MEGAChatRoomStateConnecting = 1,
    MEGAChatRoomStateJoinning   = 2,
    MEGAChatRoomStateOnline     = 3
};

@interface MEGAChatRoom : NSObject

/**
 * @brief The MegaChatHandle of the chat.
 */
@property (readonly, nonatomic) uint64_t chatId;

/**
 * @brief Your privilege level in this chat
 */
@property (readonly, nonatomic) NSInteger ownPrivilege;
@property (readonly, nonatomic) NSUInteger peerCount;
@property (readonly, nonatomic, getter=isGroup) BOOL group;
@property (readonly, nonatomic) NSString *title;
@property (readonly, nonatomic) MEGAChatRoomState onlineState;
@property (readonly, nonatomic) MEGAChatRoomChangeType changes;
@property (readonly, nonatomic) NSInteger unreadCount;
//@property (readonly, nonatomic) MEGAChatStatus onlineStatus;

- (instancetype)clone;

- (NSInteger)peerPrivilegeByHandle:(uint64_t)userHande;
- (NSInteger)peerHandeAtIndex:(NSUInteger)index;
- (MEGAChatRoomPrivilege)peerPrivilegeAtIndex:(NSUInteger)index;
- (BOOL)hasChangedForType:(MEGAChatRoomChangeType)changeType;

@end
