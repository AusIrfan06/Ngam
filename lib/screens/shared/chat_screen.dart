import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../utils/app_theme.dart';

// ============================================================
// Ngam App — Chat Screen
// Glassmorphic conversation list with message thread UI
// ============================================================

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Mock conversations
  final List<_Conversation> _conversations = [
    _Conversation(
      name: 'Ahmad Razif',
      lastMessage: 'Ok nanti saya hantar barang tu.',
      time: '2m ago',
      unread: 2,
      isOnline: true,
      avatar: 'A',
      avatarColor: const Color(0xFF3498DB),
    ),
    _Conversation(
      name: 'Siti Rahimah',
      lastMessage: 'Dah siap, boleh pickup sekarang!',
      time: '18m ago',
      unread: 0,
      isOnline: true,
      avatar: 'S',
      avatarColor: const Color(0xFF2ECC71),
    ),
    _Conversation(
      name: 'Hairul Fikri',
      lastMessage: 'Terima kasih, semua ok 👍',
      time: '1h ago',
      unread: 0,
      isOnline: false,
      avatar: 'H',
      avatarColor: AppTheme.primary,
    ),
    _Conversation(
      name: 'Nadia Aziz',
      lastMessage: 'Boleh tolong carikan barang ni?',
      time: '3h ago',
      unread: 1,
      isOnline: false,
      avatar: 'N',
      avatarColor: const Color(0xFFE91E96),
    ),
    _Conversation(
      name: 'Zulaikha Md',
      lastMessage: 'Task selesai, payment dah transfer.',
      time: 'Yesterday',
      unread: 0,
      isOnline: false,
      avatar: 'Z',
      avatarColor: const Color(0xFF9B59B6),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
              children: [
                // ─── Header ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Messages',
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      _GlassIconButton(
                        isDark: isDark,
                        icon: HugeIcons.strokeRoundedPencilEdit01,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),

                // ─── Search Bar ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: GlassContainer(
                    useOwnLayer: true,
                    quality: GlassQuality.standard,
                    shape: LiquidRoundedSuperellipse(borderRadius: 20.0),
                    settings: _glassSettings(isDark),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.7),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedSearch01,
                            color: Colors.grey.shade500,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Search conversations...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ─── Online Users Row ────────────────────────────
                SizedBox(
                  height: 88,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _conversations.where((c) => c.isOnline).length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _OnlineAvatarItem(
                          name: 'You',
                          avatar: 'M',
                          color: AppTheme.primary,
                          isMe: true,
                          isDark: isDark,
                        );
                      }
                      final online = _conversations.where((c) => c.isOnline).toList();
                      final c = online[index - 1];
                      return _OnlineAvatarItem(
                        name: c.name.split(' ').first,
                        avatar: c.avatar,
                        color: c.avatarColor,
                        isDark: isDark,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // ─── Section label ───────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'RECENT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),

                // ─── Conversation List ───────────────────────────
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _conversations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final c = _conversations[index];
                      return _ConversationTile(
                        conversation: c,
                        isDark: isDark,
                        onTap: () => _openChat(context, c, isDark),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
  }

  void _openChat(BuildContext context, _Conversation c, bool isDark) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ChatThreadScreen(conversation: c),
      ),
    );
  }

  LiquidGlassSettings _glassSettings(bool isDark) => LiquidGlassSettings(
        thickness: 0.1,
        blur: 15,
        refractiveIndex: 1.0,
        glassColor: Colors.transparent,
        lightAngle: 45.0,
        lightIntensity: isDark ? 0.1 : 0.2,
        ambientStrength: 1.0,
        saturation: 1.0,
        chromaticAberration: 0.0,
      );
}

