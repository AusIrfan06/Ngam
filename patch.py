import re

with open('c:/Ngam/lib/screens/shared/chat_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add _sendMessage to quick action chip
content = content.replace('''  Widget _buildQuickActionChip(String text, bool isDark) {
    return GestureDetector(
      onTap: () {
        _controller.text = text;
      },''', '''  Widget _buildQuickActionChip(String text, bool isDark) {
    return GestureDetector(
      onTap: () {
        _controller.text = text;
        _sendMessage();
      },''')

# 2. Add SwipeToReply
swipe_to_reply_code = '''
class _SwipeToReply extends StatefulWidget {
  final Widget child;
  final VoidCallback onSwipe;
  final bool isMe;

  const _SwipeToReply({
    required this.child,
    required this.onSwipe,
    required this.isMe,
  });

  @override
  State<_SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<_SwipeToReply> with SingleTickerProviderStateMixin {
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
if '_SwipeToReply' not in content:
    content += swipe_to_reply_code

# Replace Dismissible with _SwipeToReply
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

swipe_to_reply_new = '''                    return _SwipeToReply(
                      isMe: msg.senderId == currentUserId,
                      onSwipe: () {
                        setState(() => _replyingToMessage = msg);
                        HapticFeedback.lightImpact();
                      },'''
content = content.replace(dismissible_old, swipe_to_reply_new)

# 3. Add Grouping UI
imports_part = "import '../../services/chat_service.dart';"
if "import '../../models/user_model.dart';" not in content:
    content = content.replace(imports_part, imports_part + "\\nimport '../../models/user_model.dart';")

group_list_old = '''                      if (conversations.isEmpty) {
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

group_list_new = '''                      final groupedConversations = <String, List<ConversationModel>>{};
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
                          return _UserGroupConversationCard(
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
content = content.replace(group_list_old, group_list_new)

# 4. Convert _ConversationTile to Sub-Tile and add _UserGroupConversationCard
user_group_card = '''
class _UserGroupConversationCard extends StatelessWidget {
  final UserModel otherUser;
  final List<ConversationModel> conversations;
  final String currentUserId;
  final bool isDark;
  final bool isOnline;
  final void Function(ConversationModel) onTap;
  final void Function(ConversationModel) onLongPress;

  const _UserGroupConversationCard({
    required this.otherUser,
    required this.conversations,
    required this.currentUserId,
    required this.isDark,
    required this.isOnline,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final avatarColor = AppTheme.primary;
    final avatarUrl = otherUser.avatarUrl;
    final name = otherUser.name;
    final avatar = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return GlassContainer(
      useOwnLayer: true,
      quality: GlassQuality.standard,
      shape: LiquidRoundedSuperellipse(borderRadius: 24.0),
      settings: LiquidGlassSettings(
        thickness: 0.1,
        blur: 15,
        refractiveIndex: 1.0,
        glassColor: Colors.transparent,
        lightAngle: 45.0,
        lightIntensity: isDark ? 0.1 : 0.2,
        ambientStrength: 1.0,
        saturation: 1.0,
        chromaticAberration: 0.0,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.7),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: avatarColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: avatarColor.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          image: avatarUrl != null
                              ? DecorationImage(
                                  image: CachedNetworkImageProvider(avatarUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: avatarUrl == null
                            ? Center(
                                child: Text(
                                  avatar,
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: avatarColor,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      if (isOnline)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(
                height: 1,
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),

            // List of Conversations (Gigs)
            ...conversations.map((c) => _ConversationTile(
                  conversation: c,
                  currentUserId: currentUserId,
                  isDark: isDark,
                  isOnline: isOnline,
                  onTap: () => onTap(c),
                  onLongPress: () => onLongPress(c),
                )),
          ],
        ),
      ),
    );
  }
}
'''
if '_UserGroupConversationCard' not in content:
    content += user_group_card

# Now modify _ConversationTile.build
build_old = '''  @override
  Widget build(BuildContext context) {
    final c = widget.conversation;
    final otherUser = c.otherUser;
    
    final String name = otherUser?.name ?? 'Unknown';
    final String? avatarUrl = otherUser?.avatarUrl;
    final String avatar = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final Color avatarColor = AppTheme.primary; // Or generate based on name
    String lastMsg = c.lastMessage ?? 'Started a conversation';'''

build_new = '''  @override
  Widget build(BuildContext context) {
    final c = widget.conversation;
    String lastMsg = c.lastMessage ?? 'Started a conversation';'''
content = content.replace(build_old, build_new)

tile_ui_old = '''    return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          child: GlassContainer(
            useOwnLayer: true,
            quality: GlassQuality.standard,
            shape: LiquidRoundedSuperellipse(borderRadius: 24.0),
            settings: LiquidGlassSettings(
              thickness: 0.1,
              blur: 15,
              refractiveIndex: 1.0,
              glassColor: Colors.transparent,
              lightAngle: 45.0,
              lightIntensity: widget.isDark ? 0.1 : 0.2,
              ambientStrength: 1.0,
              saturation: 1.0,
              chromaticAberration: 0.0,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: widget.isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: widget.isDark ? 0.12 : 0.7),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: widget.isDark ? 0.15 : 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Avatar with online dot
                  Stack(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: avatarColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: avatarColor.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          image: avatarUrl != null
                              ? DecorationImage(
                                  image: CachedNetworkImageProvider(avatarUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: avatarUrl == null
                            ? Center(
                                child: Text(
                                  avatar,
                                  style: GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: avatarColor,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      if (widget.isOnline)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),

                  // Name + last message
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: unread > 0 ? FontWeight.w800 : FontWeight.w600,
                            color: widget.isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 3),'''

tile_ui_new = '''    final gigTitle = c.gigId != null 
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
                  const SizedBox(height: 4),'''
content = content.replace(tile_ui_old, tile_ui_new)

tile_tail_old = '''                          child: Center(
                            child: Text(
                              '',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
  }'''

tile_tail_new = '''                          child: Center(
                            child: Text(
                              unread > 99 ? '99+' : unread.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }'''
content = content.replace(tile_tail_old, tile_tail_new)

with open('c:/Ngam/lib/screens/shared/chat_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
