import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nafa_edu/config/constants.dart';
import 'package:nafa_edu/screens/shared/pdf_viewer_screen.dart';
import 'package:nafa_edu/screens/shared/video_player_screen.dart';


const kActionGray = Color(0xFF606770);

// ── Gradient Avatar ───────────────────────────────────────────────────────────

class ForumGradientAvatar extends StatelessWidget {
  final String initials;
  final double radius;
  final String? avatarUrl;

  const ForumGradientAvatar({
    super.key,
    required this.initials,
    required this.radius,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      final url = avatarUrl!.startsWith('http')
          ? avatarUrl!
          : '${AppConstants.baseUrl}$avatarUrl';
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: (_, __) => _gradient(),
          errorWidget: (_, __, ___) => _gradient(),
        ),
      );
    }
    return _gradient();
  }

  Widget _gradient() => Container(
    width: radius * 2,
    height: radius * 2,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        colors: [Color(0xFF7C3AED), Color(0xFF3B5BDB)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Center(
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.7,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

// ── Media Grid ────────────────────────────────────────────────────────────────

class ForumMediaGrid extends StatelessWidget {
  final List<String> mediaUrls;

  const ForumMediaGrid({super.key, required this.mediaUrls});

  bool _isVideo(String url) {
    final lower = url.toLowerCase().split('?').first;
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv') ||
        lower.contains('video');
  }

  bool _isPdf(String url) => url.toLowerCase().split('?').first.endsWith('.pdf');

  String _fullUrl(String url) {
    if (url.startsWith('http')) return url;
    return '${AppConstants.baseUrl}$url';
  }

  void _openImageFullscreen(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog.fullscreen(
        child: Stack(
          children: [
            Container(
              color: Colors.black,
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 6.0,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: _fullUrl(url),
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const CircularProgressIndicator(
                        color: Colors.white38, strokeWidth: 2),
                    errorWidget: (_, __, ___) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white38,
                        size: 64),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              left: 8,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    shape: const CircleBorder(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openPdf(BuildContext context, String url) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PdfViewerScreen(url: _fullUrl(url), title: 'Document'),
    ));
  }

  Future<void> _openVideo(BuildContext context, String url) async {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => VideoPlayerScreen(url: _fullUrl(url)),
    ));
  }

  Widget _mediaItem(BuildContext context, String url,
      {double? height, BorderRadius? radius}) {
    final br = radius ?? BorderRadius.zero;

    if (_isVideo(url)) {
      return GestureDetector(
        onTap: () => _openVideo(context, url),
        child: ClipRRect(
          borderRadius: br,
          child: Container(
            height: height,
            color: Colors.black,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_circle_outline, color: Colors.white, size: 48),
                  SizedBox(height: 4),
                  Text('Appuyer pour lire',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_isPdf(url)) {
      return GestureDetector(
        onTap: () => _openPdf(context, url),
        child: ClipRRect(
          borderRadius: br,
          child: Container(
            height: height,
            color: const Color(0xFFF3F0FF),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.picture_as_pdf_outlined,
                      color: Color(0xFF7C3AED), size: 48),
                  SizedBox(height: 4),
                  Text('Appuyer pour ouvrir le PDF',
                      style: TextStyle(color: Color(0xFF7C3AED), fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Image
    return GestureDetector(
      onTap: () => _openImageFullscreen(context, url),
      child: ClipRRect(
        borderRadius: br,
        child: CachedNetworkImage(
          imageUrl: _fullUrl(url),
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (_, __) =>
              Container(height: height, color: const Color(0xFFE4E6EB)),
          errorWidget: (_, __, ___) => Container(
            height: height,
            color: const Color(0xFFE4E6EB),
            child: const Icon(Icons.broken_image_outlined, color: kActionGray),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = mediaUrls.length;

    if (count == 1) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: _mediaItem(context, mediaUrls[0]),
      );
    }

    if (count == 2) {
      return SizedBox(
        height: 200,
        child: Row(
          children: [
            Expanded(child: _mediaItem(context, mediaUrls[0], height: 200)),
            const SizedBox(width: 2),
            Expanded(child: _mediaItem(context, mediaUrls[1], height: 200)),
          ],
        ),
      );
    }

    if (count == 3) {
      return SizedBox(
        height: 200,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: _mediaItem(context, mediaUrls[0], height: 200),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: _mediaItem(context, mediaUrls[1])),
                  const SizedBox(height: 2),
                  Expanded(child: _mediaItem(context, mediaUrls[2])),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 4+ media: 2x2 grid, overlay "+N" on last if > 4
    final show = mediaUrls.take(4).toList();
    final extra = count - 4;
    return SizedBox(
      height: 300,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                    child: _mediaItem(context, show[0],
                        height: double.infinity)),
                const SizedBox(width: 2),
                Expanded(
                    child: _mediaItem(context, show[1],
                        height: double.infinity)),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Row(
              children: [
                Expanded(
                    child: _mediaItem(context, show[2],
                        height: double.infinity)),
                const SizedBox(width: 2),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _mediaItem(context, show[3], height: double.infinity),
                      if (extra > 0)
                        Container(
                          color: Colors.black.withValues(alpha: 0.5),
                          child: Center(
                            child: Text(
                              '+$extra',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
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
        ],
      ),
    );
  }
}

// ── Action Button ─────────────────────────────────────────────────────────────

class ForumActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const ForumActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20, color: color),
      label: Text(
        label,
        style:
            TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