// ─── Conversation Tile ────────────────────────────────────────
class _ConversationTile extends StatelessWidget {
  final _Conversation conversation;
  final bool isDark;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = conversation;
    return GestureDetector(
      onTap: onTap,
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
          lightIntensity: isDark ? 0.1 : 0.2,
          ambientStrength: 1.0,
          saturation: 1.0,
          chromaticAberration: 0.0,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          child: Row(
            children: [
              // Avatar with online dot
              Stack(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: c.avatarColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: c.avatarColor.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        c.avatar,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: c.avatarColor,
                        ),
                      ),
                    ),
                  ),
                  if (c.isOnline)
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppTheme.success,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? const Color(0xFF13131A) : Colors.white,
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
                      c.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: c.unread > 0 ? FontWeight.w800 : FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      c.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: c.unread > 0 ? FontWeight.w600 : FontWeight.w400,
                        color: c.unread > 0
                            ? (isDark ? Colors.white70 : Colors.black87)
                            : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Time + unread badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    c.time,
                    style: TextStyle(
                      fontSize: 11,
                      color: c.unread > 0 ? AppTheme.primary : Colors.grey.shade500,
                      fontWeight: c.unread > 0 ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (c.unread > 0)
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${c.unread}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Online Avatar Row Item ───────────────────────────────────
class _OnlineAvatarItem extends StatelessWidget {
  final String name;
  final String avatar;
  final Color color;
  final bool isDark;
  final bool isMe;

  const _OnlineAvatarItem({
    required this.name,
    required this.avatar,
    required this.color,
    required this.isDark,
    this.isMe = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isMe ? 1.0 : 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
              ),
              child: Center(
                child: isMe
                    ? const Icon(Icons.add_rounded, color: Colors.white, size: 22)
                    : Text(
                        avatar,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
              ),
            ),
            if (!isMe)
              Positioned(
                right: 2,
                bottom: 2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppTheme.success,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF13131A) : const Color(0xFFF8F9FA),
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }
}

// ─── Glass Icon Button ────────────────────────────────────────
class _GlassIconButton extends StatelessWidget {
  final bool isDark;
  final dynamic icon;
  final VoidCallback onTap;

  const _GlassIconButton({
    required this.isDark,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        useOwnLayer: true,
        quality: GlassQuality.standard,
        shape: LiquidRoundedSuperellipse(borderRadius: 16.0),
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.7),
              width: 1.0,
            ),
          ),
          child: HugeIcon(
            icon: icon,
            color: isDark ? Colors.white : Colors.black87,
            size: 20,
          ),
        ),
      ),
    );
  }
}

// ─── Chat Thread Screen ───────────────────────────────────────
class _ChatThreadScreen extends StatefulWidget {
  final _Conversation conversation;

  const _ChatThreadScreen({required this.conversation});

  @override
  State<_ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<_ChatThreadScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_Message> _messages = [
    _Message(text: 'Hai! Boleh tolong hantar barang ni?', isMe: false, time: '2:30 PM'),
    _Message(text: 'Boleh, lokasi mana?', isMe: true, time: '2:31 PM'),
    _Message(text: 'Taman Sri Muda, Shah Alam. Dekat dengan Mydin.', isMe: false, time: '2:32 PM'),
    _Message(text: 'Ok boleh. Berapa berat barang tu?', isMe: true, time: '2:33 PM'),
    _Message(text: 'Tak berat sangat, dalam 3kg je. Boleh bawa motor.', isMe: false, time: '2:34 PM'),
    _Message(text: 'Ok nanti saya hantar barang tu.', isMe: false, time: '2:35 PM'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_Message(text: text, isMe: true, time: 'Now'));
    });
    _controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = widget.conversation;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: isDark ? Colors.white : Colors.black87,
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c.avatarColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: c.avatarColor.withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      c.avatar,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: c.avatarColor,
                      ),
                    ),
                  ),
                ),
                if (c.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppTheme.success,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF13131A) : Colors.white,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  c.isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 11,
                    color: c.isOnline ? AppTheme.success : Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          _GlassIconButton(isDark: isDark, icon: HugeIcons.strokeRoundedCall02, onTap: () {}),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          // ─── Messages ────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              physics: const BouncingScrollPhysics(),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _MessageBubble(message: msg, isDark: isDark);
              },
            ),
          ),

          // ─── Input Bar ───────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              16, 8, 16,
              // When keyboard is open Scaffold already pushes us up — just add 8px gap.
              // When keyboard is closed use the device safe area bottom.
              MediaQuery.of(context).viewInsets.bottom > 0
                  ? 8
                  : MediaQuery.of(context).padding.bottom + 8,
            ),
            child: GlassContainer(
              useOwnLayer: true,
              quality: GlassQuality.standard,
              shape: LiquidRoundedSuperellipse(borderRadius: 32.0),
              settings: LiquidGlassSettings(
                thickness: 0.1,
                blur: 20,
                refractiveIndex: 1.0,
                glassColor: Colors.transparent,
                lightAngle: 45.0,
                lightIntensity: isDark ? 0.1 : 0.2,
                ambientStrength: 1.0,
                saturation: 1.0,
                chromaticAberration: 0.0,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.8),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedAttachment01,
                      color: Colors.grey.shade500,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onSubmitted: (_) => _sendMessage(),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          filled: false,
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedSent,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Message Bubble ───────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final _Message message;
  final bool isDark;

  const _MessageBubble({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) const SizedBox(width: 8),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? AppTheme.primary
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.8)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                border: isMe
                    ? null
                    : Border.all(
                        color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.6),
                        width: 1.0,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: (isMe ? AppTheme.primary : Colors.black).withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.time,
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.white.withValues(alpha: 0.7) : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ─── Data Models ──────────────────────────────────────────────
class _Conversation {
  final String name;
  final String lastMessage;
  final String time;
  final int unread;
  final bool isOnline;
  final String avatar;
  final Color avatarColor;

  const _Conversation({
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unread,
    required this.isOnline,
    required this.avatar,
    required this.avatarColor,
  });
}

class _Message {
  final String text;
  final bool isMe;
  final String time;

  const _Message({required this.text, required this.isMe, required this.time});
}
