import re

with open('c:/Ngam/lib/screens/shared/chat_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix the newline on line 12
content = content.replace(\"import '../../services/chat_service.dart';\\nimport '../../models/user_model.dart';\", \"import '../../services/chat_service.dart';\\nimport '../../models/user_model.dart';\")

# Let's find the start of _ConversationTileState.build
build_start_idx = content.find('  @override\\n  Widget build(BuildContext context) {\\n    final c = widget.conversation;\\n    String lastMsg')
if build_start_idx != -1:
    # Find the end of build method
    # The build method ends right before class _GlassIconButton
    build_end_idx = content.find('// "?"?"? Glass Icon Button', build_start_idx)
    
    if build_end_idx != -1:
        # Get the old build block
        old_build = content[build_start_idx:build_end_idx]
        
        new_build = '''  @override
  Widget build(BuildContext context) {
    final c = widget.conversation;
    String lastMsg = c.lastMessage ?? 'Started a conversation';
    if (lastMsg.startsWith('__SYSTEM__:')) {
      lastMsg = lastMsg.replaceFirst('__SYSTEM__:', '');
    } else if (lastMsg.startsWith('__TASK_CARD__:')) {
      lastMsg = 'Sent a Task Card';
    } else if (lastMsg.startsWith('__QUOTE__:')) {
      lastMsg = 'Sent a Custom Quote';
    } else if (lastMsg.startsWith('__COUNTER__:')) {
      lastMsg = 'Sent a Counter-Offer';
    } else if (lastMsg == '__REQUEST_LOC__') {
      lastMsg = 'Requested your Location';
    }
    final int unread = c.unreadCount;
    final String time = c.formattedTime;
    final gigTitle = c.gigId != null 
        ? (ChatService.getCachedGigSync(c.gigId!)?['title'] ?? 'Task Chat') 
        : 'General Chat';

    return InkWell(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gigTitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: unread > 0 ? FontWeight.w800 : FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (c.lastMessageSenderId == widget.currentUserId && !_isTyping)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: MessageStatusIndicator(
                            status: 'sent',
                            isRead: c.lastMessageIsRead,
                            isMe: true,
                            defaultColor: widget.isDark ? Colors.white70 : Colors.grey.shade600,
                          ),
                        ),
                      Expanded(
                        child: _isTyping
                            ? Row(
                                children: [
                                  Text(
                                    'Typing',
                                    style: TextStyle(
                                      color: AppTheme.primary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 1,
                                  ),
                                  const SizedBox(width: 4),
                                  const SizedBox(
                                    width: 20,
                                    height: 12,
                                    child: TypingIndicator(isDark: false),
                                  ),
                                ],
                              )
                            : Text(
                                lastMsg,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.w400,
                                  color: unread > 0
                                      ? (widget.isDark ? Colors.white70 : Colors.black87)
                                      : Colors.grey.shade500,
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    color: unread > 0 ? AppTheme.primary : Colors.grey.shade500,
                    fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
                if (unread > 0) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      unread > 99 ? '99+' : unread.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ] else const SizedBox(height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

'''
        content = content.replace(old_build, new_build)

# Fix the missing isOnline in _UserGroupConversationCard constructor instantiation.
# In _ChatScreenState:
'''
                          return _UserGroupConversationCard(
                            otherUser: otherUser,
                            conversations: userConvs,
                            currentUserId: currentUser.id,
                            isDark: isDark,
                            isOnline: isOnline,
                            onTap: (c) => _openChat(context, c, isDark),
                            onLongPress: (c) => _showDeleteDialog(context, c),
                          );
'''
# Actually wait, _ConversationTile constructor instantiation was changed to _UserGroupConversationCard.
# The parameter isOnline is passed.
# Let's also remove isOnline parameter from _ConversationTile to fix the warning.
content = content.replace('final bool isOnline;', '')
content = content.replace('required this.isOnline,', '')

with open('c:/Ngam/lib/screens/shared/chat_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
