import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/chat_model.dart';

class LocalDatabaseService {
  static final LocalDatabaseService instance = LocalDatabaseService._init();
  static Database? _database;

  LocalDatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('chat_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textNullType = 'TEXT';
    const boolType = 'INTEGER NOT NULL'; // SQLite doesn't have a separate Boolean storage class.
    const integerType = 'INTEGER NOT NULL';
    const integerNullType = 'INTEGER';

    await db.execute('''
CREATE TABLE messages (
  id $idType,
  conversation_id $textType,
  sender_id $textType,
  content $textType,
  image_url $textNullType,
  is_read $boolType,
  created_at $textType,
  message_type $textType,
  file_name $textNullType,
  file_size $integerNullType,
  status $textType
)
''');

    await db.execute('''
CREATE TABLE conversations (
  id $idType,
  user1_id $textType,
  user2_id $textType,
  gig_id $textNullType,
  last_message $textNullType,
  last_message_sender_id $textNullType,
  last_message_is_read $boolType,
  updated_at $textType,
  unread_count $integerType
)
''');
  }

  // Messages Operations
  Future<void> insertMessage(MessageModel message) async {
    final db = await instance.database;
    final json = message.toJson();
    json['is_read'] = message.isRead ? 1 : 0;
    
    await db.insert(
      'messages',
      json,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertMessages(List<MessageModel> messages) async {
    final db = await instance.database;
    final batch = db.batch();
    for (var message in messages) {
      final json = message.toJson();
      json['is_read'] = message.isRead ? 1 : 0;
      batch.insert('messages', json, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<MessageModel>> getMessages(String conversationId, {int limit = 50, int offset = 0}) async {
    final db = await instance.database;
    final maps = await db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    if (maps.isNotEmpty) {
      return maps.map((json) {
        final mutableJson = Map<String, dynamic>.from(json);
        mutableJson['is_read'] = mutableJson['is_read'] == 1;
        return MessageModel.fromJson(mutableJson);
      }).toList();
    } else {
      return [];
    }
  }

  Future<void> updateMessageStatus(String id, String status) async {
    final db = await instance.database;
    await db.update(
      'messages',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteMessage(String id) async {
    final db = await instance.database;
    await db.delete(
      'messages',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Conversations Operations
  Future<void> insertConversation(ConversationModel conversation) async {
    final db = await instance.database;
    final json = conversation.toJson();
    json['last_message_is_read'] = conversation.lastMessageIsRead ? 1 : 0;
    await db.insert('conversations', json, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertConversations(List<ConversationModel> conversations) async {
    final db = await instance.database;
    final batch = db.batch();
    for (var conv in conversations) {
      final json = conv.toJson();
      json['last_message_is_read'] = conv.lastMessageIsRead ? 1 : 0;
      batch.insert('conversations', json, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<ConversationModel>> getConversations() async {
    final db = await instance.database;
    final maps = await db.query(
      'conversations',
      orderBy: 'updated_at DESC',
    );

    if (maps.isNotEmpty) {
      return maps.map((json) {
        final mutableJson = Map<String, dynamic>.from(json);
        mutableJson['last_message_is_read'] = mutableJson['last_message_is_read'] == 1;
        return ConversationModel.fromJson(mutableJson, ''); 
      }).toList();
    } else {
      return [];
    }
  }
}
