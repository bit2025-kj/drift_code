import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nafa_edu/config/constants.dart';


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
    final lower = url.toLowerCase();
    return lower.contains('.mp4') ||
        lower.contains('.mov') ||
        lower.contains('.avi') ||
        lower.contains('.mkv') ||
        lower.contains('video');
  }

  String _fullUrl(String url) {
    if (url.startsWith('http')) return url;
    return '${AppConstants.baseUrl}$url';
  }

  Widget _mediaItem(String url, {double? height, BorderRadius? radius}) {
    final isVideo = _isVideo(url);
    final br = radius ?? BorderRadius.zero;
    if (isVideo) {
      return ClipRRect(
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
                Text('Vidéo',
                    style: TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
        ),
      );
    }
    return ClipRRect(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = mediaUrls.length;

    if (count == 1) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: _mediaItem(mediaUrls[0]),
      );
    }

    if (count == 2) {
      return SizedBox(
        height: 200,
        child: Row(
          children: [
            Expanded(child: _mediaItem(mediaUrls[0], height: 200)),
            const SizedBox(width: 2),
            Expanded(child: _mediaItem(mediaUrls[1], height: 200)),
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
              child: _mediaItem(mediaUrls[0], height: 200),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: _mediaItem(mediaUrls[1])),
                  const SizedBox(height: 2),
                  Expanded(child: _mediaItem(mediaUrls[2])),
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
                Expanded(child: _mediaItem(show[0], height: double.infinity)),
                const SizedBox(width: 2),
                Expanded(child: _mediaItem(show[1], height: double.infinity)),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _mediaItem(show[2], height: double.infinity)),
                const SizedBox(width: 2),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _mediaItem(show[3], height: double.infinity),
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
