import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nafa_edu/config/constants.dart';
import 'package:nafa_edu/config/theme.dart';
import 'package:nafa_edu/models/marketplace_model.dart';
import 'package:nafa_edu/providers/auth_provider.dart';
import 'package:nafa_edu/providers/marketplace_provider.dart';
import 'package:nafa_edu/screens/marketplace/create_product_screen.dart';
import 'package:nafa_edu/screens/marketplace/product_detail_screen.dart';
import 'package:nafa_edu/screens/marketplace/teacher_dashboard_screen.dart';
import 'package:nafa_edu/screens/marketplace/teacher_request_screen.dart';
import 'package:nafa_edu/core/utils/auth_utils.dart';

const _kTypes = ['Tous', 'Cours', 'Packs', 'Sujets & Corrigés', 'Résumés', 'Vidéos'];
const _kTypeValues = [null, 'cours', 'pack', 'sujet_corrige', 'resume', 'video'];

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  int _selectedType = 0;
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 300) {
      ref.read(marketplaceProvider.notifier).loadMore();
    }
  }

  void _applyType(int i) {
    setState(() => _selectedType = i);
    ref.read(marketplaceProvider.notifier).applyFilter(
          ProductFilter(
            productType: _kTypeValues[i],
            q: _searchCtrl.text.isEmpty ? null : _searchCtrl.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isTeacher = user?.isTeacher ?? false;
    final featured = ref.watch(featuredProductsProvider);
    final state = ref.watch(marketplaceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Marketplace',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        actions: [
          // Wallet balance
          Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_balance_wallet_outlined,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  '${user?.walletBalance ?? 0} FCFA',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary),
                ),
              ],
            ),
          ),
          if (isTeacher)
            IconButton(
              icon: const Icon(Icons.dashboard_outlined, color: AppColors.primary),
              tooltip: 'Mon tableau de bord',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const TeacherDashboardScreen()),
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(marketplaceProvider.notifier).refresh(),
        color: AppColors.primary,
        child: ListView(
          controller: _scrollCtrl,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _buildSearch(),
            _buildTypeChips(),
            if (!isTeacher) _buildBecomeProfBanner(context),
            if (isTeacher) _buildTeacherBanner(context),
            _buildSectionHeader('Mis en avant'),
            _buildFeaturedGrid(featured),
            _buildSectionHeader('Tous les produits'),
            _buildProductsList(state),
            if (state.isLoading && state.products.isNotEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary)),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Rechercher un cours, résumé, pack...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    ref.read(marketplaceProvider.notifier).applyFilter(
                          ProductFilter(productType: _kTypeValues[_selectedType]),
                        );
                  },
                )
              : null,
        ),
        onSubmitted: (q) {
          ref.read(marketplaceProvider.notifier).applyFilter(
                ProductFilter(
                  productType: _kTypeValues[_selectedType],
                  q: q.isEmpty ? null : q,
                ),
              );
        },
      ),
    );
  }

  Widget _buildTypeChips() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _kTypes.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ChoiceChip(
            label: Text(_kTypes[i]),
            selected: _selectedType == i,
            onSelected: (_) => _applyType(i),
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              color: _selectedType == i ? Colors.white : AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBecomeProfBanner(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (!await requireAuth(context, ref)) return;
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TeacherRequestScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF3B5BDB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Devenir enseignant',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Partagez vos connaissances et gagnez de l\'argent en vendant vos cours.',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                        height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Soumettre ma candidature',
                      style: TextStyle(
                          color: Color(0xFF7C3AED),
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.school_outlined, color: Colors.white, size: 52),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreateProductScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2F4AC0), Color(0xFF4DABF7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Publier un nouveau contenu',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cours, résumé, pack, sujets corrigés ou vidéo.',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '+ Nouveau produit',
                      style: TextStyle(
                          color: Color(0xFF2F4AC0),
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.add_circle_outline, color: Colors.white, size: 52),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Text(title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildFeaturedGrid(AsyncValue<List<ProductModel>> featured) {
    return featured.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox(),
      data: (products) {
        if (products.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Aucun produit mis en avant pour l\'instant.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          );
        }
        return SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        ProductDetailScreen(product: products[i])),
              ),
              child: _ProductCard(
                product: products[i],
                onBuy: () => _purchase(context, products[i]),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductsList(ProductListState state) {
    if (state.isLoading && state.products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (state.error != null && state.products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              Text(state.error!,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () =>
                    ref.read(marketplaceProvider.notifier).refresh(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }
    if (state.products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
            child: Text('Aucun produit trouvé',
                style: TextStyle(color: AppColors.textSecondary))),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: state.products.map((product) {
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(product: product)),
            ),
            child: _ProductListTile(
              product: product,
              onBuy: () => _purchase(context, product),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _purchase(BuildContext context, ProductModel product) async {
    if (!await requireAuth(context, ref)) return;
    if (product.isFree) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contenu gratuit — accès direct !')),
      );
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
            Text(product.title,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(product.priceLabel,
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
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

    if (confirm != true || !context.mounted) return;

    final result =
        await ref.read(marketplaceProvider.notifier).purchase(product.id);

    if (!context.mounted) return;

    if (result != null && result['error'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] as String)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Achat de "${product.title}" effectué !'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}

// ── Product card (horizontal list) ────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onBuy;

  const _ProductCard({required this.product, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    final thumb = product.thumbnailUrl ?? product.firstImage?.url;

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(13)),
            child: thumb != null
                ? CachedNetworkImage(
                    imageUrl: thumb.startsWith('http')
                        ? thumb
                        : '${AppConstants.baseUrl}$thumb',
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _PlaceholderThumb(product.productType),
                    errorWidget: (_, __, ___) =>
                        _PlaceholderThumb(product.productType),
                  )
                : _PlaceholderThumb(product.productType),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.title,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(product.teacherName ?? '',
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textSecondary)),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 11, color: Color(0xFFFFD43B)),
                      Text(' ${product.rating.toStringAsFixed(1)}',
                          style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      if (product.hasDiscount)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('-${product.discountPercent}%',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(product.priceLabel,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onBuy,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        textStyle: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                      child: Text(product.isFree ? 'Gratuit' : 'Acheter'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Product list tile ─────────────────────────────────────────────────────────

class _ProductListTile extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onBuy;

  const _ProductListTile({required this.product, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    final thumb = product.thumbnailUrl ?? product.firstImage?.url;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: thumb != null
                ? CachedNetworkImage(
                    imageUrl: thumb.startsWith('http')
                        ? thumb
                        : '${AppConstants.baseUrl}$thumb',
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        _PlaceholderThumb(product.productType, size: 56),
                    errorWidget: (_, __, ___) =>
                        _PlaceholderThumb(product.productType, size: 56),
                  )
                : _PlaceholderThumb(product.productType, size: 56),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 12, color: Color(0xFFFFD43B)),
                    Text(' ${product.rating.toStringAsFixed(1)}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                    if (product.teacherName != null) ...[
                      const Text(' · ',
                          style: TextStyle(color: AppColors.textHint)),
                      Flexible(
                        child: Text(product.teacherName!,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ],
                ),
                if (product.isPack && product.packItems.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '${product.packItems.length} éléments inclus',
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.primary),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (product.hasDiscount)
                Text('${product.price} FCFA',
                    style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: AppColors.textHint,
                        fontSize: 10)),
              Text(product.priceLabel,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
              const SizedBox(height: 6),
              ElevatedButton(
                onPressed: onBuy,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  textStyle: const TextStyle(fontSize: 11),
                ),
                child: Text(product.isFree ? 'Gratuit' : 'Acheter'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Placeholder thumbnail ─────────────────────────────────────────────────────

class _PlaceholderThumb extends StatelessWidget {
  final String productType;
  final double? size;

  const _PlaceholderThumb(this.productType, {this.size});

  IconData _icon() {
    switch (productType) {
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
      width: size,
      height: size ?? 100,
      color: AppColors.primary.withValues(alpha: 0.10),
      child: Center(
        child: Icon(_icon(), color: AppColors.primary, size: size != null ? 24 : 36),
      ),
    );
  }
}
