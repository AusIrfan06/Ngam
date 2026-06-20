import re

with open('c:/Ngam/lib/screens/shared/chat_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add imports
imports = '''import '../../services/chat_service.dart';
import '../../widgets/chat/user_group_conversation_card.dart';'''
content = content.replace(\"import '../../services/chat_service.dart';\", imports)

# 2. Add SwipeToReply
swipe_to_reply_code = '''
class SwipeToReply extends StatefulWidget {
  final Widget child;
  final VoidCallback onSwipe;
  final bool isMe;

  const SwipeToReply({
    super.key,
    required this.child,
    required this.onSwipe,
    required this.isMe,
  });

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply> with SingleTickerProviderStateMixin {
  double _dragOffset = 0.0;
  final double _maxDrag = 60.0;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animationController.addListener(() {
      setState(() {
        _dragOffset = _animation.value;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _resetDrag() {
    _animation = Tween<double>(begin: _dragOffset, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: (details) {
        setState(() {
          _dragOffset += details.delta.dx;
          if (widget.isMe) {
            _dragOffset = _dragOffset.clamp(-_maxDrag, 0.0);
          } else {
            _dragOffset = _dragOffset.clamp(0.0, _maxDrag);
          }
        });
      },
      onHorizontalDragEnd: (details) {
        if (_dragOffset.abs() >= _maxDrag * 0.8) {
          widget.onSwipe();
        }
        _resetDrag();
      },
      onHorizontalDragCancel: () {
        _resetDrag();
      },
      child: Stack(
        alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
        children: [
          if (_dragOffset.abs() > 10)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Icon(
                Icons.reply_rounded,
                color: Colors.grey.withValues(alpha: (_dragOffset.abs() / _maxDrag).clamp(0.0, 1.0)),
              ),
            ),
          Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
'''
if 'class SwipeToReply' not in content:
    content += swipe_to_reply_code

# Replace Dismissible with SwipeToReply
dismissible_old = '''                    return Dismissible(
                      key: ValueKey('dismiss_'),
                  direction: msg.senderId == currentUserId ? DismissDirection.endToStart : DismissDirection.startToEnd,
                  confirmDismiss: (direction) async {
                    setState(() => _replyingToMessage = msg);
                    HapticFeedback.lightImpact();
                    return false;
                  },
                  background: Align(
                    alignment: msg.senderId == currentUserId ? Alignment.centerRight : Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Icon(Icons.reply_rounded, color: isDark ? Colors.white54 : Colors.black54),
                    ),
                  ),'''

swipe_to_reply_new = '''                    return SwipeToReply(
                      isMe: msg.senderId == currentUserId,
                      onSwipe: () {
                        setState(() => _replyingToMessage = msg);
                        HapticFeedback.lightImpact();
                      },'''
content = content.replace(dismissible_old, swipe_to_reply_new)

# 3. Quick Action Chip
quick_old = '''  Widget _buildQuickActionChip(String text, bool isDark) {
    return GestureDetector(
      onTap: () {
        _controller.text = text;
      },'''
quick_new = '''  Widget _buildQuickActionChip(String text, bool isDark) {
    return GestureDetector(
      onTap: () {
        _controller.text = text;
        _sendMessage();
      },'''
content = content.replace(quick_old, quick_new)

# 4. Group UI in ListView
listview_old = '''                      if (conversations.isEmpty) {
                         return Center(child: Text("No matching conversations."));
                      }
                      
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                        physics: const BouncingScrollPhysics(),
                        itemCount: conversations.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final c = conversations[index];
                          final isOnline = c.otherUser != null && _onlineUserIds.contains(c.otherUser!.id);
                          return _ConversationTile(
                            conversation: c,
                            currentUserId: currentUser.id,
                            isDark: isDark,
                            isOnline: isOnline,
                            onTap: () => _openChat(context, c, isDark),
                            onLongPress: () => _showDeleteDialog(context, c),
                          );
                        },
                      );'''

listview_new = '''                      final groupedConversations = <String, List<ConversationModel>>{};
                      for (var c in conversations) {
                        if (c.otherUser == null) continue;
                        groupedConversations.putIfAbsent(c.otherUser!.id, () => []).add(c);
                      }
                      
                      final groupedList = groupedConversations.values.toList();

                      if (groupedList.isEmpty) {
                         return Center(child: Text("No matching conversations."));
                      }
                      
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                        physics: const BouncingScrollPhysics(),
                        itemCount: groupedList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final userConvs = groupedList[index];
                          final otherUser = userConvs.first.otherUser!;
                          final isOnline = _onlineUserIds.contains(otherUser.id);
                          return UserGroupConversationCard(
                            otherUser: otherUser,
                            conversations: userConvs,
                            currentUserId: currentUser.id,
                            isDark: isDark,
                            isOnline: isOnline,
                            onTap: (c) => _openChat(context, c, isDark),
                            onLongPress: (c) => _showDeleteDialog(context, c),
                          );
                        },
                      );'''
content = content.replace(listview_old, listview_new)

# 5. Remove _ConversationTile
# We find the start of class _ConversationTile and remove everything until the end of the file, except class _GlassIconButton if we need it.
# Wait, _GlassIconButton is at the end.
start_idx = content.find('class _ConversationTile extends StatefulWidget {')
if start_idx != -1:
    end_idx = content.find('class _GlassIconButton extends StatelessWidget {')
    if end_idx != -1:
        content = content[:start_idx] + content[end_idx:]
    else:
        # If _GlassIconButton isn't there, just chop to end
        content = content[:start_idx]


with open('c:/Ngam/lib/screens/shared/chat_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
