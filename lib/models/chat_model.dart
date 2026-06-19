import 'package:intl/intl.dart';
import 'user_model.dart';

class ConversationModel {
  final String id;
  final String user1Id;
  final String user2Id;
  final String? gigId;
  final String? lastMessage;
  final String? lastMessageSenderId;
  final bool lastMessageIsRead;
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
    this.lastMessageSenderId,
    this.lastMessageIsRead = false,
    required this.updatedAt,
    this.otherUser,
    this.unreadCount = 0,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json, String currentUserId) {
    UserModel? otherUserParsed;
    
    // In Supabase, we usually join the users table.
    // The new query uses 'user1' and 'user2' foreign key aliases.
    if (json['user1'] != null && json['user1']['id'] != currentUserId) {
      otherUserParsed = UserModel.fromJson(json['user1']);
    } else if (json['user2'] != null && json['user2']['id'] != currentUserId) {
      otherUserParsed = UserModel.fromJson(json['user2']);
    } else if (json['users'] != null) {
      // Fallback for older format if needed
      if (json['users'] is List) {
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
      lastMessageSenderId: json['last_message_sender_id'],
      lastMessageIsRead: json['last_message_is_read'] ?? false,
      updatedAt: DateTime.parse(json['updated_at']).toLocal(),
      otherUser: otherUserParsed,
      unreadCount: json['unread_count'] ?? 0, 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user1_id': user1Id,
      'user2_id': user2Id,
      'gig_id': gigId,
      'last_message': lastMessage,
      'last_message_sender_id': lastMessageSenderId,
      'last_message_is_read': lastMessageIsRead,
      'updated_at': updatedAt.toIso8601String(),
      'unread_count': unreadCount,
    };
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

  ConversationModel copyWith({
    String? id,
    String? user1Id,
    String? user2Id,
    String? gigId,
    String? lastMessage,
    String? lastMessageSenderId,
    bool? lastMessageIsRead,
    DateTime? updatedAt,
    UserModel? otherUser,
    int? unreadCount,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      user1Id: user1Id ?? this.user1Id,
      user2Id: user2Id ?? this.user2Id,
      gigId: gigId ?? this.gigId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageIsRead: lastMessageIsRead ?? this.lastMessageIsRead,
      updatedAt: updatedAt ?? this.updatedAt,
      otherUser: otherUser ?? this.otherUser,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final String? imageUrl;
  final bool isRead;
  final DateTime createdAt;
  
  // New robust file handling fields
  final String messageType; 
  final String? fileName;
  final int? fileSize;
  
  // Local state field ('sending', 'sent', 'failed')
  final String status;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.imageUrl,
    required this.isRead,
    required this.createdAt,
    this.messageType = 'text',
    this.fileName,
    this.fileSize,
    this.status = 'sent',
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      conversationId: json['conversation_id'],
      senderId: json['sender_id'],
      content: json['content'],
      imageUrl: json['image_url'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      messageType: json['message_type'] ?? 'text',
      fileName: json['file_name'],
      fileSize: json['file_size'],
      status: json['status'] ?? 'sent',
    );
  }

  bool get isFile {
    if (messageType == 'file' || messageType == 'document') return true;
    if (imageUrl != null) {
      if (content == '📎 File' || (fileName != null && fileName!.isNotEmpty)) return true;
      final lowerUrl = imageUrl!.toLowerCase();
      if (lowerUrl.endsWith('.pdf') || lowerUrl.endsWith('.doc') || lowerUrl.endsWith('.docx') || lowerUrl.endsWith('.txt') || lowerUrl.endsWith('.csv')) {
        return true;
      }
    }
    return false;
  }
  
  bool get isImage => messageType == 'image' || (imageUrl != null && !isFile);

  String get displayFileName {
    if (fileName != null && fileName!.isNotEmpty) return fileName!;
    if (imageUrl != null) {
      final uri = Uri.tryParse(imageUrl!);
      if (uri != null && uri.pathSegments.isNotEmpty) {
        final lastSegment = uri.pathSegments.last;
        if (lastSegment.contains('_')) {
          final parts = lastSegment.split('_');
          if (int.tryParse(parts[0]) != null) {
            return parts.sublist(1).join('_');
          }
        }
        return lastSegment;
      }
    }
    return 'File';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      if (imageUrl != null) 'image_url': imageUrl,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'message_type': messageType,
      if (fileName != null) 'file_name': fileName,
      if (fileSize != null) 'file_size': fileSize,
      'status': status,
    };
  }

  Map<String, dynamic> toSupabaseJson() {
    final json = <String, dynamic>{
      if (id.isNotEmpty && !id.startsWith('temp_')) 'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      if (imageUrl != null) 'image_url': imageUrl,
      'is_read': isRead,
    };
    
    // Prevent errors if the Supabase table hasn't been updated with these new columns
    if (messageType != 'text') json['message_type'] = messageType;
    if (fileName != null) json['file_name'] = fileName;
    if (fileSize != null) json['file_size'] = fileSize;
    
    return json;
  }

  String get formattedTime {
    return DateFormat('h:mm a').format(createdAt);
  }

  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? content,
    String? imageUrl,
    bool? isRead,
    DateTime? createdAt,
    String? messageType,
    String? fileName,
    int? fileSize,
    String? status,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      messageType: messageType ?? this.messageType,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      status: status ?? this.status,
    );
  }
}
