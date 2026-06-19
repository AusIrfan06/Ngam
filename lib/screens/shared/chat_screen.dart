import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../services/chat_service.dart';
import '../../models/chat_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/gig_service.dart';
import '../../services/review_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

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
  late Stream<List<ConversationModel>> _conversationsStream;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _searchQuery = '';
  Set<String> _onlineUserIds = {};

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() {
      if (mounted) setState(() {});
    });
    final currentUser = context.read<AuthProvider>().user;
    if (currentUser != null) {
      _conversationsStream = ChatService.getConversationsStream(currentUser.id);
      ChatService.trackPresence(currentUser.id, (onlineIds) {
        if (mounted) setState(() => _onlineUserIds = onlineIds);
      });
    } else {
      _conversationsStream = const Stream.empty();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    ChatService.stopTrackingPresence();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = context.read<AuthProvider>().user;
    if (currentUser == null) return const Scaffold(body: Center(child: Text("Not logged in")));

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
                    shape: LiquidRoundedSuperellipse(borderRadius: 24.0),
                    settings: _glassSettings(isDark),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: _searchFocus.hasFocus ? 0.08 : 0.04)
                            : Colors.white.withValues(alpha: _searchFocus.hasFocus ? 0.5 : 0.2),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _searchFocus.hasFocus 
                              ? AppTheme.primary.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: isDark ? 0.1 : 0.4),
                          width: _searchFocus.hasFocus ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedSearch01,
                              color: isDark ? Colors.white70 : Colors.grey.shade600,
                              size: 20,
                              strokeWidth: 2.0,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocus,
                              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search conversations...',
                                hintStyle: TextStyle(
                                  fontSize: 15,
                                  color: isDark ? Colors.white54 : Colors.grey.shade500,
                                  fontWeight: FontWeight.w400,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                                _searchFocus.unfocus();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white24 : Colors.black12,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: isDark ? Colors.white : Colors.black87,
                                  size: 14,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
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
                  child: StreamBuilder<List<ConversationModel>>(
                    stream: _conversationsStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                         return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                         return const Center(child: Text("No conversations yet."));
                      }
                      final allConversations = snapshot.data!;
                      final conversations = _searchQuery.isEmpty 
                          ? allConversations 
                          : allConversations.where((c) {
                              final nameMatch = (c.otherUser?.name ?? '').toLowerCase().contains(_searchQuery);
                              final msgMatch = (c.lastMessage ?? '').toLowerCase().contains(_searchQuery);
                              return nameMatch || msgMatch;
                            }).toList();
                            
                      if (conversations.isEmpty) {
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
                      );
                    }
                  ),
                ),
              ],
            ),
          ),
        );
  }

  void _openChat(BuildContext context, ConversationModel c, bool isDark) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatThreadScreen(conversation: c),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, ConversationModel c) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Delete Chat?",
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          "This will permanently delete the conversation for both of you.",
          style: GoogleFonts.outfit(
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: TextStyle(color: Colors.grey.shade500)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ChatService.deleteConversation(c.id);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete chat: $e')),
                  );
                }
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
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
  final ConversationModel conversation;
  final String currentUserId;
  final bool isDark;
  final bool isOnline;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ConversationTile({
    required this.conversation,
    required this.currentUserId,
    required this.isDark,
    this.isOnline = false,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final c = conversation;
    final otherUser = c.otherUser;
    
    final String name = otherUser?.name ?? 'Unknown';
    final String? avatarUrl = otherUser?.avatarUrl;
    final String avatar = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final Color avatarColor = AppTheme.primary; // Or generate based on name
    final String lastMsg = c.lastMessage ?? 'Started a conversation';
    final int unread = c.unreadCount;
    final String time = c.formattedTime;
    
    return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          onLongPress: onLongPress,
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
                      if (isOnline)
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
                                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (c.lastMessageSenderId == currentUserId)
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: MessageStatusIndicator(
                                  status: 'sent',
                                  isRead: c.lastMessageIsRead,
                                  isMe: true,
                                  defaultColor: isDark ? Colors.white70 : Colors.grey.shade600,
                                ),
                              ),
                            Expanded(
                              child: Text(
                                lastMsg,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.w400,
                                  color: unread > 0
                                      ? (isDark ? Colors.white70 : Colors.black87)
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

                  // Time + unread badge
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
                      const SizedBox(height: 6),
                      if (unread > 0)
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$unread',
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
      behavior: HitTestBehavior.opaque,
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
class ChatThreadScreen extends StatefulWidget {
  final ConversationModel conversation;

  const ChatThreadScreen({super.key, required this.conversation});

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  
  bool _isUploadingImage = false;
  bool _isLoading = false;
  bool _hasMore = true;
  
  late String currentUserId;
  late String otherUserId;
  
  final List<MessageModel> _messages = [];
  RealtimeChannel? _subscription;
  Map<String, dynamic>? _otherUserProfile;

  bool _isOtherTyping = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    currentUserId = context.read<AuthProvider>().user!.id;
    otherUserId = widget.conversation.user1Id == currentUserId ? widget.conversation.user2Id : widget.conversation.user1Id;
    
    _loadOtherUserProfile();
    _loadMessages();
    
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _loadMessages();
      }
    });

    _subscription = ChatService.subscribeToChatEvents(
      widget.conversation.id,
      onNewMessage: (newMsg) {
        if (mounted) {
          setState(() {
            final existingIndex = _messages.indexWhere((m) => m.id == newMsg.id || (m.status == 'sending' && m.content == newMsg.content));
            if (existingIndex != -1) {
              _messages[existingIndex] = newMsg;
            } else {
              _messages.insert(0, newMsg);
            }
          });
        }
      },
      onTypingStatus: (String userId, bool isTyping) {
        if (userId == otherUserId && mounted) {
          setState(() {
            _isOtherTyping = isTyping;
          });
        }
      },
    );

    ChatService.markMessagesAsRead(widget.conversation.id, otherUserId);
  }

  void _onTextChanged(String text) {
    if (_typingTimer?.isActive ?? false) _typingTimer!.cancel();
    
    _subscription?.sendBroadcastMessage(event: 'typing', payload: {'user_id': currentUserId, 'is_typing': true});
    
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _subscription?.sendBroadcastMessage(event: 'typing', payload: {'user_id': currentUserId, 'is_typing': false});
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _subscription?.unsubscribe();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadOtherUserProfile() async {
    final profile = await ChatService.getUserProfile(otherUserId);
    if (mounted) {
      setState(() {
        _otherUserProfile = profile;
      });
    }
  }

  Future<void> _loadMessages() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    final newMessages = await ChatService.getMessages(widget.conversation.id, offset: _messages.length, limit: 50);
    
    if (mounted) {
      setState(() {
        if (newMessages.isEmpty) {
          _hasMore = false;
        } else {
          _messages.addAll(newMessages);
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    final pendingMsg = MessageModel(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: widget.conversation.id,
      senderId: currentUserId,
      content: text,
      isRead: false,
      createdAt: DateTime.now(),
      status: 'sending',
    );

    setState(() {
      _messages.insert(0, pendingMsg);
    });

    if (_scrollController.hasClients) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }

    try {
      await ChatService.sendMessage(pendingMsg);
    } catch (e) {
      if (mounted) {
        setState(() {
          final index = _messages.indexWhere((m) => m.id == pendingMsg.id);
          if (index != -1) _messages[index] = pendingMsg.copyWith(status: 'failed');
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _isUploadingImage = true);
      
      final pendingMsg = MessageModel(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: widget.conversation.id,
        senderId: currentUserId,
        content: '📷 Photo',
        isRead: false,
        createdAt: DateTime.now(),
        messageType: 'image',
        status: 'sending',
      );

      setState(() {
        _messages.insert(0, pendingMsg);
      });

      try {
        await ChatService.sendImageMessage(pendingMsg, File(pickedFile.path));
      } catch (e) {
        if (mounted) {
          setState(() {
            final index = _messages.indexWhere((m) => m.id == pendingMsg.id);
            if (index != -1) _messages[index] = pendingMsg.copyWith(status: 'failed');
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send image: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploadingImage = false);
      }
    }
  }

  void _showAttachmentOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const HugeIcon(icon: HugeIcons.strokeRoundedCamera01, color: AppTheme.primary, size: 24),
                title: Text('Camera', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const HugeIcon(icon: HugeIcons.strokeRoundedImage01, color: AppTheme.primary, size: 24),
                title: Text('Gallery', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const HugeIcon(icon: HugeIcons.strokeRoundedFile01, color: AppTheme.primary, size: 24),
                title: Text('File', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'csv'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _isUploadingImage = true);
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;

        final pendingMsg = MessageModel(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          conversationId: widget.conversation.id,
          senderId: currentUserId,
          content: '📎 File',
          isRead: false,
          createdAt: DateTime.now(),
          messageType: 'file',
          fileName: fileName,
          fileSize: file.lengthSync(),
          status: 'sending',
        );

        setState(() {
          _messages.insert(0, pendingMsg);
        });

        try {
          await ChatService.sendFileMessage(pendingMsg, file, fileName);
        } catch (e) {
          if (mounted) {
            setState(() {
              final index = _messages.indexWhere((m) => m.id == pendingMsg.id);
              if (index != -1) _messages[index] = pendingMsg.copyWith(status: 'failed');
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to send file: $e')),
            );
          }
        } finally {
          if (mounted) setState(() => _isUploadingImage = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick file: $e')));
      }
    }
  }

  void _showProfileBrief(BuildContext context, Map<String, dynamic> userData, bool isDark) {
    final name = userData['name'] ?? 'User';
    final email = userData['email'] ?? '';
    final role = userData['role'] ?? 'Unknown';
    final avatarUrl = userData['avatar_url'];
    final userId = userData['id'] as String;
    final avatar = name.isNotEmpty ? name[0].toUpperCase() : '?';

    showDialog(
      context: context,
      builder: (_) => Center(
        child: Material(
          type: MaterialType.transparency,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.6), width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4), width: 2),
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
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primary,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        role.toString().toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      email,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.grey,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    // Stats Section
                    FutureBuilder<List<dynamic>>(
                      future: Future.wait([
                        GigService.getPostedCount(userId),
                        GigService.getCompletedCount(userId),
                        ReviewService.getAverageRating(userId),
                      ]),
                      builder: (context, snapshot) {
                        int posted = 0;
                        int completed = 0;
                        double rating = 0.0;
                        
                        if (snapshot.hasData) {
                          posted = snapshot.data![0] as int;
                          completed = snapshot.data![1] as int;
                          rating = snapshot.data![2] as double;
                        }

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildGlassStat(isDark, 'Posted', '$posted', HugeIcons.strokeRoundedUpload01),
                            _buildGlassStat(isDark, 'Done', '$completed', HugeIcons.strokeRoundedTick01),
                            _buildGlassStat(isDark, 'Rating', rating > 0 ? rating.toStringAsFixed(1) : '-', HugeIcons.strokeRoundedStar),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    GlassContainer(
                      useOwnLayer: true,
                      quality: GlassQuality.standard,
                      shape: LiquidRoundedSuperellipse(borderRadius: 20.0),
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
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                          ),
                          child: const Center(
                            child: Text(
                              'Close',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildGlassStat(bool isDark, String label, String value, dynamic icon) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
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
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.6), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                HugeIcon(icon: icon, size: 22, color: AppTheme.primary),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ─── Main Content ──────────────────────────────────────────
          // ─── Messages ────────────────────────────────────────
          Positioned.fill(
            child: ListView.builder(
              reverse: true,
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 80, 16, 100), // Extra top padding for the top bar, bottom for input
              physics: const BouncingScrollPhysics(),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                final msg = _messages[index];
                
                // Grouping logic: hide avatar if next message (index + 1 because reversed) is from same sender within 1 minute
                bool showAvatar = true;
                if (index < _messages.length - 1) {
                  final nextMsg = _messages[index + 1];
                  if (nextMsg.senderId == msg.senderId) {
                    final timeDiff = msg.createdAt.difference(nextMsg.createdAt).inSeconds.abs();
                    if (timeDiff < 60) {
                      showAvatar = false;
                    }
                  }
                }
                
                return _MessageBubble(
                  message: msg, 
                  isDark: isDark, 
                  isMe: msg.senderId == currentUserId,
                  showAvatar: showAvatar,
                  otherAvatarUrl: _otherUserProfile?['avatar_url'],
                  otherName: _otherUserProfile?['name'],
                  onImageTap: () {
                    if (!msg.isImage) return;
                    final imageMessages = _messages.where((m) => m.isImage).toList();
                    final initialIndex = imageMessages.indexWhere((m) => m.id == msg.id);
                    if (initialIndex != -1) {
                      showDialog(
                        context: context,
                        builder: (_) => _ImageViewerDialog(
                          imageUrls: imageMessages.map((m) => m.imageUrl!).toList(),
                          initialIndex: initialIndex,
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),

          // ─── Input Bar ───────────────────────────────────────
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom > 0
                ? 8
                : MediaQuery.of(context).padding.bottom + 8,
            child: GlassContainer(
              useOwnLayer: true,
              quality: GlassQuality.standard,
              shape: LiquidRoundedSuperellipse(borderRadius: 32.0),
              settings: LiquidGlassSettings(
                thickness: 0.1,
                blur: 2.0,
                refractiveIndex: 1.0,
                glassColor: Colors.transparent,
                lightAngle: 45.0,
                lightIntensity: isDark ? 0.1 : 0.2,
                ambientStrength: 1.0,
                saturation: 1.0,
                chromaticAberration: 0.0,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.4),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _showAttachmentOptions,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedAttachment01,
                          color: Colors.grey.shade500,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onChanged: _onTextChanged,
                        onSubmitted: (_) {
                          _typingTimer?.cancel();
                          _subscription?.sendBroadcastMessage(event: 'typing', payload: {'user_id': currentUserId, 'is_typing': false});
                          _sendMessage();
                        },
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
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        _typingTimer?.cancel();
                        _subscription?.sendBroadcastMessage(event: 'typing', payload: {'user_id': currentUserId, 'is_typing': false});
                        _sendMessage();
                      },
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: _isUploadingImage 
                          ? const SizedBox(
                              width: 18, height: 18, 
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            )
                          : const HugeIcon(
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
          
          // ─── Typing Indicator ──────────────────────────────────
          if (_isOtherTyping)
            Positioned(
              left: 32,
              bottom: (MediaQuery.of(context).viewInsets.bottom > 0 ? 8 : MediaQuery.of(context).padding.bottom + 8) + 60,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white12 : Colors.black12,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_otherUserProfile?['name'] ?? 'User'} is typing...',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
      
      // ─── Custom Glass Floating Top Bar ─────────────────────────────────
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: GlassContainer(
                      useOwnLayer: true,
                      quality: GlassQuality.standard,
                      shape: LiquidRoundedSuperellipse(borderRadius: 30.0),
                      settings: LiquidGlassSettings(
                        thickness: 0.1,
                        blur: 2.0,
                        refractiveIndex: 1.0,
                        glassColor: Colors.transparent,
                        lightAngle: 45.0,
                        lightIntensity: isDark ? 0.1 : 0.2,
                        ambientStrength: 1.0,
                        saturation: 1.0,
                        chromaticAberration: 0.0,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.4), width: 1.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => Navigator.pop(context),
                              child: Padding(
                                padding: const EdgeInsets.only(right: 12.0),
                                child: HugeIcon(
                                  icon: HugeIcons.strokeRoundedArrowLeft01,
                                  color: isDark ? Colors.white : Colors.black87,
                                  size: 22,
                                ),
                              ),
                            ),
                            Expanded(
                              child: FutureBuilder<Map<String, dynamic>>(
                                future: ChatService.getUserProfile(otherUserId),
                                builder: (context, snapshot) {
                                  final name = snapshot.data?['name'] ?? '...';
                                  final avatarUrl = snapshot.data?['avatar_url'];
                                  final avatar = name.isNotEmpty ? name[0] : '?';
                                  final avatarColor = AppTheme.primary;
                                  return GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      if (snapshot.hasData) {
                                        _showProfileBrief(context, snapshot.data!, isDark);
                                      }
                                    },
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: avatarColor.withValues(alpha: 0.15),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: avatarColor.withValues(alpha: 0.4), width: 1.5),
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
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w800,
                                                      color: avatarColor,
                                                    ),
                                                  ),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? Colors.white : Colors.black87,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_otherUserProfile != null) ...(() {
                    final phone = _otherUserProfile!['phone'] ?? _otherUserProfile!['phone_number'];
                    if (phone != null && phone.toString().isNotEmpty) {
                      return <Widget>[
                        const SizedBox(width: 8),
                        GlassContainer(
                          useOwnLayer: true,
                          quality: GlassQuality.standard,
                          shape: LiquidRoundedSuperellipse(borderRadius: 30.0),
                          settings: LiquidGlassSettings(
                            thickness: 0.1,
                            blur: 2.0,
                            refractiveIndex: 1.0,
                            glassColor: Colors.transparent,
                            lightAngle: 45.0,
                            lightIntensity: isDark ? 0.1 : 0.2,
                            ambientStrength: 1.0,
                            saturation: 1.0,
                            chromaticAberration: 0.0,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.4), width: 1.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () async {
                                    final Uri url = Uri.parse('tel:$phone');
                                    try {
                                      if (!await launchUrl(url)) {
                                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch dialer')));
                                      }
                                    } catch (e) {
                                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch dialer')));
                                    }
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6.0),
                                    child: HugeIcon(
                                      icon: HugeIcons.strokeRoundedCall02,
                                      color: AppTheme.primary,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () async {
                                    String cleanPhone = phone.toString().replaceAll(RegExp(r'\D'), '');
                                    if (cleanPhone.startsWith('0')) cleanPhone = '6$cleanPhone';
                                    try {
                                      final Uri appUrl = Uri.parse('whatsapp://send?phone=$cleanPhone');
                                      if (!await launchUrl(appUrl, mode: LaunchMode.externalApplication)) {
                                        final Uri webUrl = Uri.parse('https://wa.me/$cleanPhone');
                                        if (!await launchUrl(webUrl, mode: LaunchMode.externalApplication)) {
                                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch WhatsApp')));
                                        }
                                      }
                                    } catch (e) {
                                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch WhatsApp')));
                                    }
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6.0),
                                    child: HugeIcon(
                                      icon: HugeIcons.strokeRoundedWhatsapp,
                                      color: Color(0xFF25D366),
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ];
                    }
                    return <Widget>[];
                  }()),
                ],
              ),
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
class _MessageBubble extends StatefulWidget {
  final MessageModel message;
  final bool isDark;
  final bool isMe;
  final bool showAvatar;
  final VoidCallback? onImageTap;
  final String? otherAvatarUrl;
  final String? otherName;

  const _MessageBubble({
    super.key,
    required this.message, 
    required this.isDark, 
    required this.isMe,
    this.showAvatar = true,
    this.onImageTap,
    this.otherAvatarUrl,
    this.otherName,
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  bool _isDownloading = false;

  Future<void> _openFile() async {
    final url = widget.message.imageUrl;
    if (url == null || url.isEmpty) return;
    
    setState(() {
      _isDownloading = true;
    });

    try {
      final fileName = widget.message.displayFileName;
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);

      if (!await file.exists()) {
        final httpClient = HttpClient();
        final request = await httpClient.getUrl(Uri.parse(url));
        final response = await request.close();
        final bytes = await consolidateHttpClientResponseBytes(response);
        await file.writeAsBytes(bytes);
      }

      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open file: ${result.message}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final isDark = widget.isDark;
    final isMe = widget.isMe;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && widget.showAvatar) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.primary,
              backgroundImage: widget.otherAvatarUrl != null && widget.otherAvatarUrl!.isNotEmpty ? CachedNetworkImageProvider(widget.otherAvatarUrl!) : null,
              child: widget.otherAvatarUrl == null || widget.otherAvatarUrl!.isEmpty
                  ? Text(
                      widget.otherName != null && widget.otherName!.isNotEmpty 
                          ? widget.otherName![0].toUpperCase() 
                          : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ] else if (!isMe) ...[
            const SizedBox(width: 44),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.primary : (isDark ? const Color(0xFF2C2C2E) : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe || !widget.showAvatar ? 20 : 4),
                  bottomRight: Radius.circular(isMe && widget.showAvatar ? 4 : 20),
                ),
                boxShadow: isMe || isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        )
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.imageUrl != null)
                    message.isFile
                    ? GestureDetector(
                        onTap: _isDownloading ? null : _openFile,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.white.withValues(alpha: 0.2) : (isDark ? Colors.white10 : Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _isDownloading 
                                  ? SizedBox(
                                      width: 24, height: 24, 
                                      child: CircularProgressIndicator(color: isMe ? Colors.white : AppTheme.primary, strokeWidth: 2,)
                                    )
                                  : HugeIcon(
                                      icon: HugeIcons.strokeRoundedFile01, 
                                      color: isMe ? Colors.white : AppTheme.primary, 
                                      size: 24
                                    ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  message.displayFileName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
                                    decoration: TextDecoration.underline,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: GestureDetector(
                          onTap: () {
                            if (widget.onImageTap != null) {
                              widget.onImageTap!();
                            } else {
                              showDialog(
                                context: context,
                                builder: (_) => _ImageViewerDialog(
                                  imageUrls: [message.imageUrl!],
                                  initialIndex: 0,
                                ),
                              );
                            }
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: message.imageUrl!,
                              width: MediaQuery.of(context).size.width * 0.6,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: MediaQuery.of(context).size.width * 0.6,
                                height: 150,
                                color: isDark ? Colors.white10 : Colors.black12,
                                child: const Center(child: CircularProgressIndicator()),
                              ),
                              errorWidget: (context, url, error) => const Icon(Icons.error),
                            ),
                          ),
                        ),
                      )
                  else
                    Text(
                      message.content,
                      style: TextStyle(
                        fontSize: 14,
                        color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
                        height: 1.4,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.formattedTime,
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe ? Colors.white.withValues(alpha: 0.7) : Colors.grey.shade500,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        MessageStatusIndicator(
                          status: message.status,
                          isRead: message.isRead,
                          isMe: isMe,
                          defaultColor: Colors.white.withValues(alpha: 0.7),
                        ),
                      ],
                    ],
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

// ─── Message Status Indicator ──────────────────────────────────
class MessageStatusIndicator extends StatelessWidget {
  final String status;
  final bool isRead;
  final bool isMe;
  final Color defaultColor;

  const MessageStatusIndicator({
    super.key,
    required this.status,
    required this.isRead,
    required this.isMe,
    this.defaultColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    if (!isMe) return const SizedBox.shrink();

    if (status == 'failed') {
      return const Icon(
        Icons.error_outline,
        color: Colors.redAccent,
        size: 14,
      );
    }

    if (status == 'sending') {
      return Icon(
        Icons.access_time,
        color: defaultColor,
        size: 14,
      );
    }

    if (isRead) {
      return const Icon(
        Icons.done_all,
        color: Colors.blueAccent,
        size: 15,
      );
    }

    return Icon(
      Icons.check,
      color: defaultColor,
      size: 15,
    );
  }
}

class _ImageViewerDialog extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _ImageViewerDialog({required this.imageUrls, required this.initialIndex});

  @override
  State<_ImageViewerDialog> createState() => _ImageViewerDialogState();
}

class _ImageViewerDialogState extends State<_ImageViewerDialog> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentIndex < widget.imageUrls.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _prevPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrls[index],
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          if (_currentIndex > 0)
            Positioned(
              left: 10,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white, size: 40),
                    onPressed: _prevPage,
                  ),
                ),
              ),
            ),
          if (_currentIndex < widget.imageUrls.length - 1)
            Positioned(
              right: 10,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white, size: 40),
                    onPressed: _nextPage,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
