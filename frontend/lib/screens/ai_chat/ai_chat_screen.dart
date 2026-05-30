import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafa_edu/config/theme.dart';
import 'package:nafa_edu/core/api/api_client.dart';
import 'package:nafa_edu/core/api/api_endpoints.dart';
import 'package:nafa_edu/models/document_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Data models ────────────────────────────────────────────────────────────────

class _Message {
  final String role;
  final String text;
  final bool isError;

  _Message({required this.role, required this.text, this.isError = false});

  Map<String, dynamic> toJson() => {'role': role, 'text': text, 'isError': isError};
  factory _Message.fromJson(Map<String, dynamic> j) => _Message(
        role: j['role'] as String,
        text: j['text'] as String,
        isError: j['isError'] as bool? ?? false,
      );
}

class _ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final List<_Message> messages;

  _ChatSession({required this.id, required this.title, required this.createdAt, required this.messages});

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  factory _ChatSession.fromJson(Map<String, dynamic> j) => _ChatSession(
        id: j['id'] as String,
        title: j['title'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        messages: (j['messages'] as List).map((m) => _Message.fromJson(m as Map<String, dynamic>)).toList(),
      );
}

// ── Attached document state ────────────────────────────────────────────────────

class _AttachedDoc {
  final String filename;
  final String extractedText;
  final bool isImage;
  final int pageCount;

  const _AttachedDoc({
    required this.filename,
    required this.extractedText,
    required this.isImage,
    required this.pageCount,
  });
}

// ── Screen ─────────────────────────────────────────────────────────────────────

class AiChatScreen extends StatefulWidget {
  final String? initialMessage;
  final DocumentModel? attachedDocument;

  const AiChatScreen({super.key, this.initialMessage, this.attachedDocument});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  final List<_Message> _messages = [];
  bool _isLoading = false;
  bool _isStreaming = false; // true once first token arrives
  bool _isUploading = false;
  bool _autoSentInitial = false;
  String _sessionId = '';
  _AttachedDoc? _attachedDoc;

  static const _maxSessions = 20;
  static const _sessionsKey = 'ai_chat_session_ids';
  static const _suggestions = [
    "Explique-moi le théorème de Thalès",
    "Comment préparer le BAC Série D ?",
    "Qu'est-ce que la photosynthèse ?",
    "Résume la Révolution française",
    "Aide-moi avec les équations du 2nd degré",
    "Quelles sont les règles d'accord du participe passé ?",
  ];

  @override
  void initState() {
    super.initState();
    _newSession(addGreeting: true);

    if (widget.attachedDocument != null) {
      _initWithDocument(widget.attachedDocument!);
    } else {
      _loadLastSession();
      if (widget.initialMessage != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _controller.text = widget.initialMessage!;
          _send();
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Document from card ────────────────────────────────────────────────────────

  Future<void> _initWithDocument(DocumentModel doc) async {
    // Attach the document shell immediately, but do not use metadata as AI context.
    _attachedDoc = _AttachedDoc(
      filename: doc.title,
      extractedText: '',
      isImage: doc.isImage,
      pageCount: 1,
    );

    _isUploading = true;
    var loadedContent = false;

    try {
      final res = await ApiClient.instance.dio.post(
        ApiEndpoints.aiAnalyzeDocument,
        data: {'document_id': doc.id},
      );
      if (!mounted) return;

      final data = res.data as Map<String, dynamic>;
      setState(() {
        _attachedDoc = _AttachedDoc(
          filename: data['filename'] as String? ?? doc.title,
          extractedText: data['text'] as String? ?? '',
          isImage: data['is_image'] as bool? ?? false,
          pageCount: data['page_count'] as int? ?? 1,
        );
        _isUploading = false;
      });
      loadedContent = (_attachedDoc?.extractedText.trim().isNotEmpty ?? false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _messages.add(_Message(
          role: 'ai',
          text: "Je n'ai pas pu lire le contenu du fichier. Réessaie après avoir vérifié que le fichier est bien disponible.",
          isError: true,
        ));
      });
    }

    if (mounted && loadedContent) _triggerInitialSend(doc);
  }

  void _triggerInitialSend(DocumentModel doc) {
    if (_autoSentInitial) return;
    _autoSentInitial = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final parts = <String>[
        if (doc.matiereName != null) doc.matiereName!,
        if (doc.typeExamenName != null) doc.typeExamenName!,
        if (doc.classeName != null) doc.classeName!,
        if (doc.annee != null) '${doc.annee}',
      ];
      final subjectLine = parts.isNotEmpty ? parts.join(' · ') : doc.title;
      _controller.text = "Aide-moi à analyser ce sujet : $subjectLine";
      _send();
    });
  }

