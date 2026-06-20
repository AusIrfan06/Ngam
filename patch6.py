import re

with open('c:/Ngam/lib/screens/shared/chat_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix trackPresence
old_track = '''      ChatService.trackPresence(
        currentUserId: currentUser.id, 
        isRunner: currentUser.role == 'runner', 
        onUpdate: (onlineIds) {
          if (mounted) setState(() => _onlineUserIds = onlineIds);
        }
      );'''

new_track = '''      ChatService.trackPresence(currentUser.id);
      ChatService.onlineUsers.addListener(_onPresenceUpdate);'''
content = content.replace(old_track, new_track)

# Add listener callback
callback = '''
  void _onPresenceUpdate() {
    if (mounted) {
      setState(() {
        _onlineUserIds = ChatService.onlineUsers.value;
      });
    }
  }

  @override
  void dispose() {'''
content = content.replace('  @override\\n  void dispose() {', callback)

# Stop tracking removal of listener
dispose_old = '''  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    ChatService.stopTrackingPresence();
    super.dispose();
  }'''
dispose_new = '''  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    ChatService.onlineUsers.removeListener(_onPresenceUpdate);
    ChatService.stopTrackingPresence();
    super.dispose();
  }'''
content = content.replace(dispose_old, dispose_new)

with open('c:/Ngam/lib/screens/shared/chat_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
