import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../models/user_model.dart';
import '../../models/chat_model.dart';
import '../../services/chat_service.dart';
import '../../utils/app_theme.dart';
import 'conversation_sub_tile.dart';

class UserGroupConversationCard extends StatefulWidget {
  final UserModel otherUser;
  final List<ConversationModel> conversations;
  final String currentUserId;
  final bool isDark;
  final bool isOnline;
  final void Function(ConversationModel) onTap;
  final void Function(ConversationModel) onLongPress;

  const UserGroupConversationCard({
    super.key,
    required this.otherUser,
    required this.conversations,
    required this.currentUserId,
    required this.isDark,
    required this.isOnline,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<UserGroupConversationCard> createState() => _UserGroupConversationCardState();
}

class _UserGroupConversationCardState extends State<UserGroupConversationCard> {
  bool _isExpanded = false;

  Widget _buildBadge(dynamic icon, Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, color: color, size: 18),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
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

    final avatarColor = AppTheme.primary;
    final avatarUrl = widget.otherUser.avatarUrl;
    final name = widget.otherUser.name;
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
        lightIntensity: widget.isDark ? 0.1 : 0.2,
        ambientStrength: 1.0,
        saturation: 1.0,
        chromaticAberration: 0.0,
      ),
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Header
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
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                        if (widget.isOnline)
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
                                  color: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
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
                              _buildBadge(HugeIcons.strokeRoundedWorkHistory, AppTheme.primary, '${widget.conversations.length}'),
                              if (inProgress > 0) _buildBadge(HugeIcons.strokeRoundedHourglass, Colors.blue, '$inProgress'),
                              if (completed > 0) _buildBadge(HugeIcons.strokeRoundedTick01, Colors.green, '$completed'),
                              if (unreadCount > 0) _buildBadge(HugeIcons.strokeRoundedMessageMultiple01, Colors.orange, '$unreadCount'),
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
                  ],
                ),
              ),
            ),
            
            // Content
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _isExpanded ? Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(
                      height: 1,
                      color: widget.isDark ? Colors.white12 : Colors.black12,
                    ),
                  ),
                  ...widget.conversations.map((c) => ConversationSubTile(
                        conversation: c,
                        currentUserId: widget.currentUserId,
                        isDark: widget.isDark,
                        onTap: () => widget.onTap(c),
                        onLongPress: () => widget.onLongPress(c),
                      )),
                  const SizedBox(height: 8),
                ],
              ) : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}