  // ── Session management ────────────────────────────────────────────────────────

  void _newSession({bool addGreeting = false}) {
    _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _messages.clear();
    if (addGreeting) {
      _messages.add(_Message(
        role: 'ai',
        text: "Bonjour ! 👋 Je suis ton assistant IA Nafa Edu.\nPose-moi une question sur tes cours, demande une explication ou prépare ton examen. Tu peux aussi m'envoyer un document PDF 📎 pour que je t'aide à l'analyser !",
      ));
    }
  }

  Future<void> _loadLastSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_sessionsKey) ?? [];
      if (ids.isEmpty) return;
      final json = prefs.getString('ai_session_${ids.last}');
      if (json == null) return;
      final session = _ChatSession.fromJson(jsonDecode(json) as Map<String, dynamic>);
      if (!mounted) return;
      setState(() {
        _sessionId = session.id;
        _messages.clear();
        _messages.addAll(session.messages);
      });
    } catch (_) {}
  }

  Future<void> _saveCurrentSession() async {
    final userMessages = _messages.where((m) => m.role == 'user').toList();
    if (userMessages.isEmpty) return;
    try {
      final title = userMessages.first.text.length > 50
          ? '${userMessages.first.text.substring(0, 50)}…'
          : userMessages.first.text;
      final session = _ChatSession(id: _sessionId, title: title, createdAt: DateTime.now(), messages: List.from(_messages));
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_sessionsKey) ?? [];
      if (!ids.contains(_sessionId)) ids.add(_sessionId);
      if (ids.length > _maxSessions) {
        final removed = ids.removeAt(0);
        await prefs.remove('ai_session_$removed');
      }
      await prefs.setStringList(_sessionsKey, ids);
      await prefs.setString('ai_session_$_sessionId', jsonEncode(session.toJson()));
    } catch (_) {}
  }

  Future<List<_ChatSession>> _loadAllSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_sessionsKey) ?? [];
      final sessions = <_ChatSession>[];
      for (final id in ids.reversed) {
        final json = prefs.getString('ai_session_$id');
        if (json != null) {
          try { sessions.add(_ChatSession.fromJson(jsonDecode(json) as Map<String, dynamic>)); } catch (_) {}
        }
      }
      return sessions;
    } catch (_) { return []; }
  }

  Future<void> _deleteSession(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_sessionsKey) ?? [];
      ids.remove(id);
      await prefs.setStringList(_sessionsKey, ids);
      await prefs.remove('ai_session_$id');
    } catch (_) {}
  }

  // ── File upload ────────────────────────────────────────────────────────────────

  Future<void> _pickAndUploadFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    setState(() => _isUploading = true);

    try {
      final bytes = file.bytes;
      final path = file.path;
      MultipartFile mf;
      if (bytes != null) {
        mf = MultipartFile.fromBytes(bytes, filename: file.name);
      } else if (path != null) {
        mf = await MultipartFile.fromFile(path, filename: file.name);
      } else {
        setState(() => _isUploading = false);
        return;
      }

      final res = await ApiClient.instance.dio.post(
        ApiEndpoints.aiUploadDocument,
        data: FormData.fromMap({'file': mf}),
        options: Options(contentType: 'multipart/form-data'),
      );

      final data = res.data as Map<String, dynamic>;
      setState(() {
        _attachedDoc = _AttachedDoc(
          filename: data['filename'] as String? ?? file.name,
          extractedText: data['text'] as String? ?? '',
          isImage: data['is_image'] as bool? ?? false,
          pageCount: data['page_count'] as int? ?? 1,
        );
        _isUploading = false;
      });
    } catch (e) {
      setState(() => _isUploading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Erreur lors du chargement du fichier'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // ── Chat logic ────────────────────────────────────────────────────────────────

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (animated) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    _controller.clear();
    final docContext = _attachedDoc?.extractedText;

    setState(() {
      _messages.add(_Message(role: 'user', text: text));
      _isLoading = true;
      _isStreaming = false;
    });
    _scrollToBottom();

    // History to send: only messages up to and including the user turn just added
    final history = _messages
        .map((m) => {'role': m.role == 'ai' ? 'assistant' : 'user', 'content': m.text})
        .toList();

    String accumulated = '';
    final lineBuffer = StringBuffer();

    try {
      final response = await ApiClient.instance.dio.post(
        ApiEndpoints.aiChatStream,
        data: {
          'messages': history,
          if (docContext != null && docContext.isNotEmpty) 'document_context': docContext,
        },
        options: Options(responseType: ResponseType.stream),
      );

      final stream = (response.data as ResponseBody).stream;

      await for (final bytes in stream) {
        if (!mounted) return;
        lineBuffer.write(utf8.decode(bytes, allowMalformed: true));

        // Process all complete lines in the buffer
        while (true) {
          final buf = lineBuffer.toString();
          final nlIdx = buf.indexOf('\n');
          if (nlIdx == -1) break;
          final line = buf.substring(0, nlIdx).trimRight();
          lineBuffer.clear();
          lineBuffer.write(buf.substring(nlIdx + 1));

          if (!line.startsWith('data: ')) continue;
          final data = line.substring(6);

          if (data == '[DONE]') {
            setState(() { _isLoading = false; _isStreaming = false; });
            _saveCurrentSession();
            return;
          }

          try {
            final parsed = jsonDecode(data) as Map<String, dynamic>;
            final delta = parsed['delta'] as String?;
            final error = parsed['error'] as String?;

            if (delta != null) {
              accumulated += delta;
              setState(() {
                if (!_isStreaming) {
                  _isStreaming = true;
                  _messages.add(_Message(role: 'ai', text: accumulated));
                } else {
                  _messages[_messages.length - 1] = _Message(role: 'ai', text: accumulated);
                }
              });
              _scrollToBottom(animated: false);
            } else if (error != null) {
              setState(() {
                _isLoading = false;
                _isStreaming = false;
                _messages.add(_Message(role: 'ai', text: "Erreur : $error", isError: true));
              });
              return;
            }
          } catch (_) {}
        }
      }

      setState(() { _isLoading = false; _isStreaming = false; });
      _saveCurrentSession();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isStreaming = false;
        _messages.add(_Message(
          role: 'ai',
          text: "Je rencontre un problème de connexion. Vérifie ta connexion internet et réessaie. 🔌",
          isError: true,
        ));
      });
    }
    _scrollToBottom();
  }

  void _useSuggestion(String s) {
    _controller.text = s;
    _send();
  }

  Future<void> _startNewConversation() async {
    await _saveCurrentSession();
    setState(() {
      _newSession(addGreeting: true);
      _attachedDoc = null;
    });
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HistorySheet(
        loadSessions: _loadAllSessions,
        currentSessionId: _sessionId,
        onSelect: (session) {
          Navigator.pop(context);
          setState(() {
            _sessionId = session.id;
            _messages.clear();
            _messages.addAll(session.messages);
            _attachedDoc = null;
          });
          _scrollToBottom();
        },
        onDelete: (id) async {
          await _deleteSession(id);
          if (id == _sessionId) setState(() => _newSession(addGreeting: true));
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final showWelcome = _messages.length == 1 && widget.attachedDocument == null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7048E8), Color(0xFF3B5BDB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Assistant IA',
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF1A1D23))),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF2F9E44), shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text('En ligne · Nafa Edu',
                        style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF2F9E44), fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, size: 22),
            tooltip: 'Historique',
            onPressed: _showHistory,
          ),
          IconButton(
            icon: const Icon(Icons.add_comment_outlined, size: 20),
            tooltip: 'Nouvelle conversation',
            onPressed: _startNewConversation,
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE9ECEF)),
        ),
      ),
      body: Column(
        children: [
          // Document context banner (when from banque card)
          if (widget.attachedDocument != null) _buildDocBanner(widget.attachedDocument!),
          Expanded(
            child: showWelcome
                ? _buildWelcomeView()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    // Show typing bubble only while waiting for first token
                    itemCount: _messages.length + (_isLoading && !_isStreaming ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (_isLoading && !_isStreaming && i == _messages.length) {
                        return _TypingBubble();
                      }
                      final isStreamingThis = _isStreaming && i == _messages.length - 1;
                      return _MessageBubble(message: _messages[i], isStreaming: isStreamingThis);
                    },
                  ),
          ),
          if (showWelcome && !_isLoading) _buildSuggestions(),
          // Attached file chip
          if (_attachedDoc != null && widget.attachedDocument == null)
            _buildAttachmentChip(_attachedDoc!),
          _buildInputBar(bottom),
        ],
      ),
    );
  }

  // ── Document banner (from card) ───────────────────────────────────────────────

  Widget _buildDocBanner(DocumentModel doc) {
    return Container(
      color: const Color(0xFFEEF2FF),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: const Color(0xFF3B5BDB).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: _isUploading
                ? const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3B5BDB))))
                : Icon(doc.isImage ? Icons.image_rounded : Icons.picture_as_pdf_rounded, color: const Color(0xFF3B5BDB), size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc.title,
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1A1D23)),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  _isUploading
                      ? 'Lecture du document...'
                      : [doc.matiereName, doc.classeName, doc.annee?.toString()].where((e) => e != null).join(' · '),
                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF495057)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _isUploading ? const Color(0xFFE9ECEF) : const Color(0xFF3B5BDB).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _isUploading ? 'Chargement...' : 'Sujet joint',
              style: GoogleFonts.inter(
                fontSize: 9, fontWeight: FontWeight.w700,
                color: _isUploading ? const Color(0xFF868E96) : const Color(0xFF3B5BDB),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Attachment chip (uploaded file) ──────────────────────────────────────────

  Widget _buildAttachmentChip(_AttachedDoc doc) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF7048E8).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              doc.isImage ? Icons.image_rounded : Icons.picture_as_pdf_rounded,
              color: const Color(0xFF7048E8), size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc.filename,
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1A1D23)),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  doc.isImage ? 'Image' : '${doc.pageCount} page${doc.pageCount > 1 ? 's' : ''}',
                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF868E96)),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _attachedDoc = null),
            child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFFADB5BD)),
          ),
        ],
      ),
    );
  }

  // ── Welcome view ──────────────────────────────────────────────────────────────

  Widget _buildWelcomeView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7048E8), Color(0xFF3B5BDB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: const Color(0xFF7048E8).withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 20),
          Text('Assistant IA Nafa Edu',
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF1A1D23))),
          const SizedBox(height: 8),
          Text(
            'Pose-moi n\'importe quelle question sur tes cours.\nTu peux aussi envoyer un sujet PDF 📎 pour que je t\'aide à l\'analyser !',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF868E96), height: 1.5),
          ),
          const SizedBox(height: 24),
          _MessageBubble(message: _messages.first),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Suggestions', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFADB5BD), fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => _useSuggestion(_suggestions[i]),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFD0BFFF)),
                  ),
                  child: Text(_suggestions[i],
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF5C3BC8), fontWeight: FontWeight.w500)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Input bar ─────────────────────────────────────────────────────────────────

  Widget _buildInputBar(double bottomInset) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE9ECEF))),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, -3))],
      ),
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, (bottomInset > 0 ? bottomInset : MediaQuery.of(context).padding.bottom) + 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Paperclip button
          GestureDetector(
            onTap: _isUploading ? null : _pickAndUploadFile,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40, height: 40,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _attachedDoc != null
                    ? const Color(0xFF7048E8)
                    : const Color(0xFFF1F3F5),
                shape: BoxShape.circle,
              ),
              child: _isUploading
                  ? const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7048E8))))
                  : Icon(
                      _attachedDoc != null ? Icons.attach_file_rounded : Icons.attach_file_rounded,
                      size: 18,
                      color: _attachedDoc != null ? Colors.white : const Color(0xFF868E96),
                    ),
            ),
          ),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE9ECEF)),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1A1D23)),
                decoration: InputDecoration(
                  hintText: _attachedDoc != null ? "Posez une question sur ce document..." : "Pose ta question...",
                  hintStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFADB5BD)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _send,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46, height: 46,
              decoration: BoxDecoration(
                gradient: _isLoading
                    ? const LinearGradient(colors: [Color(0xFFADB5BD), Color(0xFFADB5BD)])
                    : const LinearGradient(
                        colors: [Color(0xFF7048E8), Color(0xFF3B5BDB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                shape: BoxShape.circle,
                boxShadow: _isLoading ? [] : [
                  BoxShadow(color: const Color(0xFF7048E8).withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: _isLoading
                  ? const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ── History bottom sheet ───────────────────────────────────────────────────────

class _HistorySheet extends StatefulWidget {
  final Future<List<_ChatSession>> Function() loadSessions;
  final String currentSessionId;
  final void Function(_ChatSession) onSelect;
  final Future<void> Function(String id) onDelete;

  const _HistorySheet({
    required this.loadSessions,
    required this.currentSessionId,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  State<_HistorySheet> createState() => _HistorySheetState();
}

class _HistorySheetState extends State<_HistorySheet> {
  List<_ChatSession>? _sessions;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    widget.loadSessions().then((s) {
      if (mounted) setState(() { _sessions = s; _loading = false; });
    });
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays == 1) return 'Hier';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFDEE2E6), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Historique des conversations',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1A1D23))),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFE9ECEF)),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : (_sessions == null || _sessions!.isEmpty)
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.history_rounded, size: 56, color: Color(0xFFCED4DA)),
                              const SizedBox(height: 12),
                              Text('Aucun historique',
                                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF868E96))),
                              const SizedBox(height: 4),
                              Text('Tes conversations seront sauvegardées ici.',
                                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFADB5BD))),
                            ],
                          ),
                        )
                      : ListView.separated(
                          controller: sc,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _sessions!.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F3F5)),
                          itemBuilder: (_, i) {
                            final s = _sessions![i];
                            final isCurrent = s.id == widget.currentSessionId;
                            final msgCount = s.messages.where((m) => m.role == 'user').length;
                            return Dismissible(
                              key: Key(s.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: AppColors.error,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(Icons.delete_outline, color: Colors.white),
                              ),
                              onDismissed: (_) async {
                                setState(() => _sessions!.removeAt(i));
                                await widget.onDelete(s.id);
                              },
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                leading: Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: isCurrent ? const Color(0xFFEEF2FF) : const Color(0xFFF8F9FA),
                                    borderRadius: BorderRadius.circular(10),
                                    border: isCurrent ? Border.all(color: const Color(0xFF7048E8).withValues(alpha: 0.4)) : null,
                                  ),
                                  child: Icon(Icons.chat_bubble_outline_rounded, size: 18,
                                      color: isCurrent ? const Color(0xFF7048E8) : const Color(0xFF868E96)),
                                ),
                                title: Text(s.title,
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                        color: const Color(0xFF1A1D23)),
                                    maxLines: 2, overflow: TextOverflow.ellipsis),
                                subtitle: Text(
                                  '$msgCount message${msgCount > 1 ? 's' : ''} · ${_formatDate(s.createdAt)}',
                                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFADB5BD)),
                                ),
                                trailing: isCurrent
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEEF2FF),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text('En cours',
                                            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFF7048E8))),
                                      )
                                    : null,
                                onTap: () => widget.onSelect(s),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Message bubble ─────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final _Message message;
  final bool isStreaming;
  const _MessageBubble({required this.message, this.isStreaming = false});

  @override
  Widget build(BuildContext context) {
    final isAI = message.role == 'ai';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isAI ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isAI) ...[
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7048E8), Color(0xFF3B5BDB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
            Flexible(child: _AiBubble(message: message, isStreaming: isStreaming)),
          ] else ...[
            Flexible(child: _UserBubble(message: message)),
            const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}

