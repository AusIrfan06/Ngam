import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import 'local_database_service.dart';

class ChatService {
  static final _supabase = Supabase.instance.client;
  static final Map<String, UserModel> _userCache = {};

  /// Caches and fetches User Profiles to solve the N+1 query problem
  static Future<UserModel?> getCachedUser(String userId) async {
    if (_userCache.containsKey(userId)) return _userCache[userId];
    try {
      final data = await _supabase.from('users').select().eq('id', userId).single();
      final user = UserModel.fromJson(data);
      _userCache[userId] = user;
      return user;
    } catch (e) {
      return null;
    }
  }
  static final Map<String, Map<String, dynamic>> _gigCache = {};
  
  static Map<String, dynamic>? getCachedGigSync(String gigId) => _gigCache[gigId];

  static Future<Map<String, dynamic>?> getCachedGig(String gigId) async {
    if (_gigCache.containsKey(gigId)) return _gigCache[gigId];
    try {
      final data = await _supabase.from('gigs').select('customer_id, gig_worker_id, title, status').eq('id', gigId).maybeSingle();
      if (data != null) {
        _gigCache[gigId] = data;
      }
      return data;
    } catch (e) {
      return null;
    }
  }

  /// Fetch all conversations for the current user
  static Stream<List<ConversationModel>> getConversationsStream(String currentUserId, {required bool isRunner}) async* {
    final localDb = LocalDatabaseService.instance;

    // Yield local data instantly
    final localConversations = await localDb.getConversations();
    if (localConversations.isNotEmpty) {
      // For local conversations, populate with cached users
      List<ConversationModel> populatedLocal = [];
      for (var conv in localConversations) {
        if (conv.gigId != null) {
           final gigData = _gigCache[conv.gigId!];
           if (gigData != null) {
             final isCustomerInGig = gigData['customer_id'] == currentUserId;
             if (isRunner && isCustomerInGig) continue;
             if (!isRunner && !isCustomerInGig) continue;
           } else {
             // Skip if we don't have gig cache to avoid flickering wrong role chats
             continue;
           }
        }

        final otherId = conv.user1Id == currentUserId ? conv.user2Id : conv.user1Id;
        final otherUser = _userCache[otherId];
        populatedLocal.add(conv.copyWith(otherUser: otherUser));
      }
      yield populatedLocal;
    }

    // Stream network data
    yield* _supabase
        .from('conversations')
        .stream(primaryKey: ['id'])
        .asyncMap((maps) async {
          final filtered = maps.where((m) => m['user1_id'] == currentUserId || m['user2_id'] == currentUserId).toList();
          filtered.sort((a, b) {
            final aTime = DateTime.tryParse(a['updated_at'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = DateTime.tryParse(b['updated_at'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });
          
          List<ConversationModel> conversations = [];
          for (var e in filtered) {
             final conv = ConversationModel.fromJson(e, currentUserId);

             if (conv.gigId != null) {
               final gigData = await getCachedGig(conv.gigId!);
               if (gigData != null) {
                 final isCustomerInGig = gigData['customer_id'] == currentUserId;
                 if (isRunner && isCustomerInGig) continue;
                 if (!isRunner && !isCustomerInGig) continue;
               }
             }

             final otherId = conv.user1Id == currentUserId ? conv.user2Id : conv.user1Id;
             final otherUser = await getCachedUser(otherId);
             conversations.add(conv.copyWith(otherUser: otherUser));
          }
          
          // Cache to SQLite
          await localDb.insertConversations(conversations);
          return conversations;
        });
  }

  /// Get paginated historical messages
  static Future<List<MessageModel>> getMessages(String conversationId, {int limit = 50, int offset = 0}) async {
    final localDb = LocalDatabaseService.instance;
    try {
      final response = await _supabase
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
          
      final networkMessages = response.map((e) => MessageModel.fromJson(e)).toList();
      await localDb.insertMessages(networkMessages);
      return networkMessages;
    } catch (e) {
      // Fallback to offline cache
      return await localDb.getMessages(conversationId, limit: limit, offset: offset);
    }
  }

  /// Subscribe to new messages and typing events via Supabase Realtime
  static RealtimeChannel subscribeToChatEvents(
    String conversationId, {
    required void Function(MessageModel) onNewMessage,
    required void Function(String userId, bool isTyping) onTypingStatus,
  }) {
    return _supabase.channel('public:chat:$conversationId')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'conversation_id',
          value: conversationId,
        ),
        callback: (payload) {
          final newMsg = MessageModel.fromJson(payload.newRecord);
          LocalDatabaseService.instance.insertMessage(newMsg);
          onNewMessage(newMsg);
        },
      )
      .onBroadcast(
        event: 'typing',
        callback: (payload) {
          final userId = payload['user_id'] as String?;
          final isTyping = payload['is_typing'] as bool? ?? false;
          if (userId != null) onTypingStatus(userId, isTyping);
        },
      )
      .subscribe();
  }

  // --- Presence ---
  static RealtimeChannel? _presenceChannel;
  static final ValueNotifier<Set<String>> onlineUsers = ValueNotifier({});

  /// Joins the global presence channel to mark the current user as online.
  static void trackPresence(String userId) {
    if (_presenceChannel != null) return; // Already tracking
    
    _presenceChannel = _supabase.channel('online_presence');
    _presenceChannel!
      .onPresenceSync((payload) {
        final state = _presenceChannel!.presenceState();
        final Set<String> onlineUserIds = {};
        for (dynamic presenceState in state) {
          final presences = presenceState.presences;
          if (presences != null) {
            for (dynamic p in presences) {
              if (p.payload != null && p.payload['user_id'] != null) {
                onlineUserIds.add(p.payload['user_id'] as String);
              }
            }
          }
        }
        onlineUsers.value = onlineUserIds;
      })
      .subscribe((status, [error]) async {
        if (status == RealtimeSubscribeStatus.subscribed) {
          await _presenceChannel!.track({'user_id': userId});
        }
      });
  }

  static void stopTrackingPresence() {
    _presenceChannel?.unsubscribe();
    _presenceChannel = null;
    onlineUsers.value = {};
  }

  /// Create or get a conversation between two users
  static Future<ConversationModel> createOrGetConversation(String currentUserId, String otherUserId, {String? gigId}) async {
    if (currentUserId == otherUserId) {
      throw Exception('You cannot chat with yourself.');
    }

    final existing = await _supabase
        .from('conversations')
        .select()
        .or('and(user1_id.eq.$currentUserId,user2_id.eq.$otherUserId),and(user1_id.eq.$otherUserId,user2_id.eq.$currentUserId)')
        .maybeSingle();

    if (existing != null) {
      return ConversationModel.fromJson(existing, currentUserId);
    }

    final response = await _supabase.from('conversations').insert({
      'user1_id': currentUserId,
      'user2_id': otherUserId,
      'gig_id': gigId,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).select().single();

    return ConversationModel.fromJson(response, currentUserId);
  }

  /// Send a message
  static Future<void> sendMessage(MessageModel message, {String? contextGigId}) async {
    try {
      // 1. Insert message
      await _supabase.from('messages').insert(message.toSupabaseJson());

      // 2. Update conversation
      if (contextGigId != null) {
        await _supabase.rpc('update_conversation_task_message', params: {
          'p_conversation_id': message.conversationId,
          'p_sender_id': message.senderId,
          'p_message_content': message.content,
          'p_gig_id': contextGigId,
        });
      } else {
        await _supabase.from('conversations').update({
          'last_message': message.content,
          'last_message_sender_id': message.senderId,
          'last_message_is_read': false,
          'updated_at': message.createdAt.toUtc().toIso8601String(),
        }).eq('id', message.conversationId);
      }
      
      // Update local status
      final sentMsg = message.copyWith(status: 'sent');
      await LocalDatabaseService.instance.insertMessage(sentMsg);
    } catch (e) {
      final failedMsg = message.copyWith(status: 'failed');
      await LocalDatabaseService.instance.insertMessage(failedMsg);
      rethrow;
    }
  }

  /// Upload image and send an image message
  static Future<void> sendImageMessage(MessageModel pendingMessage, File imageFile, {String? contextGigId}) async {
    try {
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${pendingMessage.senderId}.$fileExt';
      final filePath = '${pendingMessage.conversationId}/$fileName';
      
      await _supabase.storage.from('chat_images').upload(filePath, imageFile);
      final imageUrl = _supabase.storage.from('chat_images').getPublicUrl(filePath);

      final newMsg = pendingMessage.copyWith(
        imageUrl: imageUrl, 
        fileName: fileName,
        fileSize: imageFile.lengthSync(),
      );

      await _supabase.from('messages').insert(newMsg.toSupabaseJson());

      if (contextGigId != null) {
        await _supabase.rpc('update_conversation_task_message', params: {
          'p_conversation_id': pendingMessage.conversationId,
          'p_sender_id': pendingMessage.senderId,
          'p_message_content': '📷 Photo',
          'p_gig_id': contextGigId,
        });
      } else {
        await _supabase.from('conversations').update({
          'last_message': '📷 Photo',
          'last_message_sender_id': pendingMessage.senderId,
          'last_message_is_read': false,
          'updated_at': newMsg.createdAt.toUtc().toIso8601String(),
        }).eq('id', pendingMessage.conversationId);
      }
      
      await LocalDatabaseService.instance.insertMessage(newMsg.copyWith(status: 'sent'));
    } catch (e) {
      await LocalDatabaseService.instance.insertMessage(pendingMessage.copyWith(status: 'failed'));
      rethrow;
    }
  }

  /// Upload file and send a file message
  static Future<void> sendFileMessage(MessageModel pendingMessage, File file, String fileName, {String? contextGigId}) async {
    try {
      final filePath = '${pendingMessage.conversationId}/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      
      await _supabase.storage.from('chat_images').upload(filePath, file);
      final fileUrl = _supabase.storage.from('chat_images').getPublicUrl(filePath);

      final newMsg = pendingMessage.copyWith(
        imageUrl: fileUrl,
        fileName: fileName,
        fileSize: file.lengthSync(),
      );

      await _supabase.from('messages').insert(newMsg.toSupabaseJson());

      if (contextGigId != null) {
        await _supabase.rpc('update_conversation_task_message', params: {
          'p_conversation_id': pendingMessage.conversationId,
          'p_sender_id': pendingMessage.senderId,
          'p_message_content': '📎 File',
          'p_gig_id': contextGigId,
        });
      } else {
        await _supabase.from('conversations').update({
          'last_message': '📎 File',
          'last_message_sender_id': pendingMessage.senderId,
          'last_message_is_read': false,
          'updated_at': newMsg.createdAt.toUtc().toIso8601String(),
        }).eq('id', pendingMessage.conversationId);
      }
      
      await LocalDatabaseService.instance.insertMessage(newMsg.copyWith(status: 'sent'));
    } catch (e) {
      await LocalDatabaseService.instance.insertMessage(pendingMessage.copyWith(status: 'failed'));
      rethrow;
    }
  }

  /// Mark all messages in a conversation as read (sent by the other user)
  static Future<void> markMessagesAsRead(String conversationId, String otherUserId) async {
    await _supabase.from('messages')
        .update({'is_read': true})
        .eq('conversation_id', conversationId)
        .eq('sender_id', otherUserId)
        .eq('is_read', false);

    await _supabase.from('conversations')
        .update({
          'last_message_is_read': true,
          'task_unread_counts': {},
        })
        .eq('id', conversationId)
        .eq('last_message_sender_id', otherUserId);
  }
  
  /// Fetch user profile helper
  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    return await _supabase.from('users').select().eq('id', userId).single();
  }

  /// Delete a conversation and all its messages and images
  static Future<void> deleteConversation(String conversationId) async {
    try {
      final files = await _supabase.storage.from('chat_images').list(path: conversationId);
      if (files.isNotEmpty) {
        final filePaths = files.map((f) => '$conversationId/${f.name}').toList();
        await _supabase.storage.from('chat_images').remove(filePaths);
      }
    } catch (e) {
      // Safely ignore if the folder is already empty or doesn't exist
    }

    await _supabase.from('messages').delete().eq('conversation_id', conversationId);
    await _supabase.from('conversations').delete().eq('id', conversationId);
  }
}
