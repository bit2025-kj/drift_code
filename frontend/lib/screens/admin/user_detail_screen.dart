import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nafa_edu/config/theme.dart';
import 'package:nafa_edu/providers/admin_provider.dart';

class UserDetailScreen extends ConsumerWidget {
  final String userId;
  const UserDetailScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(adminUserDetailProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text('Détail utilisateur')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (user) => _UserDetailBody(user: user, ref: ref),
      ),
    );
  }
}

class _UserDetailBody extends StatelessWidget {
  final AdminUserDetail user;
  final WidgetRef ref;
  const _UserDetailBody({required this.user, required this.ref});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    Text(user.email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    if (user.phone != null) Text(user.phone!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Tags
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              _Tag(user.isActive ? 'Actif' : 'Désactivé', user.isActive ? AppColors.success : AppColors.error),
              if (user.isAdmin) const _Tag('Administrateur', AppColors.error),
              if (user.isTeacher) const _Tag('Professeur', AppColors.lycee),
              if (user.ville != null) _Tag(user.ville!, AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 24),

          // Stats personnelles
          const Text('Statistiques', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _InfoRow(Icons.star_outline, 'Points', '${user.points}'),
          _InfoRow(Icons.account_balance_wallet_outlined, 'Solde', '${user.walletBalance} FCFA'),
          _InfoRow(Icons.local_fire_department_outlined, 'Série actuelle', '${user.currentStreak} jours'),
          _InfoRow(Icons.calendar_today_outlined, 'Jours actifs', '${user.activeDays}'),
          _InfoRow(Icons.access_time_outlined, 'Inscrit le', _formatDate(user.createdAt)),
          const Divider(height: 32),

          // Activité
          const Text('Activité', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(children: [
            _ActivityCard('Téléchargements', user.downloadsCount, Icons.download_outlined, AppColors.college),
            const SizedBox(width: 10),
            _ActivityCard('Favoris', user.favoritesCount, Icons.bookmark_outline, AppColors.primary),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _ActivityCard('Quiz', user.quizSessionsCount, Icons.quiz_outlined, AppColors.lycee),
            const SizedBox(width: 10),
            _ActivityCard('Forum', user.forumPostsCount, Icons.forum_outlined, AppColors.success),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _ActivityCard('Achats', user.purchasesCount, Icons.shopping_bag_outlined, AppColors.universite),
            const Expanded(child: SizedBox()),
          ]),
          const SizedBox(height: 32),

          // Action
          if (!user.isAdmin)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: user.isActive ? AppColors.error : AppColors.success,
                ),
                icon: Icon(user.isActive ? Icons.block : Icons.check_circle_outline),
                label: Text(user.isActive ? 'Désactiver le compte' : 'Réactiver le compte'),
                onPressed: () => _toggleStatus(context, ref),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _toggleStatus(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(user.isActive ? 'Désactiver le compte ?' : 'Réactiver le compte ?'),
        content: Text(user.isActive
            ? 'L\'utilisateur ne pourra plus se connecter.'
            : 'L\'utilisateur pourra à nouveau se connecter.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: user.isActive ? AppColors.error : AppColors.success),
            onPressed: () => Navigator.pop(context, true),
            child: Text(user.isActive ? 'Désactiver' : 'Réactiver'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await ref.read(adminUsersProvider.notifier).setUserStatus(user.id, !user.isActive);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Statut mis à jour' : 'Erreur lors de la mise à jour'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ));
      if (ok) Navigator.pop(context);
    }
  }

  String _formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Text('$label :', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(width: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _ActivityCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