// ── User bubble ────────────────────────────────────────────────────────────────

class _UserBubble extends StatelessWidget {
  final _Message message;
  const _UserBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: message.text));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message copié !'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF3B5BDB),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B5BDB).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: GoogleFonts.inter(fontSize: 13.5, color: Colors.white, height: 1.55),
        ),
      ),
    );
  }
}

// ── AI bubble (markdown + copy) ────────────────────────────────────────────────

class _AiBubble extends StatefulWidget {
  final _Message message;
  final bool isStreaming;
  const _AiBubble({required this.message, this.isStreaming = false});

  @override
  State<_AiBubble> createState() => _AiBubbleState();
}

class _AiBubbleState extends State<_AiBubble> {
  bool _copied = false;

  // Shared markdown style — initialized once
  static final _mdStyle = MarkdownStyleSheet(
    p: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF1A1D23), height: 1.65),
    h1: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF1A1D23)),
    h2: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1A1D23)),
    h3: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF3B5BDB)),
    strong: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF1A1D23)),
    em: GoogleFonts.inter(fontSize: 13.5, fontStyle: FontStyle.italic, color: const Color(0xFF495057)),
    del: GoogleFonts.inter(fontSize: 13.5, decoration: TextDecoration.lineThrough, color: const Color(0xFF868E96)),
    // Inline code — used for short formulas/values
    code: const TextStyle(
      fontFamily: 'monospace',
      fontSize: 12.5,
      color: Color(0xFF5C3BC8),
      backgroundColor: Color(0xFFF0EEFF),
    ),
    // Code block — used for multi-line formulas and equations
    codeblockDecoration: BoxDecoration(
      color: const Color(0xFFF3F0FF),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFD0BFFF)),
    ),
    codeblockPadding: const EdgeInsets.all(12),
    // Blockquote — used for definitions and key remarks
    blockquote: TextStyle(
      fontFamily: GoogleFonts.inter().fontFamily,
      fontSize: 13,
      color: const Color(0xFF495057),
      fontStyle: FontStyle.italic,
    ),
    blockquoteDecoration: const BoxDecoration(
      color: Color(0xFFF0EEFF),
      border: Border(left: BorderSide(color: Color(0xFF7048E8), width: 3)),
    ),
    blockquotePadding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
    // Tables
    tableHead: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1A1D23)),
    tableBody: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF495057)),
    tableBorder: TableBorder.all(color: const Color(0xFFDEE2E6), width: 1),
    tableHeadAlign: TextAlign.left,
    tableCellsPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    // Lists
    listBullet: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF7048E8)),
    listIndent: 20,
    listBulletPadding: const EdgeInsets.only(right: 6),
    // Horizontal rule
    horizontalRuleDecoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFFE9ECEF), width: 1.5)),
    ),
  );

  void _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.message.text));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isError = widget.message.isError;
    return Container(
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFFF5F5) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(18),
        ),
        border: Border.all(
          color: isError ? const Color(0xFFFFCDD2) : const Color(0xFFE9ECEF),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: isError
                ? Text(
                    widget.message.text,
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFC62828), height: 1.5),
                  )
                : MarkdownBody(
                    data: widget.message.text,
                    selectable: false,
                    styleSheet: _mdStyle,
                    softLineBreak: true,
                  ),
          ),
          // Bottom row: streaming indicator OR copy button
          Padding(
            padding: const EdgeInsets.only(right: 10, bottom: 6),
            child: Align(
              alignment: Alignment.centerRight,
              child: widget.isStreaming
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 10, height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: Color(0xFFADB5BD),
                          ),
                        ),
                        SizedBox(width: 5),
                        Text(
                          'En cours...',
                          style: TextStyle(fontSize: 10, color: Color(0xFFADB5BD)),
                        ),
                      ],
                    )
                  : GestureDetector(
                      onTap: _copy,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _copied
                              ? const Color(0xFF2F9E44).withValues(alpha: 0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _copied ? Icons.check_rounded : Icons.copy_rounded,
                              size: 12,
                              color: _copied ? const Color(0xFF2F9E44) : const Color(0xFFADB5BD),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _copied ? 'Copié !' : 'Copier',
                              style: TextStyle(
                                fontSize: 10,
                                color: _copied ? const Color(0xFF2F9E44) : const Color(0xFFADB5BD),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
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

// ── Typing indicator ───────────────────────────────────────────────────────────

class _TypingBubble extends StatefulWidget {
  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF7048E8), Color(0xFF3B5BDB)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18), topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4), bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: const Color(0xFFE9ECEF)),
            ),
            child: AnimatedBuilder(
              animation: _anim,
              builder: (_, __) => Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final val = ((_anim.value - i * 0.15).clamp(0.0, 1.0));
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 7, height: 7,
                    decoration: BoxDecoration(
                      color: Color.lerp(const Color(0xFFCED4DA), const Color(0xFF7048E8), val),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
