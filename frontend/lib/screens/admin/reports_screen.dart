import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nafa_edu/config/theme.dart';
import 'package:nafa_edu/providers/admin_provider.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _statusFilter = 'pending';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminReportsProvider);

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
                _Tab('Résolus', 'resolved', _statusFilter, () => _setFilter('resolved')),
                const SizedBox(width: 8),
                _Tab('Rejetés', 'dismissed', _statusFilter, () => _setFilter('dismissed')),
              ],
            ),
          ),
        ),
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.error != null
                  ? Center(child: Text('Erreur: ${state.error}'))
                  : state.reports.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.flag_outlined, size: 52, color: AppColors.textHint),
                              SizedBox(height: 12),
                              Text('Aucun signalement', style: TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => ref.read(adminReportsProvider.notifier).load(status: _statusFilter),
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: state.reports.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, i) => _ReportCard(report: state.reports[i]),
                          ),
                        ),
        ),
      ],
    );
  }

  void _setFilter(String status) {
    setState(() => _statusFilter = status);
    ref.read(adminReportsProvider.notifier).load(status: status);
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
        child: Text(label, style: TextStyle(fontSize: 13, color: selected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

class _ReportCard extends ConsumerWidget {
  final AdminReport report;
  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPending = report.status == 'pending';
    final typeColor = report.contentType == 'document' ? AppColors.college : AppColors.universite;
    final reasonLabel = _reasonLabel(report.reason);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isPending ? AppColors.error.withValues(alpha: 0.3) : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                child: Text(report.contentType == 'document' ? 'Document' : 'Produit',
                    style: TextStyle(fontSize: 11, color: typeColor, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(report.contentTitle ?? report.contentId,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis),
              ),
              if (isPending)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: const Text('En attente', style: TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(report.reporterName ?? 'Anonyme', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(width: 12),
              const Icon(Icons.flag_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(reasonLabel, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          if (report.description != null && report.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('"${report.description}"',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          if (isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Résoudre'),
                    onPressed: () => _showResolveDialog(context, ref, deleteContent: false),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.success, side: const BorderSide(color: AppColors.success)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Suppr. contenu'),
                    onPressed: () => _showResolveDialog(context, ref, deleteContent: true),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _dismiss(context, ref),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.textSecondary, side: const BorderSide(color: AppColors.border)),
                  child: const Text('Rejeter'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showResolveDialog(BuildContext context, WidgetRef ref, {required bool deleteContent}) async {
    final noteController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(deleteContent ? 'Supprimer le contenu ?' : 'Marquer comme résolu ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (deleteContent)
              const Text('Le contenu signalé sera supprimé définitivement.', style: TextStyle(color: AppColors.error)),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(hintText: 'Note admin (optionnel)', labelText: 'Note'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: deleteContent ? AppColors.error : AppColors.success),
            onPressed: () => Navigator.pop(context, true),
            child: Text(deleteContent ? 'Supprimer' : 'Résoudre'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await ref.read(adminReportsProvider.notifier).resolveReport(
          report.id, 'resolved',
          adminNote: noteController.text.isNotEmpty ? noteController.text : null,
          deleteContent: deleteContent,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Signalement traité' : 'Erreur'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ));
    }
  }

  Future<void> _dismiss(BuildContext context, WidgetRef ref) async {
    final ok = await ref.read(adminReportsProvider.notifier).resolveReport(report.id, 'dismissed');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Signalement rejeté' : 'Erreur'),
        backgroundColor: ok ? AppColors.textSecondary : AppColors.error,
      ));
    }
  }

  String _reasonLabel(String reason) {
    const labels = {
      'contenu_inapproprie': 'Contenu inapproprié',
      'triche': 'Triche',
      'spam': 'Spam',
      'droits_auteur': 'Droits d\'auteur',
      'autre': 'Autre',
    };
    return labels[reason] ?? reason;
  }
}
