class ConversationThread {
  final String id;
  final String title;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastMessageAt;

  const ConversationThread({
    required this.id,
    required this.title,
    this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessageAt,
  });

  factory ConversationThread.fromJson(Map<String, dynamic> j) =>
      ConversationThread(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String?,
        isActive: j['is_active'] as bool? ?? true,
        createdAt: DateTime.parse(j['created_at'] as String),
        updatedAt: DateTime.parse(j['updated_at'] as String),
        lastMessageAt: j['last_message_at'] != null
            ? DateTime.parse(j['last_message_at'] as String)
            : null,
      );
}

class ChatMessage {
  final String id;
  final String role;
  final String content;
  final String? documentId;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.documentId,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'] as String,
        role: j['role'] as String,
        content: j['content'] as String,
        documentId: j['document_id'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class ChatDocument {
  final String id;
  final String filename;
  final String originalFilename;
  final String fileType;
  final int fileSize;
  final int? pageCount;
  final bool isProcessed;
  final String? extractedText;
  final DateTime createdAt;

  const ChatDocument({
    required this.id,
    required this.filename,
    required this.originalFilename,
    required this.fileType,
    required this.fileSize,
    this.pageCount,
    required this.isProcessed,
    this.extractedText,
    required this.createdAt,
  });

  factory ChatDocument.fromJson(Map<String, dynamic> j) => ChatDocument(
        id: j['id'] as String,
        filename: j['filename'] as String,
        originalFilename: j['original_filename'] as String,
        fileType: j['file_type'] as String,
        fileSize: j['file_size'] as int,
        pageCount: j['page_count'] as int?,
        isProcessed: j['is_processed'] as bool? ?? false,
        extractedText: j['extracted_text'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class ConversationDetail {
  final String id;
  final String title;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastMessageAt;
  final List<ChatMessage> messages;
  final List<ChatDocument> documents;

  const ConversationDetail({
    required this.id,
    required this.title,
    this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessageAt,
    required this.messages,
    required this.documents,
  });

  factory ConversationDetail.fromJson(Map<String, dynamic> j) =>
      ConversationDetail(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String?,
        isActive: j['is_active'] as bool? ?? true,
        createdAt: DateTime.parse(j['created_at'] as String),
        updatedAt: DateTime.parse(j['updated_at'] as String),
        lastMessageAt: j['last_message_at'] != null
            ? DateTime.parse(j['last_message_at'] as String)
            : null,
        messages: (j['messages'] as List<dynamic>? ?? [])
            .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
            .toList(),
        documents: (j['documents'] as List<dynamic>? ?? [])
            .map((d) => ChatDocument.fromJson(d as Map<String, dynamic>))
            .toList(),
      );
}
