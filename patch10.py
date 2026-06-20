import re

with open('c:/Ngam/lib/widgets/chat/user_group_conversation_card.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add ChatService import
if \"import '../../services/chat_service.dart';\" not in content:
    content = content.replace(\"import '../../models/chat_model.dart';\", \"import '../../models/chat_model.dart';\\nimport '../../services/chat_service.dart';\")

# Add calculation logic
logic = '''  @override
  Widget build(BuildContext context) {
    int inProgress = 0;
    int completed = 0;
    int unreadCount = 0;

    for (var c in widget.conversations) {
      unreadCount += c.unreadCount;
      if (c.gigId != null) {
        final gigData = ChatService.getCachedGigSync(c.gigId!);
        final status = gigData?['status']?.toString().toUpperCase();
        if (status == 'IN-PROGRESS') inProgress++;
        else if (status == 'COMPLETED') completed++;
      }
    }

    final avatarColor = AppTheme.primary;'''
content = content.replace('''  @override
  Widget build(BuildContext context) {
    final avatarColor = AppTheme.primary;''', logic)

# Add helper for badge
helper = '''class _UserGroupConversationCardState extends State<UserGroupConversationCard> {
  bool _isExpanded = false;

  Widget _buildBadge(IconData icon, Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override'''
content = content.replace('''class _UserGroupConversationCardState extends State<UserGroupConversationCard> {
  bool _isExpanded = false;

  @override''', helper)

# Replace the Header structure
header_old = '''                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: widget.isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          HugeIcon(icon: HugeIcons.strokeRoundedWorkHistory, color: AppTheme.primary, size: 26),
                          const SizedBox(width: 4),
                          Text(
                            '',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    HugeIcon(
                      icon: _isExpanded ? HugeIcons.strokeRoundedArrowUp01 : HugeIcons.strokeRoundedArrowDown01,
                      color: widget.isDark ? Colors.white54 : Colors.black54,
                      size: 20,
                    ),
                  ],'''

header_new = '''                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: widget.isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _buildBadge(HugeIcons.strokeRoundedWorkHistory, AppTheme.primary, ''),
                              if (inProgress > 0) _buildBadge(HugeIcons.strokeRoundedHourglass, Colors.blue, ''),
                              if (completed > 0) _buildBadge(HugeIcons.strokeRoundedTick01, Colors.green, ''),
                              if (unreadCount > 0) _buildBadge(HugeIcons.strokeRoundedMessageMultiple01, Colors.orange, ''),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    HugeIcon(
                      icon: _isExpanded ? HugeIcons.strokeRoundedArrowUp01 : HugeIcons.strokeRoundedArrowDown01,
                      color: widget.isDark ? Colors.white54 : Colors.black54,
                      size: 20,
                    ),
                  ],'''
content = content.replace(header_old, header_new)

# Fix withOpacity deprecation
content = content.replace('.withOpacity(', '.withValues(alpha: ')

with open('c:/Ngam/lib/widgets/chat/user_group_conversation_card.dart', 'w', encoding='utf-8') as f:
    f.write(content)
