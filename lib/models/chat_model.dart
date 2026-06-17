import 'package:intl/intl.dart';
import 'user_model.dart';

class ConversationModel {
  final String id;
  final String user1Id;
  final String user2Id;
  final String? gigId;
  final String? lastMessage;
  final DateTime updatedAt;

  // Joined user details (e.g. the other person in the chat)
  final UserModel? otherUser;
  final int unreadCount;

  ConversationModel({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    this.gigId,
    this.lastMessage,
    required this.updatedAt,
    this.otherUser,
    this.unreadCount = 0,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json, String currentUserId) {
    UserModel? otherUserParsed;
    
    // In Supabase, we usually join the users table. It might come back as an array or object.
    if (json['users'] != null) {
      if (json['users'] is List) {
        // If joined with both users
        for (var u in json['users']) {
          if (u['id'] != currentUserId) {
            otherUserParsed = UserModel.fromJson(u);
            break;
          }
        }
      } else if (json['users'] is Map) {
        otherUserParsed = UserModel.fromJson(json['users']);
      }
    }

    return ConversationModel(
      id: json['id'],
      user1Id: json['user1_id'],
      user2Id: json['user2_id'],
      gigId: json['gig_id'],
      lastMessage: json['last_message'],
      updatedAt: DateTime.parse(json['updated_at']).toLocal(),
      otherUser: otherUserParsed,
      // For a real app, unreadCount needs a separate query or counter, but we'll default to 0
      unreadCount: json['unread_count'] ?? 0, 
    );
  }

  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(updatedAt);

    if (difference.inDays == 0) {
      return DateFormat('h:mm a').format(updatedAt);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(updatedAt); // e.g., Monday
    } else {
      return DateFormat('MMM d').format(updatedAt); // e.g., Oct 12
    }
  }
}

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      conversationId: json['conversation_id'],
      senderId: json['sender_id'],
      content: json['content'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'is_read': isRead,
    };
  }

  String get formattedTime {
    return DateFormat('h:mm a').format(createdAt);
  }
}
