import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nafa_edu/config/theme.dart';
import 'package:nafa_edu/models/forum_model.dart';
import 'package:nafa_edu/providers/auth_provider.dart';
import 'package:nafa_edu/providers/forum_provider.dart';
import 'package:nafa_edu/screens/forum/discussion_detail_screen.dart';
import 'package:nafa_edu/screens/forum/forum_widgets.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _kFeedBg = Color(0xFFF0F2F5);
const _kTimestampColor = Color(0xFF65676B);

// ── Forum Screen ─────────────────────────────────────────────────────────────

class ForumScreen extends ConsumerStatefulWidget {
  const ForumScreen({super.key});

  @override
  ConsumerState<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends ConsumerState<ForumScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(discussionProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discussionProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: _kFeedBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Communauté',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            tooltip: 'Nouvelle publication',
            onPressed: () => _openComposer(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(discussionProvider.notifier).refresh(),
        color: AppColors.primary,
        child: ListView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: 1 + state.discussions.length + (state.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _ComposeBar(
                onTap: () => _openComposer(context),
                initials: user?.initials ?? 'U',
                avatarUrl: user?.avatarUrl,
              );
            }
            final postIndex = index - 1;
            if (postIndex < state.discussions.length) {
              final d = state.discussions[postIndex];
              return _PostCard(
                discussion: d,
                isLiked: state.likedIds.contains(d.id),
                onLike: () =>
                    ref.read(discussionProvider.notifier).toggleLike(d.id),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DiscussionDetailScreen(
                      discussionId: d.id,
                      title: d.title,
                    ),
                  ),
                ),
                onComment: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DiscussionDetailScreen(
                      discussionId: d.id,
                      title: d.title,
                      autoFocusComment: true,
                    ),
                  ),
                ),
              );
            }
            // Load-more indicator
            if (state.isLoading) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary),
                ),
              );
            }
            return const SizedBox(height: 24);
          },
        ),
      ),
    );
  }

  void _openComposer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PostComposerSheet(),
    );
  }
}

// ── Compose Bar ───────────────────────────────────────────────────────────────

