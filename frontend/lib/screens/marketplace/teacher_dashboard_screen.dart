import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nafa_edu/config/constants.dart';
import 'package:nafa_edu/config/theme.dart';
import 'package:nafa_edu/models/marketplace_model.dart';
import 'package:nafa_edu/providers/marketplace_provider.dart';
import 'package:nafa_edu/screens/marketplace/create_product_screen.dart';
import 'package:nafa_edu/screens/marketplace/product_detail_screen.dart';

class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myProductsAsync = ref.watch(myProductsProvider);
    final myPurchasesAsync = ref.watch(myTeacherSalesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mon tableau de bord'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
            tooltip: 'Nouveau produit',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CreateProductScreen()),
              );
              ref.invalidate(myProductsProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myProductsProvider);
          ref.invalidate(myTeacherSalesProvider);
        },
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Stats row
            myPurchasesAsync.when(
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
              data: (purchases) => _StatsRow(purchaseCount: purchases.length),
            ),
            const SizedBox(height: 20),

            // My products
            Row(
              children: [
                const Text('Mes produits',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CreateProductScreen()),
                    );
                    ref.invalidate(myProductsProvider);
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
            const SizedBox(height: 10),

            myProductsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child:
                      CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              error: (e, _) => Center(
                child: Text('Erreur: $e',
                    style:
                        const TextStyle(color: AppColors.textSecondary)),
              ),
              data: (products) {
                if (products.isEmpty) {
                  return _EmptyProducts(
                    onAdd: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CreateProductScreen()),
                      );
                      ref.invalidate(myProductsProvider);
                    },
                  );
                }
                return Column(
                  children: products
                      .map((p) => _MyProductTile(
                            product: p,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      ProductDetailScreen(product: p)),
                            ),
                            onDelete: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Supprimer ce produit ?'),
                                  content: Text(p.title),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Annuler')),
                                    ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.error),
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('Supprimer')),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await ref
                                    .read(marketplaceProvider.notifier)
                                    .deleteMyProduct(p.id);
                                ref.invalidate(myProductsProvider);
                              }
                            },
                          ))
                      .toList(),
                );
              },
            ),

            const SizedBox(height: 24),
            const Text('Mes ventes récentes',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),

            myPurchasesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (_, __) => const SizedBox(),
              data: (purchases) {
                if (purchases.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                        child: Text('Aucune vente pour l\'instant.',
                            style: TextStyle(
                                color: AppColors.textSecondary))),
                  );
                }
                return Column(
                  children: purchases
                      .take(10)
                      .map((p) => _SaleTile(sale: p))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int purchaseCount;
  const _StatsRow({required this.purchaseCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          icon: Icons.shopping_bag_outlined,
          label: 'Ventes totales',
          value: '$purchaseCount',
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: Icons.star_outline,
          label: 'Statut',
          value: 'Enseignant',
          color: AppColors.success,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ── My product tile ───────────────────────────────────────────────────────────

class _MyProductTile extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _MyProductTile({
    required this.product,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final thumb = product.thumbnailUrl ?? product.firstImage?.url;

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              borderRadius: BorderRadius.circular(8),
              child: thumb != null
                  ? CachedNetworkImage(
                      imageUrl: thumb.startsWith('http')
                          ? thumb
                          : '${AppConstants.baseUrl}$thumb',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _thumb(),
                      errorWidget: (_, __, ___) => _thumb(),
                    )
                  : _thumb(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.title,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      _TypeChip(product.productType),
                      const SizedBox(width: 8),
                      Text(product.priceLabel,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                  Text(
                    '${product.purchasesCount} ventes · ⭐ ${product.rating.toStringAsFixed(1)}',
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 20, color: AppColors.error),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumb() => Container(
        width: 50,
        height: 50,
        color: AppColors.primary.withValues(alpha: 0.1),
        child: Icon(_typeIcon(), color: AppColors.primary, size: 22),
      );

  IconData _typeIcon() {
    switch (product.productType) {
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
}

// ── Sale tile ─────────────────────────────────────────────────────────────────

class _SaleTile extends StatelessWidget {
  final Map<String, dynamic> sale;
  const _SaleTile({required this.sale});

  @override
  Widget build(BuildContext context) {
    final date = sale['purchased_at'] != null
        ? DateTime.tryParse(sale['purchased_at'].toString())
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.shopping_bag_outlined,
              size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              sale['title'] ?? 'Produit',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${sale['amount_paid'] ?? 0} FCFA',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success),
              ),
              if (date != null)
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textSecondary),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyProducts extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyProducts({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined,
                size: 56, color: AppColors.textHint),
            const SizedBox(height: 16),
            const Text('Aucun produit publié',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text('Publiez votre premier cours ou pack !',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Créer un produit'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Type chip ─────────────────────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  final String type;
  const _TypeChip(this.type);

  String _label() {
    switch (type) {
      case 'pack':
        return 'Pack';
      case 'cours':
        return 'Cours';
      case 'resume':
        return 'Résumé';
      case 'video':
        return 'Vidéo';
      case 'sujet_corrige':
        return 'Sujets';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _label(),
        style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: AppColors.primary),
      ),
    );
  }
}
