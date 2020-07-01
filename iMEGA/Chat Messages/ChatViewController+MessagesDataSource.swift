import MessageKit

extension ChatViewController: MessagesDataSource {

    public func currentSender() -> SenderType {
        return myUser
    }

    public func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }

    public func messageForItem(at indexPath: IndexPath,
                               in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        guard let chatMessage = messages[indexPath.section] as? ChatMessage else {
            return nil
        }
        
        if isTimeLabelVisible(at: indexPath) {
            var topLabelString: String = chatMessage.sentDate.string(withDateFormat: "hh:mm")
            
            if !isFromCurrentSender(message: messages[indexPath.section]) && chatRoom.isGroup {
                let displayName = !chatMessage.message.isManagementMessage ? "\(chatMessage.displayName) " : ""
                topLabelString = displayName + topLabelString
            }
            
            return NSAttributedString(
                string: topLabelString,
                attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13.0, weight: .medium),
                             NSAttributedString.Key.foregroundColor: UIColor.mnz_primaryGray(for: traitCollection)])
        }
        return nil
    }

    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if isDateLabelVisible(for: indexPath) {
            return NSAttributedString(
                string: message.sentDate.string(withDateFormat: "E dd MMM") ,
                attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15.0, weight: .bold),
                             NSAttributedString.Key.foregroundColor: UIColor.mnz_primaryGray(for: traitCollection)])

        }

        return nil
    }
    
    func messageHeaderView(for indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageReusableView {
        
        guard MEGASdkManager.sharedMEGAChatSdk()?.isFullHistoryLoaded(forChat: chatRoom.chatId) ?? false else {
            let loadingMessagesHeaderView = messagesCollectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: LoadingMessageReusableView.reuseIdentifier, for: indexPath)  as! LoadingMessageReusableView
            loadingMessagesHeaderView.loadingView.mnz_startShimmering()
            return loadingMessagesHeaderView
        }
        
        let chatMessageHeaderView = messagesCollectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ChatViewIntroductionHeaderView.reuseIdentifier, for: indexPath) as! ChatViewIntroductionHeaderView
        chatMessageHeaderView.chatRoom = chatRoom
        return chatMessageHeaderView
    }
    
    func messageFooterView(for indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageReusableView {
   
        guard let chatMessageReactionView = messagesCollectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: MessageReactionReusableView.reuseIdentifier, for: indexPath) as? MessageReactionReusableView else {
            fatalError("Failed to dequeue MessageReactionReusableView")
        }
        
        if let chatMessage = messages[indexPath.section] as? ChatMessage  {
            chatMessageReactionView.chatMessage = chatMessage
        }
        
        chatMessageReactionView.delegate = self
        return chatMessageReactionView
    }
}

extension ChatViewController: MessageReactionReusableViewDelegate {
    func emojiTapped(_ emoji: String, chatMessage: ChatMessage) {
        print("emoji tapped \(emoji), for chat message \(chatMessage.messageId)")
    }
    
    func emojiLongPressed(_ emoji: String, chatMessage: ChatMessage) {
        guard let emojisStringList = MEGASdkManager
            .sharedMEGAChatSdk()?
            .getMessageReactions(forChat: chatRoom.chatId,
                                 messageId: chatMessage.message.messageId) else {
                                    MEGALogDebug("Could not fetch the emoji list for a message")
                                    return
        }
        
        let emojis = (0..<emojisStringList.size).compactMap { emojisStringList.string(at: $0) }
        let vc = ReactedEmojisUsersListViewController(dataSource: self,
                                                      emojiList: emojis,
                                                      selectedEmoji: emoji,
                                                      chatId: chatRoom.chatId,
                                                      messageId: chatMessage.message.messageId)
        presentPanModal(vc)
    }
}

extension ChatViewController: ReactedEmojisUsersListViewControllerDataSource {
    func userhandleList(forEmoji emoji: String, chatId: UInt64, messageId: UInt64) -> [UInt64] {
        guard let userHandleList =  MEGASdkManager
            .sharedMEGAChatSdk()?
            .getReactionUsers(forChat: chatId, messageId: messageId, reaction: emoji) else {
                MEGALogDebug("user handle list for emoji \(emoji) is empty")
            return []
        }
        
        return (0..<userHandleList.size).compactMap { userHandleList.megaHandle(at: $0) }
    }
}
