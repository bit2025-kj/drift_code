import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nafa_edu/config/theme.dart';
import 'package:nafa_edu/core/api/api_client.dart';
import 'package:nafa_edu/core/api/api_endpoints.dart';
import 'package:nafa_edu/models/forum_model.dart';
import 'package:nafa_edu/providers/forum_provider.dart';
import 'package:nafa_edu/screens/forum/forum_widgets.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _kTimestampColor = Color(0xFF65676B);
const _kFeedBg = Color(0xFFF0F2F5);

class DiscussionDetailScreen extends ConsumerStatefulWidget {
  final String discussionId;
  final String title;
  final bool autoFocusComment;

  const DiscussionDetailScreen({
    super.key,
    required this.discussionId,
    required this.title,
    this.autoFocusComment = false,
  });

  @override
  ConsumerState<DiscussionDetailScreen> createState() =>
      _DiscussionDetailScreenState();
}

class _DiscussionDetailScreenState
    extends ConsumerState<DiscussionDetailScreen> {
  final _commentController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isPosting = false;
  String? _replyToId;
  String? _replyToName;

  @override
  void initState() {
    super.initState();
    if (widget.autoFocusComment) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Future<void> _postComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;
    setState(() => _isPosting = true);
    try {
      await ApiClient.instance.dio.post(
        ApiEndpoints.discussionComments(widget.discussionId),
        data: {
          'content': content,
          if (_replyToId != null) 'parent_id': _replyToId,
        },
      );
      _commentController.clear();
      setState(() {
        _replyToId = null;
        _replyToName = null;
      });
      ref.invalidate(discussionDetailProvider(widget.discussionId));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'envoi')),
        );
      }
    }
    if (mounted) setState(() => _isPosting = false);
  }

  Future<void> _likeDiscussion() async {
    try {
      await ApiClient.instance.dio
          .post(ApiEndpoints.likeDiscussion(widget.discussionId));
      ref.invalidate(discussionDetailProvider(widget.discussionId));
    } catch (_) {}
  }

  Future<void> _likeComment(String commentId) async {
    try {
      await ApiClient.instance.dio
          .post(ApiEndpoints.likeComment(widget.discussionId, commentId));
      ref.invalidate(discussionDetailProvider(widget.discussionId));
    } catch (_) {}
  }

  void _startReply(String commentId, String authorName) {
    setState(() {
      _replyToId = commentId;
      _replyToName = authorName;
    });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync =
        ref.watch(discussionDetailProvider(widget.discussionId));

    return Scaffold(
      backgroundColor: _kFeedBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Publication',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
      ),
      body: detailAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Erreur de chargement',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref
                    .invalidate(discussionDetailProvider(widget.discussionId)),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (disc) => Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  // Full post card
                  _FullPostCard(
                    disc: disc,
                    onLike: _likeDiscussion,
                    relativeTime: _relativeTime,
                  ),
                  const SizedBox(height: 6),

                  // Comments header
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Text(
                      '${disc.commentsCount} commentaire${disc.commentsCount > 1 ? 's' : ''}',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),

                  // Comments
                  if (disc.comments.isEmpty)
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: const Center(
                        child: Text(
                          'Sois le premier à commenter',
                          style: TextStyle(
                              color: _kTimestampColor, fontSize: 14),
                        ),
                      ),
                    )
                  else
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: Column(
                        children: disc.comments
                            .map((c) => _CommentTile(
                                  comment: c,
                                  onLike: () => _likeComment(c.id),
                                  onReply: () =>
                                      _startReply(c.id, c.author.fullName),
                                  relativeTime: _relativeTime,
                                  likeComment: _likeComment,
                                  startReply: _startReply,
                                ))
                            .toList(),
                      ),
                    ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
            _CommentInputBar(
              controller: _commentController,
              focusNode: _focusNode,
              isPosting: _isPosting,
              replyToName: _replyToName,
              onSend: _postComment,
              onCancelReply: () => setState(() {
                _replyToId = null;
                _replyToName = null;
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Full Post Card ────────────────────────────────────────────────────────────

class _FullPostCard extends StatelessWidget {
  final DiscussionDetailModel disc;
  final VoidCallback onLike;
  final String Function(DateTime) relativeTime;

  const _FullPostCard({
    required this.disc,
    required this.onLike,
    required this.relativeTime,
  });

  @override
  Widget build(BuildContext context) {
    final hasMedia = disc.mediaUrls.isNotEmpty;

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ForumGradientAvatar(
                    initials: disc.author.initials, radius: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        disc.author.fullName,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        [
                          relativeTime(disc.createdAt),
                          if (disc.matiereName != null) disc.matiereName!,
                        ].join(' · '),
                        style: const TextStyle(
                            fontSize: 11, color: _kTimestampColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Full content — no truncation
          if (disc.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Text(
                disc.content,
                style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: AppColors.textPrimary),
              ),
            ),

          // Media
          if (hasMedia)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ForumMediaGrid(mediaUrls: disc.mediaUrls),
            ),

          // Stats row
          if (disc.likesCount > 0 || disc.commentsCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Row(
                children: [
                  if (disc.likesCount > 0) ...[
                    Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                      child: const Icon(Icons.thumb_up,
                          size: 11, color: Colors.white),
                    ),
                    const SizedBox(width: 4),
                    Text('${disc.likesCount}',
                        style: const TextStyle(
                            fontSize: 13, color: _kTimestampColor)),
                  ],
                  const Spacer(),
                  if (disc.commentsCount > 0)
                    Text(
                      '${disc.commentsCount} commentaire${disc.commentsCount > 1 ? 's' : ''}',
                      style: const TextStyle(
                          fontSize: 13, color: _kTimestampColor),
                    ),
                ],
              ),
            ),

          const Padding(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Divider(height: 1, color: Color(0xFFE4E6EB)),
          ),

          // Action row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ForumActionButton(
                  icon: Icons.thumb_up_outlined,
                  label: 'J\'aime',
                  color: kActionGray,
                  onTap: onLike,
                ),
                ForumActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: 'Commenter',
                  color: kActionGray,
                  onTap: () {},
                ),
                ForumActionButton(
                  icon: Icons.share_outlined,
                  label: 'Partager',
                  color: kActionGray,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Comment Tile ──────────────────────────────────────────────────────────────

class _CommentTile extends StatefulWidget {
  final CommentModel comment;
  final VoidCallback onLike;
  final VoidCallback onReply;
  final String Function(DateTime) relativeTime;
  final Future<void> Function(String) likeComment;
  final void Function(String, String) startReply;

  const _CommentTile({
    required this.comment,
    required this.onLike,
    required this.onReply,
    required this.relativeTime,
    required this.likeComment,
    required this.startReply,
  });

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile>
    with SingleTickerProviderStateMixin {
  bool _showReplies = false;
  late AnimationController _controller;
  late Animation<double> _heightFactor;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _heightFactor = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleReplies() {
    setState(() => _showReplies = !_showReplies);
    if (_showReplies) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.comment;
    final hasReplies = c.replies.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Comment bubble row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ForumGradientAvatar(initials: c.author.initials, radius: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.author.fullName,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            c.content,
                            style: const TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    // Meta row
                    Padding(
                      padding: const EdgeInsets.only(left: 4, top: 4),
                      child: Row(
                        children: [
                          Text(
                            widget.relativeTime(c.createdAt),
                            style: const TextStyle(
                                fontSize: 11, color: _kTimestampColor),
                          ),
                          const SizedBox(width: 14),
                          GestureDetector(
                            onTap: widget.onLike,
                            child: Row(
                              children: [
                                const Text(
                                  'J\'aime',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: kActionGray),
                                ),
                                if (c.likesCount > 0) ...[
                                  const SizedBox(width: 3),
                                  Text(
                                    '(${c.likesCount})',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: _kTimestampColor),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          GestureDetector(
                            onTap: widget.onReply,
                            child: const Text(
                              'Répondre',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: kActionGray),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Replies toggle + animated list
          if (hasReplies) ...[
            Padding(
              padding: const EdgeInsets.only(left: 48, top: 6),
              child: GestureDetector(
                onTap: _toggleReplies,
                child: Row(
                  children: [
                    const Icon(Icons.subdirectory_arrow_right,
                        size: 16, color: kActionGray),
                    const SizedBox(width: 4),
                    Text(
                      _showReplies
                          ? 'Masquer les réponses'
                          : 'Voir ${c.replies.length} réponse${c.replies.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),
            SizeTransition(
              sizeFactor: _heightFactor,
              child: Padding(
                padding: const EdgeInsets.only(left: 48, top: 8),
                child: Column(
                  children: c.replies
                      .map((r) => _ReplyTile(
                            reply: r,
                            onLike: () => widget.likeComment(r.id),
                            onReply: () =>
                                widget.startReply(c.id, r.author.fullName),
                            relativeTime: widget.relativeTime,
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Reply Tile ────────────────────────────────────────────────────────────────

class _ReplyTile extends StatelessWidget {
  final CommentModel reply;
  final VoidCallback onLike;
  final VoidCallback onReply;
  final String Function(DateTime) relativeTime;

  const _ReplyTile({
    required this.reply,
    required this.onLike,
    required this.onReply,
    required this.relativeTime,
  });

  @override
  Widget build(BuildContext context) {
    final r = reply;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ForumGradientAvatar(initials: r.author.initials, radius: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.author.fullName,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        r.content,
                        style: const TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 3),
                  child: Row(
                    children: [
                      Text(
                        relativeTime(r.createdAt),
                        style: const TextStyle(
                            fontSize: 10, color: _kTimestampColor),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: onLike,
                        child: Row(
                          children: [
                            const Text(
                              'J\'aime',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: kActionGray),
                            ),
                            if (r.likesCount > 0) ...[
                              const SizedBox(width: 3),
                              Text(
                                '(${r.likesCount})',
                                style: const TextStyle(
                                    fontSize: 10, color: _kTimestampColor),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: onReply,
                        child: const Text(
                          'Répondre',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: kActionGray),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Comment Input Bar ─────────────────────────────────────────────────────────

class _CommentInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isPosting;
  final String? replyToName;
  final VoidCallback onSend;
  final VoidCallback onCancelReply;

  const _CommentInputBar({
    required this.controller,
    required this.focusNode,
    required this.isPosting,
    required this.replyToName,
    required this.onSend,
    required this.onCancelReply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (replyToName != null)
              Container(
                color: AppColors.primary.withValues(alpha: 0.06),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.reply,
                        size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Réponse à $replyToName',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    GestureDetector(
                      onTap: onCancelReply,
                      child: const Icon(Icons.close,
                          size: 16, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  const ForumGradientAvatar(initials: 'M', radius: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: controller,
                      builder: (_, value, __) => TextField(
                        controller: controller,
                        focusNode: focusNode,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => onSend(),
                        decoration: InputDecoration(
                          hintText: 'Écrire un commentaire...',
                          filled: true,
                          fillColor: const Color(0xFFF0F2F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          suffixIcon: value.text.isNotEmpty
                              ? IconButton(
                                  icon: isPosting
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.primary),
                                        )
                                      : const Icon(Icons.send_rounded,
                                          color: AppColors.primary,
                                          size: 20),
                                  onPressed: isPosting ? null : onSend,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
