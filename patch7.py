import re

with open('c:/Ngam/lib/screens/shared/chat_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix getConversationsStream
content = content.replace('_conversationsStream = ChatService.getConversationsStream(currentUser.id);', \"_conversationsStream = ChatService.getConversationsStream(currentUser.id, isRunner: currentUser.role == 'runner');\")

# Add _onPresenceUpdate
if 'void _onPresenceUpdate()' not in content:
    content = content.replace('  @override\\n  void dispose() {', '''
  void _onPresenceUpdate() {
    if (mounted) {
      setState(() {
        _onlineUserIds = ChatService.onlineUsers.value;
      });
    }
  }

  @override
  void dispose() {''')

with open('c:/Ngam/lib/screens/shared/chat_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
