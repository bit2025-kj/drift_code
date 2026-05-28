import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nafa_edu/config/theme.dart';
import 'package:nafa_edu/providers/admin_provider.dart';

class TeacherRequestsAdminScreen extends ConsumerStatefulWidget {
  const TeacherRequestsAdminScreen({super.key});

  @override
  ConsumerState<TeacherRequestsAdminScreen> createState() => _TeacherRequestsAdminScreenState();
}

class _TeacherRequestsAdminScreenState extends ConsumerState<TeacherRequestsAdminScreen> {
  String _statusFilter = 'pending';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminTeacherRequestsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _Tab('En attente', 'pending', _statusFilter, () => _setFilter('pending')),
                const SizedBox(width: 8),
                _Tab('Approuvés', 'approved', _statusFilter, () => _setFilter('approved')),
                const SizedBox(width: 8),
                _Tab('Refusés', 'rejected', _statusFilter, () => _setFilter('rejected')),
              ],
            ),
          ),
        ),
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.error != null
                  ? Center(child: Text('Erreur: ${state.error}'))
                  : state.requests.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.school_outlined, size: 52, color: AppColors.textHint),
                              SizedBox(height: 12),
                              Text('Aucune demande', style: TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => ref.read(adminTeacherRequestsProvider.notifier).load(status: _statusFilter),
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: state.requests.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, i) => _RequestCard(request: state.requests[i]),
                          ),
                        ),
        ),
      ],
    );
  }

  void _setFilter(String status) {
    setState(() => _statusFilter = status);
    ref.read(adminTeacherRequestsProvider.notifier).load(status: status);
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final VoidCallback onTap;
  const _Tab(this.label, this.value, this.current, this.onTap);

  @override
  Widget build(BuildContext context) {
    final selected = value == current;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                color: selected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w500)),
      ),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  final TeacherRequestAdmin request;
  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPending = request.status == 'pending';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPending ? AppColors.warning.withValues(alpha: 0.4) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.lycee.withValues(alpha: 0.15),
                child: Text(
                  (request.userName ?? '?').isNotEmpty ? (request.userName ?? '?')[0].toUpperCase() : '?',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.lycee),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.userName ?? 'Utilisateur inconnu',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(request.userEmail ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              _StatusBadge(request.status),
            ],
          ),
          const SizedBox(height: 12),

          // Infos
          _InfoLine('Spécialités', request.specialites),
          if (request.etablissement != null) _InfoLine('Établissement', request.etablissement!),
          _InfoLine('Expérience', '${request.anneesExperience} an(s)'),
          const SizedBox(height: 8),

          // Justification
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('"${request.justification}"',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                maxLines: 3, overflow: TextOverflow.ellipsis),
          ),

          if (request.documentUrl != null) ...[
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.attach_file, size: 14, color: AppColors.primary),
                SizedBox(width: 4),
                Text('Pièce justificative jointe', style: TextStyle(fontSize: 12, color: AppColors.primary)),
              ],
            ),
          ],

          if (request.adminNote != null && request.adminNote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.admin_panel_settings_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text('Note admin : ${request.adminNote}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ),
              ],
            ),
          ],

          if (isPending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approuver'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                    onPressed: () => _review(context, ref, 'approved'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Refuser'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
                    onPressed: () => _review(context, ref, 'rejected'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _review(BuildContext context, WidgetRef ref, String status) async {
    final noteController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(status == 'approved' ? 'Approuver la demande ?' : 'Refuser la demande ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(status == 'approved'
                ? '${request.userName} deviendra professeur vérifié sur Nafa Edu.'
                : 'La demande sera refusée. Vous pouvez ajouter une raison.'),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                hintText: status == 'rejected' ? 'Raison du refus (optionnel)' : 'Note (optionnel)',
                labelText: 'Note',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: status == 'approved' ? AppColors.success : AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: Text(status == 'approved' ? 'Approuver' : 'Refuser'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final err = await ref.read(adminTeacherRequestsProvider.notifier).reviewRequest(
          request.id, status,
          adminNote: noteController.text.isNotEmpty ? noteController.text : null,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err == null
            ? (status == 'approved' ? 'Demande approuvée ✓' : 'Demande refusée')
            : 'Erreur: $err'),
        backgroundColor: err == null
            ? (status == 'approved' ? AppColors.success : AppColors.textSecondary)
            : AppColors.error,
      ));
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'approved' => ('Approuvé', AppColors.success),
      'rejected' => ('Refusé', AppColors.error),
      _ => ('En attente', AppColors.warning),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;
  const _InfoLine(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          children: [
            TextSpan(text: '$label : ', style: const TextStyle(color: AppColors.textSecondary)),
            TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