class _ComposeBar extends StatelessWidget {
  final VoidCallback onTap;
  final String initials;
  final String? avatarUrl;
  const _ComposeBar({required this.onTap, required this.initials, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        children: [
          Row(
            children: [
              ForumGradientAvatar(initials: initials, radius: 20, avatarUrl: avatarUrl),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: const Color(0xFFCED0D4)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Quoi de neuf ?',
                      style: TextStyle(
                          fontSize: 14, color: kActionGray),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 16, color: Color(0xFFE4E6EB)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _QuickAction(
                  icon: Icons.photo_library_outlined,
                  label: 'Photo',
                  color: Colors.green,
                  onTap: onTap),
              _QuickAction(
                  icon: Icons.videocam_outlined,
                  label: 'Vidéo',
                  color: Colors.red,
                  onTap: onTap),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 20),
      label: Text(label,
          style: const TextStyle(
              color: kActionGray,
              fontSize: 13,
              fontWeight: FontWeight.w500)),
    );
  }
}

// ── Post Card ─────────────────────────────────────────────────────────────────

class _PostCard extends StatefulWidget {
  final DiscussionModel discussion;
  final bool isLiked;
  final VoidCallback onLike;
  final VoidCallback onTap;
  final VoidCallback onComment;

  const _PostCard({
    required this.discussion,
    required this.isLiked,
    required this.onLike,
    required this.onTap,
    required this.onComment,
  });

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _likeController;
  late Animation<double> _likeScale;

  @override
  void initState() {
    super.initState();
    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _likeScale = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _likeController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _likeController.dispose();
    super.dispose();
  }

  void _handleLike() {
    _likeController.forward().then((_) => _likeController.reverse());
    widget.onLike();
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.discussion;
    final hasContent = d.content.isNotEmpty;
    final hasMedia = d.mediaUrls.isNotEmpty;

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ForumGradientAvatar(initials: d.author.initials, radius: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.author.fullName,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        [
                          _relativeTime(d.createdAt),
                          if (d.matiereName != null) d.matiereName!,
                        ].join(' · '),
                        style: const TextStyle(
                            fontSize: 11, color: _kTimestampColor),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, color: kActionGray),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'report', child: Text('Signaler')),
                    PopupMenuItem(value: 'copy', child: Text('Copier le lien')),
                  ],
                ),
              ],
            ),
          ),

          // Content text
          if (hasContent)
            GestureDetector(
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: _expanded || d.content.length <= 200
                    ? Text(d.content,
                        style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: AppColors.textPrimary))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.content,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: AppColors.textPrimary),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _expanded = true),
                            child: const Text(
                              'Voir plus',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: kActionGray,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

          // Media
          if (hasMedia)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ForumMediaGrid(mediaUrls: d.mediaUrls),
            ),

          // Like / comment count row
          if (d.likesCount > 0 || d.commentsCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
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
                  if (d.likesCount > 0)
                    Text('${d.likesCount}',
                        style: const TextStyle(
                            fontSize: 13, color: _kTimestampColor)),
                  const Spacer(),
                  if (d.commentsCount > 0)
                    GestureDetector(
                      onTap: widget.onComment,
                      child: Text(
                        '${d.commentsCount} commentaire${d.commentsCount > 1 ? 's' : ''}',
                        style: const TextStyle(
                            fontSize: 13, color: _kTimestampColor),
                      ),
                    ),
                ],
              ),
            ),

          const Padding(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Divider(height: 1, color: Color(0xFFE4E6EB)),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ScaleTransition(
                  scale: _likeScale,
                  child: ForumActionButton(
                    icon: widget.isLiked
                        ? Icons.thumb_up
                        : Icons.thumb_up_outlined,
                    label: 'J\'aime',
                    color: widget.isLiked ? AppColors.primary : kActionGray,
                    onTap: _handleLike,
                  ),
                ),
                ForumActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: 'Commenter',
                  color: kActionGray,
                  onTap: widget.onComment,
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

// ── Post Composer Sheet ───────────────────────────────────────────────────────

class _PostComposerSheet extends ConsumerStatefulWidget {
  const _PostComposerSheet();

  @override
  ConsumerState<_PostComposerSheet> createState() => _PostComposerSheetState();
}

class _PostComposerSheetState extends ConsumerState<_PostComposerSheet> {
  final _textController = TextEditingController();
  final List<PlatformFile> _selectedFiles = [];
  bool _isPublishing = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
      allowMultiple: true,
      withData: true,
    );
    if (result != null) {
      setState(() => _selectedFiles.addAll(result.files));
    }
  }

  Future<void> _pickVideos() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mov', 'avi', 'mkv'],
      allowMultiple: true,
      withData: true,
    );
    if (result != null) {
      setState(() => _selectedFiles.addAll(result.files));
    }
  }

  Future<void> _publish() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedFiles.isEmpty) return;

    setState(() => _isPublishing = true);

    final notifier = ref.read(discussionProvider.notifier);
    final mediaUrls = <String>[];

    for (final file in _selectedFiles) {
      final url = await notifier.uploadMedia(file);
      if (url != null) mediaUrls.add(url);
    }

    final ok = await notifier.createPost(
      text: text.isEmpty ? '...' : text,
      mediaUrls: mediaUrls,
    );

    if (mounted) {
      setState(() => _isPublishing = false);
      if (ok) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Publication publiée !')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la publication')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomPad),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCED0D4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  ForumGradientAvatar(
                initials: ref.watch(authProvider).user?.initials ?? 'U',
                radius: 18,
                avatarUrl: ref.watch(authProvider).user?.avatarUrl,
              ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Publier dans la communauté',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (_isPublishing)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary),
                    ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE4E6EB)),

            // Text + media previews — scrollable
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: TextField(
                        controller: _textController,
                        maxLines: null,
                        minLines: 3,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Qu\'avez-vous en tête ?',
                          border: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style:
                            const TextStyle(fontSize: 15, height: 1.5),
                      ),
                    ),
                    if (_selectedFiles.isNotEmpty)
                      SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _selectedFiles.length,
                          itemBuilder: (_, i) {
                            final file = _selectedFiles[i];
                            return Stack(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  margin:
                                      const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE4E6EB),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: file.bytes != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.memory(
                                              file.bytes!,
                                              fit: BoxFit.cover),
                                        )
                                      : const Center(
                                          child: Icon(
                                              Icons.insert_drive_file,
                                              color: kActionGray),
                                        ),
                                ),
                                Positioned(
                                  top: 2,
                                  right: 10,
                                  child: GestureDetector(
                                    onTap: () => setState(
                                        () => _selectedFiles.removeAt(i)),
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.black54,
                                      ),
                                      child: const Icon(Icons.close,
                                          color: Colors.white, size: 13),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE4E6EB)),

            // Toolbar
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.photo_library_outlined,
                        color: Colors.green),
                    tooltip: 'Photo',
                  ),
                  IconButton(
                    onPressed: _pickVideos,
                    icon: const Icon(Icons.videocam_outlined,
                        color: Colors.red),
                    tooltip: 'Vidéo',
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _isPublishing ? null : _publish,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      textStyle: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    child: const Text('Publier'),
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
