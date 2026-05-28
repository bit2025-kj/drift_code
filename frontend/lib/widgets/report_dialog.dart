import 'package:flutter/material.dart';
import 'package:nafa_edu/config/theme.dart';
import 'package:nafa_edu/core/api/api_client.dart';
import 'package:nafa_edu/core/api/api_endpoints.dart';

const _reasons = [
  ('contenu_inapproprie', 'Contenu inapproprié'),
  ('triche', 'Triche / Correction frauduleuse'),
  ('spam', 'Spam ou publicité'),
  ('droits_auteur', 'Violation de droits d\'auteur'),
  ('autre', 'Autre'),
];

/// Ouvre le dialog de signalement et soumet la requête.
/// [contentType] : "document" | "product"
Future<void> showReportDialog(BuildContext context, {
  required String contentType,
  required String contentId,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _ReportSheet(contentType: contentType, contentId: contentId),
  );
}

class _ReportSheet extends StatefulWidget {
  final String contentType;
  final String contentId;
  const _ReportSheet({required this.contentType, required this.contentId});

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  String? _selectedReason;
  final _descController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedReason == null) return;
    setState(() => _isLoading = true);
    try {
      final endpoint = widget.contentType == 'document'
          ? ApiEndpoints.reportDocument(widget.contentId)
          : ApiEndpoints.reportProduct(widget.contentId);
      await ApiClient.instance.dio.post(endpoint, data: {
        'reason': _selectedReason,
        if (_descController.text.isNotEmpty) 'description': _descController.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Signalement envoyé. Merci pour votre contribution.'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().contains('400') ? 'Vous avez déjà signalé ce contenu.' : 'Erreur lors du signalement.'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Signaler ce contenu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Aidez-nous à maintenir la qualité de la plateforme.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ...(_reasons.map((r) {
              final selected = _selectedReason == r.$1;
              return InkWell(
                onTap: () => setState(() => _selectedReason = r.$1),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 20, height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? AppColors.primary : AppColors.border,
                            width: selected ? 6 : 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(r.$2, style: TextStyle(fontSize: 14, color: selected ? AppColors.primary : AppColors.textPrimary, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
                    ],
                  ),
                ),
              );
            })),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Détails supplémentaires (optionnel)',
                labelText: 'Description',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedReason == null || _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                child: _isLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Envoyer le signalement'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
