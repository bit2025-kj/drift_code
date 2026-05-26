import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nafa_edu/config/constants.dart';
import 'package:nafa_edu/config/theme.dart';
import 'package:nafa_edu/models/marketplace_model.dart';
import 'package:nafa_edu/providers/marketplace_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  bool _isPurchasing = false;
  int _mediaPage = 0;
  final _pageCtrl = PageController();

  ProductModel get prod => widget.product;

  String _fullUrl(String url) =>
      url.startsWith('http') ? url : '${AppConstants.baseUrl}$url';

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(_fullUrl(url));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _purchase() async {
    if (prod.isFree) {
      if (prod.mediaUrls.isNotEmpty) {
        await _openUrl(prod.mediaUrls.first.url);
      }
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer l\'achat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(prod.title,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(prod.priceLabel,
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Acheter')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isPurchasing = true);
    final result =
        await ref.read(marketplaceProvider.notifier).purchase(prod.id);
    if (mounted) {
      setState(() => _isPurchasing = false);
      if (result != null && result['error'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] as String)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Achat effectué avec succès !'),
            backgroundColor: AppColors.success,
          ),
        );
        // Open first media after purchase
        final media = (result?['media_urls'] as List?)
                ?.map((m) => ProductMedia.fromJson(m as Map<String, dynamic>))
                .toList() ??
            prod.mediaUrls;
        if (media.isNotEmpty) await _openUrl(media.first.url);
      }
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildBody()),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildAppBar() {
    final hasThumbnail =
        prod.thumbnailUrl != null || prod.firstImage != null;
    final thumbUrl = prod.thumbnailUrl ?? prod.firstImage?.url;

    return SliverAppBar(
      expandedHeight: hasThumbnail ? 220 : 160,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: hasThumbnail
            ? CachedNetworkImage(
                imageUrl: _fullUrl(thumbUrl!),
                fit: BoxFit.cover,
                placeholder: (_, __) => _GradientHeader(prod),
                errorWidget: (_, __, ___) => _GradientHeader(prod),
              )
            : _GradientHeader(prod),
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + teacher
          Text(prod.title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          if (prod.teacherName != null)
            Row(
              children: [
                if (prod.teacherVerified)
                  const Icon(Icons.verified,
                      size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(prod.teacherName!,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),

          const SizedBox(height: 12),

          // Stats chips
          Row(
            children: [
              _Chip(
                  icon: Icons.star_rounded,
                  label: prod.rating.toStringAsFixed(1),
                  color: const Color(0xFFFFD43B)),
              const SizedBox(width: 8),
              _Chip(
                  icon: Icons.people_outline,
                  label: '${prod.purchasesCount} achats',
                  color: AppColors.primary),
              if (prod.hasDiscount) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('-${prod.discountPercent}%',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),

          // Tags
          if (prod.matiereName != null ||
              prod.classeName != null ||
              prod.levelName != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              children: [
                if (prod.levelName != null) _Tag(prod.levelName!),
                if (prod.classeName != null) _Tag(prod.classeName!),
                if (prod.matiereName != null) _Tag(prod.matiereName!),
              ],
            ),
          ],

          const SizedBox(height: 20),

          // Media gallery
          if (prod.mediaUrls.isNotEmpty) ...[
            _sectionTitle('Contenu inclus'),
            const SizedBox(height: 10),
            _MediaGallery(
              mediaUrls: prod.mediaUrls,
              onOpen: _openUrl,
              pageCtrl: _pageCtrl,
              currentPage: _mediaPage,
              onPageChanged: (i) => setState(() => _mediaPage = i),
            ),
            const SizedBox(height: 20),
          ],

          // Pack items
          if (prod.isPack && prod.packItems.isNotEmpty) ...[
            _sectionTitle('Éléments du pack (${prod.packItems.length})'),
            const SizedBox(height: 10),
            ...prod.packItems.asMap().entries.map(
                  (e) => _PackItemRow(
                    index: e.key + 1,
                    item: e.value,
                  ),
                ),
            const SizedBox(height: 20),
          ],

          // Description
          _sectionTitle('Description'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(prod.description,
                style: const TextStyle(
                    fontSize: 13, height: 1.7, color: AppColors.textPrimary)),
          ),

          const SizedBox(height: 20),

          // Details
          _sectionTitle('Détails'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _DetailRow('Type', _typeLabel()),
                if (prod.levelName != null)
                  _DetailRow('Niveau', prod.levelName!),
                if (prod.classeName != null)
                  _DetailRow('Classe', prod.classeName!),
                if (prod.matiereName != null)
                  _DetailRow('Matière', prod.matiereName!),
                _DetailRow('Évaluations', '${prod.ratingsCount} avis'),
                if (prod.mediaUrls.isNotEmpty)
                  _DetailRow('Fichiers',
                      '${prod.mediaUrls.length} fichier${prod.mediaUrls.length > 1 ? 's' : ''}'),
              ],
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (prod.hasDiscount)
                  Text(
                    '${prod.price} FCFA',
                    style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: AppColors.textSecondary,
                        fontSize: 12),
                  ),
                Text(prod.priceLabel,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary)),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isPurchasing ? null : _purchase,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                child: _isPurchasing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(prod.isFree ? 'Accéder gratuitement' : 'Acheter maintenant'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700));

  String _typeLabel() {
    switch (prod.productType) {
      case 'pack':
        return 'Pack';
      case 'cours':
        return 'Cours';
      case 'resume':
        return 'Résumé';
      case 'sujet_corrige':
        return 'Sujets & Corrigés';
      case 'video':
        return 'Vidéo';
      default:
        return prod.productType;
    }
  }
}

// ── Media gallery ─────────────────────────────────────────────────────────────

class _MediaGallery extends StatelessWidget {
  final List<ProductMedia> mediaUrls;
  final Future<void> Function(String) onOpen;
  final PageController pageCtrl;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  const _MediaGallery({
    required this.mediaUrls,
    required this.onOpen,
    required this.pageCtrl,
    required this.currentPage,
    required this.onPageChanged,
  });

  String _fullUrl(String url) =>
      url.startsWith('http') ? url : '${AppConstants.baseUrl}$url';

  Widget _mediaWidget(ProductMedia m) {
    if (m.isVideo) {
      return GestureDetector(
        onTap: () => onOpen(m.url),
        child: Container(
          color: Colors.black,
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_circle_outline,
                    color: Colors.white, size: 56),
                SizedBox(height: 6),
                Text('Appuyez pour lire la vidéo',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ),
      );
    }
    if (m.isPdf) {
      return GestureDetector(
        onTap: () => onOpen(m.url),
        child: Container(
          color: const Color(0xFFF3F0FF),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.picture_as_pdf_outlined,
                  color: Color(0xFF7C3AED), size: 56),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  m.name.isNotEmpty ? m.name : 'Document PDF',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Color(0xFF7C3AED),
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 6),
              const Text('Appuyez pour ouvrir',
                  style: TextStyle(
                      color: Color(0xFF7C3AED), fontSize: 11)),
            ],
          ),
        ),
      );
    }
    // Image
    return GestureDetector(
      onTap: () => onOpen(m.url),
      child: CachedNetworkImage(
        imageUrl: _fullUrl(m.url),
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: const Color(0xFFE4E6EB)),
        errorWidget: (_, __, ___) => Container(
          color: const Color(0xFFE4E6EB),
          child: const Icon(Icons.broken_image_outlined,
              color: AppColors.textHint),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (mediaUrls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: _mediaWidget(mediaUrls[0]),
        ),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: PageView.builder(
              controller: pageCtrl,
              onPageChanged: onPageChanged,
              itemCount: mediaUrls.length,
              itemBuilder: (_, i) => _mediaWidget(mediaUrls[i]),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            mediaUrls.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == currentPage ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == currentPage
                    ? AppColors.primary
                    : AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${currentPage + 1} / ${mediaUrls.length}',
          style: const TextStyle(
              fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ── Pack item row ─────────────────────────────────────────────────────────────

class _PackItemRow extends StatelessWidget {
  final int index;
  final PackItem item;

  const _PackItemRow({required this.index, required this.item});

  IconData _icon() {
    switch (item.type) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'video':
        return Icons.play_circle_outline;
      default:
        return Icons.image_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('$index',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
            ),
          ),
          const SizedBox(width: 10),
          Icon(_icon(), size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(item.title,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          Text(
            item.type.toUpperCase(),
            style: const TextStyle(
                fontSize: 9,
                color: AppColors.textHint,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _GradientHeader extends StatelessWidget {
  final ProductModel prod;
  const _GradientHeader(this.prod);

  IconData _icon() {
    switch (prod.productType) {
      case 'pack':
        return Icons.inventory_2_outlined;
      case 'cours':
        return Icons.menu_book_outlined;
      case 'resume':
        return Icons.article_outlined;
      case 'video':
        return Icons.play_circle_outline;
      default:
        return Icons.picture_as_pdf_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2F4AC0), Color(0xFF4DABF7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(_icon(), color: Colors.white, size: 64),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Chip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
                fontSize: 12, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11,
              color: AppColors.primary,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
