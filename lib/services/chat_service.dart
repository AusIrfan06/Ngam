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
          
          // Note: Realtime streams don't support complex joins out of the box in the `stream()` method.
          // To get the user profiles, you'd typically need to fetch them separately or use a database function.
          // For simplicity in UI, we will rely on mapping it here and let the UI handle profile fetching,
          // OR we can fetch profiles asynchronously.
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

    // 2. Update conversation last_message and updated_at
    await _supabase.from('conversations').update({
      'last_message': content,
      'updated_at': now,
    }).eq('id', conversationId);
  }
  
  /// Fetch user profile helper
  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    return await _supabase.from('users').select().eq('id', userId).single();
  }
}
