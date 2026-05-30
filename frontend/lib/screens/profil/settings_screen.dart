import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nafa_edu/config/theme.dart';
import 'package:nafa_edu/core/api/api_client.dart';
import 'package:nafa_edu/core/api/api_endpoints.dart';
import 'package:nafa_edu/providers/auth_provider.dart';
import 'package:nafa_edu/providers/education_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _villeController = TextEditingController();
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _isSavingProfile = false;
  bool _isSavingPassword = false;
  bool _obscureOld = true;
  bool _obscureNew = true;

  int? _selectedLevelId;
  int? _selectedClasseId;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    if (user != null) {
      _nameController.text = user.fullName;
      _phoneController.text = user.phone ?? '';
      _villeController.text = user.ville ?? '';
      _selectedLevelId = user.levelId;
      _selectedClasseId = user.classeId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _villeController.dispose();
    _oldPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isSavingProfile = true);
    try {
      await ApiClient.instance.dio.patch(ApiEndpoints.updateMe, data: {
        'full_name': _nameController.text.trim(),
        if (_phoneController.text.trim().isNotEmpty)
          'phone': _phoneController.text.trim(),
        if (_selectedLevelId != null) 'level_id': _selectedLevelId,
        if (_selectedClasseId != null) 'classe_id': _selectedClasseId,
        if (_villeController.text.trim().isNotEmpty)
          'ville': _villeController.text.trim(),
      });
      await ref.read(authProvider.notifier).refreshUser();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la mise à jour')),
        );
      }
    }
    if (mounted) setState(() => _isSavingProfile = false);
  }

  Future<void> _changePassword() async {
    final old = _oldPassController.text;
    final newP = _newPassController.text;
    final confirm = _confirmPassController.text;

    if (old.isEmpty || newP.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Remplis tous les champs')));
      return;
    }
    if (newP != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Les mots de passe ne correspondent pas')));
      return;
    }
    if (newP.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Minimum 8 caractères requis')));
      return;
    }

    setState(() => _isSavingPassword = true);
    try {
      await ApiClient.instance.dio.patch(ApiEndpoints.changePassword,
          data: {'old_password': old, 'new_password': newP});
      _oldPassController.clear();
      _newPassController.clear();
      _confirmPassController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mot de passe modifié avec succès !'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      final msg = _extractError(e);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    }
    if (mounted) setState(() => _isSavingPassword = false);
  }

  String _extractError(dynamic e) {
    try {
      final data = (e as dynamic).response?.data;
      if (data is Map && data['detail'] != null) {
        return data['detail'].toString();
      }
    } catch (_) {}
    return 'Une erreur est survenue';
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text('Tu devras te reconnecter pour accéder à l\'application.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
    // Guard: widget can be disposed while the dialog was open
    if (confirm != true || !mounted) return;
    await ref.read(authProvider.notifier).logout();
    // Stack cleanup is handled by _AuthGate's ref.listen — no manual pop needed.
  }

  @override
  Widget build(BuildContext context) {
    final levelsAsync = ref.watch(levelsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Mon profil'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: Column(
              children: [
                _field('Nom complet', _nameController,
                    icon: Icons.person_outline),
                const SizedBox(height: 12),
                _field('Téléphone', _phoneController,
                    icon: Icons.phone_outlined,
                    keyboard: TextInputType.phone),
                const SizedBox(height: 12),
                _field('Ville', _villeController,
                    icon: Icons.location_on_outlined),
                const SizedBox(height: 12),
                levelsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox(),
                  data: (levels) => Column(
                    children: [
                      DropdownButtonFormField<int>(
                        initialValue: _selectedLevelId,
                        decoration: const InputDecoration(
                          labelText: 'Niveau scolaire',
                          prefixIcon: Icon(Icons.school_outlined),
                        ),
                        items: levels
                            .map((l) => DropdownMenuItem(
                                value: l.id, child: Text(l.name)))
                            .toList(),
                        onChanged: (v) => setState(() {
                          _selectedLevelId = v;
                          _selectedClasseId = null;
                        }),
                      ),
                      if (_selectedLevelId != null) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          initialValue: _selectedClasseId,
                          decoration: const InputDecoration(
                            labelText: 'Classe',
                            prefixIcon: Icon(Icons.class_outlined),
                          ),
                          items: (levels
                                      .firstWhere(
                                          (l) => l.id == _selectedLevelId,
                                          orElse: () => levels.first)
                                      .classes)
                                  .map((c) => DropdownMenuItem(
                                      value: c.id, child: Text(c.name)))
                                  .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedClasseId = v),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSavingProfile ? null : _saveProfile,
                    child: _isSavingProfile
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Enregistrer les modifications'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle('Sécurité'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: Column(
              children: [
                _passField(
                    'Ancien mot de passe', _oldPassController, _obscureOld,
                    () => setState(() => _obscureOld = !_obscureOld)),
                const SizedBox(height: 12),
                _passField(
                    'Nouveau mot de passe', _newPassController, _obscureNew,
                    () => setState(() => _obscureNew = !_obscureNew)),
                const SizedBox(height: 12),
                _passField('Confirmer le nouveau mot de passe',
                    _confirmPassController, _obscureNew, () {}),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSavingPassword ? null : _changePassword,
                    child: _isSavingPassword
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Changer le mot de passe'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle('Compte'),
          const SizedBox(height: 12),
          Container(
            decoration: _cardDecoration(),
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text('Se déconnecter',
                  style: TextStyle(
                      color: AppColors.error, fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_right,
                  color: AppColors.textHint),
              onTap: _logout,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700));

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      );

  Widget _field(String label, TextEditingController controller,
      {IconData? icon, TextInputType? keyboard}) =>
      TextField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon) : null,
        ),
      );

  Widget _passField(String label, TextEditingController controller,
          bool obscure, VoidCallback toggle) =>
      TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(
                obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
            onPressed: toggle,
          ),
        ),
      );
}
