import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_model.dart';

class ChatService {
  static final _supabase = Supabase.instance.client;

  /// Fetch all conversations for the current user
  static Stream<List<ConversationModel>> getConversationsStream(String currentUserId) {
    return _supabase
        .from('conversations')
        .stream(primaryKey: ['id'])
        // Supabase stream filters only work on a single equality check or we can filter in memory.
        // It's safer to fetch the stream and filter in map if the user is user1 or user2
        .map((maps) {
          final filtered = maps.where((m) => m['user1_id'] == currentUserId || m['user2_id'] == currentUserId).toList();
          filtered.sort((a, b) {
            final aTime = DateTime.tryParse(a['updated_at'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = DateTime.tryParse(b['updated_at'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });
          
          return filtered.map((e) => ConversationModel.fromJson(e, currentUserId)).toList();
        });
  }

  /// Get messages for a specific conversation
  static Stream<List<MessageModel>> getMessagesStream(String conversationId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((maps) => maps.map((e) => MessageModel.fromJson(e)).toList());
  }

  /// Create or get a conversation between two users
  static Future<ConversationModel> createOrGetConversation(String currentUserId, String otherUserId, {String? gigId}) async {
    if (currentUserId == otherUserId) {
      throw Exception('You cannot chat with yourself.');
    }

    // Check if conversation exists
    final existing = await _supabase
        .from('conversations')
        .select()
        .or('and(user1_id.eq.$currentUserId,user2_id.eq.$otherUserId),and(user1_id.eq.$otherUserId,user2_id.eq.$currentUserId)')
        .maybeSingle();

    if (existing != null) {
      return ConversationModel.fromJson(existing, currentUserId);
    }

    // Create new
    final response = await _supabase.from('conversations').insert({
      'user1_id': currentUserId,
      'user2_id': otherUserId,
      'gig_id': gigId,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).select().single();

    return ConversationModel.fromJson(response, currentUserId);
  }

  /// Send a message
  static Future<void> sendMessage(String conversationId, String senderId, String content) async {
    final now = DateTime.now().toUtc().toIso8601String();
    
    // 1. Insert message
    await _supabase.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'created_at': now,
    });

    // 2. Update conversation last_message, sender, and updated_at
    await _supabase.from('conversations').update({
      'last_message': content,
      'last_message_sender_id': senderId,
      'last_message_is_read': false,
      'updated_at': now,
    }).eq('id', conversationId);
  }

  /// Upload image and send an image message
  static Future<void> sendImageMessage(String conversationId, String senderId, File imageFile) async {
    final now = DateTime.now().toUtc().toIso8601String();
    
    // 1. Upload image to Storage bucket 'chat_images'
    final fileExt = imageFile.path.split('.').last;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_$senderId.$fileExt';
    final filePath = '$conversationId/$fileName';
    
    await _supabase.storage.from('chat_images').upload(filePath, imageFile);
    final imageUrl = _supabase.storage.from('chat_images').getPublicUrl(filePath);

    // 2. Insert message
    await _supabase.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': '📷 Photo',
      'image_url': imageUrl,
      'created_at': now,
    });

    // 3. Update conversation last_message
    await _supabase.from('conversations').update({
      'last_message': '📷 Photo',
      'last_message_sender_id': senderId,
      'last_message_is_read': false,
      'updated_at': now,
    }).eq('id', conversationId);
  }

  /// Mark all messages in a conversation as read (sent by the other user)
  static Future<void> markMessagesAsRead(String conversationId, String otherUserId) async {
    // 1. Update messages table
    await _supabase.from('messages')
        .update({'is_read': true})
        .eq('conversation_id', conversationId)
        .eq('sender_id', otherUserId)
        .eq('is_read', false);

    // 2. Update conversation table if the last message was from the other user
    // We can just update it safely if the last message sender was otherUserId
    await _supabase.from('conversations')
        .update({'last_message_is_read': true})
        .eq('id', conversationId)
        .eq('last_message_sender_id', otherUserId);
  }
  
  /// Fetch user profile helper
  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    return await _supabase.from('users').select().eq('id', userId).single();
  }

  /// Delete a conversation and all its messages and images
  static Future<void> deleteConversation(String conversationId) async {
    // 1. Delete all images from Supabase Storage
    try {
      final files = await _supabase.storage.from('chat_images').list(path: conversationId);
      if (files.isNotEmpty) {
        final filePaths = files.map((f) => '$conversationId/${f.name}').toList();
        await _supabase.storage.from('chat_images').remove(filePaths);
      }
    } catch (e) {
      // Safely ignore if the folder is already empty or doesn't exist
    }

    // 2. Delete messages from database
    await _supabase.from('messages').delete().eq('conversation_id', conversationId);
    
    // 3. Delete conversation record
    await _supabase.from('conversations').delete().eq('id', conversationId);
  }
}
