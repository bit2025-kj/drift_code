import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nafa_edu/config/theme.dart';
import 'package:nafa_edu/models/marketplace_model.dart';
import 'package:nafa_edu/providers/auth_provider.dart';
import 'package:nafa_edu/providers/marketplace_provider.dart';
import 'package:nafa_edu/screens/marketplace/teacher_dashboard_screen.dart';

class TeacherRequestScreen extends ConsumerStatefulWidget {
  const TeacherRequestScreen({super.key});

  @override
  ConsumerState<TeacherRequestScreen> createState() =>
      _TeacherRequestScreenState();
}

class _TeacherRequestScreenState extends ConsumerState<TeacherRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bioCtrl = TextEditingController();
  final _specialitesCtrl = TextEditingController();
  final _etablissementCtrl = TextEditingController();
  final _justificationCtrl = TextEditingController();
  int _experience = 0;
  bool _isLoading = false;
  bool _submitted = false;
  TeacherRequestModel? _existingRequest;
  PlatformFile? _docFile;
  String? _uploadedDocUrl;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _specialitesCtrl.dispose();
    _etablissementCtrl.dispose();
    _justificationCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    final req = await ref.read(myTeacherRequestProvider.future);
    if (req != null && mounted) {
      setState(() {
        _existingRequest = req;
        _bioCtrl.text = req.bio;
        _specialitesCtrl.text = req.specialites;
        _etablissementCtrl.text = req.etablissement ?? '';
        _justificationCtrl.text = req.justification;
        _experience = req.anneesExperience;
        _uploadedDocUrl = req.documentUrl;
      });
      if (req.isApproved) {
        // Ensure auth state reflects is_teacher = true after approval
        await ref.read(authProvider.notifier).refreshUser();
      }
    }
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _docFile = result.files.first);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final notifier = ref.read(marketplaceProvider.notifier);
    final req = await notifier.submitTeacherRequest(
      bio: _bioCtrl.text.trim(),
      specialites: _specialitesCtrl.text.trim(),
      etablissement: _etablissementCtrl.text.trim().isEmpty
          ? null
          : _etablissementCtrl.text.trim(),
      anneesExperience: _experience,
      justification: _justificationCtrl.text.trim(),
    );

    if (req != null && _docFile != null) {
      await notifier.uploadTeacherDocument(req.id, _docFile!);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (req != null) {
          _existingRequest = req;
          _submitted = true;
        }
      });

      if (req == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'envoi. Réessayez.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted ||
        (_existingRequest != null && _existingRequest!.isPending)) {
      return _buildStatusView('pending');
    }
    if (_existingRequest != null && _existingRequest!.isApproved) {
      return _buildStatusView('approved');
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Devenir enseignant'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF3B5BDB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.school_outlined,
                      color: Colors.white, size: 36),
                  const SizedBox(height: 10),
                  const Text(
                    'Rejoindre Nafa Edu comme enseignant',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Partagez vos connaissances, aidez des milliers d\'élèves et générez des revenus.',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                        height: 1.4),
                  ),
                  if (_existingRequest?.isRejected ?? false)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Demande précédente refusée${_existingRequest!.adminNote != null ? ' : ${_existingRequest!.adminNote}' : ''}. Vous pouvez soumettre une nouvelle demande.',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _sectionTitle('Votre profil'),
            const SizedBox(height: 12),

            _buildField(
              controller: _bioCtrl,
              label: 'Biographie *',
              hint: 'Décrivez votre parcours, votre expertise...',
              maxLines: 4,
              validator: (v) =>
                  (v == null || v.trim().length < 30)
                      ? 'Minimum 30 caractères'
                      : null,
            ),

            const SizedBox(height: 12),

            _buildField(
              controller: _specialitesCtrl,
              label: 'Spécialités / Matières *',
              hint: 'Ex: Mathématiques, Physique-Chimie, SVT...',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
            ),

            const SizedBox(height: 12),

            _buildField(
              controller: _etablissementCtrl,
              label: 'Établissement actuel (optionnel)',
              hint: 'Lycée, université, etc.',
            ),

            const SizedBox(height: 16),

            // Experience slider
            _sectionTitle('Années d\'expérience'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _experience.toDouble(),
                    min: 0,
                    max: 30,
                    divisions: 30,
                    label: '$_experience ans',
                    activeColor: AppColors.primary,
                    onChanged: (v) =>
                        setState(() => _experience = v.round()),
                  ),
                ),
                Container(
                  width: 48,
                  alignment: Alignment.center,
                  child: Text(
                    '$_experience ans',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _sectionTitle('Motivation *'),
            const SizedBox(height: 8),

            _buildField(
              controller: _justificationCtrl,
              label: 'Pourquoi voulez-vous devenir enseignant sur Nafa Edu ?',
              hint: 'Expliquez votre motivation, ce que vous apportez...',
              maxLines: 5,
              validator: (v) =>
                  (v == null || v.trim().length < 50)
                      ? 'Minimum 50 caractères'
                      : null,
            ),

            const SizedBox(height: 16),

            _sectionTitle('Pièce justificative (optionnel)'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDocument,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _docFile != null
                        ? AppColors.primary
                        : AppColors.border,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _docFile != null
                          ? Icons.check_circle
                          : Icons.upload_file_outlined,
                      color: _docFile != null
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _docFile?.name ??
                            _uploadedDocUrl ??
                            'Diplôme, attestation... (PDF ou image)',
                        style: TextStyle(
                          fontSize: 13,
                          color: _docFile != null
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.attach_file,
                        size: 18, color: AppColors.textHint),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Soumettre ma candidature'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusView(String status) {
    final isPending = status == 'pending';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Ma candidature')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isPending) ...[
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🏫', style: TextStyle(fontSize: 40)),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 16, color: Color(0xFF7C3AED)),
                      SizedBox(width: 6),
                      Text(
                        'Badge Professeur Vérifié obtenu',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7C3AED),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else
                const Icon(Icons.hourglass_top, size: 72, color: AppColors.warning),
              const SizedBox(height: 20),
              Text(
                isPending ? 'Candidature en cours d\'examen' : 'Candidature approuvée !',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                isPending
                    ? 'Notre équipe examine votre demande. Vous serez notifié dès qu\'une décision est prise.'
                    : 'Félicitations ! Vous êtes maintenant enseignant vérifié sur Nafa Edu. Vous pouvez créer et vendre vos cours.',
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (!isPending) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.dashboard_rounded),
                    label: const Text('Accéder à mon tableau de bord'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const TeacherDashboardScreen()),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      );

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }
}
