import re

with open('c:/Ngam/lib/widgets/chat/user_group_conversation_card.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Make it a StatefulWidget
content = content.replace('class UserGroupConversationCard extends StatelessWidget {', '''import 'package:hugeicons/hugeicons.dart';

class UserGroupConversationCard extends StatefulWidget {''')

content = content.replace('  const UserGroupConversationCard({', '''  const UserGroupConversationCard({''')

# Replace the build method definition
content = content.replace('''  });

  @override
  Widget build(BuildContext context) {
    final avatarColor = AppTheme.primary;''', '''  });

  @override
  State<UserGroupConversationCard> createState() => _UserGroupConversationCardState();
}

class _UserGroupConversationCardState extends State<UserGroupConversationCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final avatarColor = AppTheme.primary;
    final avatarUrl = widget.otherUser.avatarUrl;
    final name = widget.otherUser.name;
    final isDark = widget.isDark;
    final isOnline = widget.isOnline;
    final conversations = widget.conversations;
    final currentUserId = widget.currentUserId;
    final onTap = widget.onTap;
    final onLongPress = widget.onLongPress;
''')

# Replace widget. access in the build method
# We already extracted the variables above, but let's check if the rest of the code uses otherUser.avatarUrl directly.
content = content.replace('otherUser.avatarUrl', 'widget.otherUser.avatarUrl')
content = content.replace('otherUser.name', 'widget.otherUser.name')

# Wrap Header in InkWell
header_old = '''            // User Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: ['''

header_new = '''            // User Header
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: ['''
content = content.replace(header_old, header_new)

# Add Trailing to Header
trailing_old = '''                  Expanded(
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
            
            // Divider'''

trailing_new = '''                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        HugeIcon(icon: HugeIcons.strokeRoundedWorkHistory, color: AppTheme.primary, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '',
                          style: TextStyle(
                            fontSize: 12,
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
                    color: isDark ? Colors.white54 : Colors.black54,
                    size: 20,
                  ),
                ],
              ),
            ),
            
            // Divider'''
content = content.replace(trailing_old, trailing_new)

# Wrap List in AnimatedSize or if (_isExpanded)
list_old = '''            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(
                height: 1,
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),

            // List of Conversations (Gigs)
            ...conversations.map((c) => ConversationSubTile(
                  conversation: c,
                  currentUserId: currentUserId,
                  isDark: isDark,
                  onTap: () => onTap(c),
                  onLongPress: () => onLongPress(c),
                )),
          ],
        ),'''

list_new = '''            // Content
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _isExpanded ? Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(
                      height: 1,
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                  ),
                  ...conversations.map((c) => ConversationSubTile(
                        conversation: c,
                        currentUserId: currentUserId,
                        isDark: isDark,
                        onTap: () => onTap(c),
                        onLongPress: () => onLongPress(c),
                      )),
                  const SizedBox(height: 8),
                ],
              ) : const SizedBox(width: double.infinity),
            ),
          ],
        ),'''
content = content.replace(list_old, list_new)

with open('c:/Ngam/lib/widgets/chat/user_group_conversation_card.dart', 'w', encoding='utf-8') as f:
    f.write(content)
