import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nafa_edu/config/theme.dart';
import 'package:nafa_edu/providers/admin_provider.dart';
import 'package:nafa_edu/screens/admin/user_detail_screen.dart';

class UsersListScreen extends ConsumerStatefulWidget {
  const UsersListScreen({super.key});

  @override
  ConsumerState<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends ConsumerState<UsersListScreen> {
  final _searchController = TextEditingController();
  bool? _filterActive;
  bool? _filterTeacher;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    ref.read(adminUsersProvider.notifier).load(
          q: _searchController.text.isNotEmpty ? _searchController.text : null,
          isActive: _filterActive,
          isTeacher: _filterTeacher,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminUsersProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher par nom ou email...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); _applyFilters(); })
                      : null,
                ),
                onSubmitted: (_) => _applyFilters(),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(label: 'Tous', selected: _filterActive == null && _filterTeacher == null, onTap: () { setState(() { _filterActive = null; _filterTeacher = null; }); _applyFilters(); }),
                    const SizedBox(width: 8),
                    _FilterChip(label: 'Actifs', selected: _filterActive == true, onTap: () { setState(() { _filterActive = _filterActive == true ? null : true; }); _applyFilters(); }),
                    const SizedBox(width: 8),
                    _FilterChip(label: 'Désactivés', selected: _filterActive == false, onTap: () { setState(() { _filterActive = _filterActive == false ? null : false; }); _applyFilters(); }),
                    const SizedBox(width: 8),
                    _FilterChip(label: 'Profs', selected: _filterTeacher == true, onTap: () { setState(() { _filterTeacher = _filterTeacher == true ? null : true; }); _applyFilters(); }),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.error != null
                  ? Center(child: Text('Erreur: ${state.error}'))
                  : state.users.isEmpty
                      ? const Center(child: Text('Aucun utilisateur trouvé'))
                      : RefreshIndicator(
                          onRefresh: () => ref.read(adminUsersProvider.notifier).load(),
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: state.users.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, i) => _UserTile(user: state.users[i]),
                          ),
                        ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, color: selected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

class _UserTile extends ConsumerWidget {
  final AdminUserItem user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserDetailScreen(userId: user.id))),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: user.isAdmin ? AppColors.error.withValues(alpha: 0.15) : AppColors.primary.withValues(alpha: 0.12),
              child: Text(user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                  style: TextStyle(fontWeight: FontWeight.w700, color: user.isAdmin ? AppColors.error : AppColors.primary)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis)),
                      if (user.isAdmin) const _Badge('Admin', AppColors.error),
                      if (user.isTeacher) const _Badge('Prof', AppColors.lycee),
                    ],
                  ),
                  Text(user.email, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: user.isActive ? AppColors.success.withValues(alpha: 0.12) : AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(user.isActive ? 'Actif' : 'Désactivé',
                      style: TextStyle(fontSize: 11, color: user.isActive ? AppColors.success : AppColors.error, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 4),
                Text('${user.points} pts', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
    );
  }
}
