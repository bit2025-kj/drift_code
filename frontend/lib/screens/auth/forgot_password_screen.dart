import 'package:flutter/material.dart';
import 'package:nafa_edu/config/theme.dart';
import 'package:nafa_edu/core/api/api_client.dart';
import 'package:nafa_edu/core/api/api_endpoints.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Étapes : 0 = email, 1 = code, 2 = nouveau mdp, 3 = succès
  int _step = 0;
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _obscure = true;

  String? _demoCode; // code visible en mode démo

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('Adresse email invalide');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await ApiClient.instance.dio.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
      );
      setState(() {
        _demoCode = res.data['demo_code']?.toString();
        _step = 1;
      });
    } catch (_) {
      // Afficher quand même l'étape suivante (ne pas révéler si l'email existe)
      setState(() => _step = 1);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.trim().length != 6) {
      _showError('Le code doit contenir 6 chiffres');
      return;
    }
    setState(() => _step = 2);
  }

  Future<void> _resetPassword() async {
    final newPass = _newPassController.text;
    final confirm = _confirmPassController.text;

    if (newPass.length < 8) {
      _showError('Minimum 8 caractères');
      return;
    }
    if (newPass != confirm) {
      _showError('Les mots de passe ne correspondent pas');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiClient.instance.dio.post(ApiEndpoints.resetPassword, data: {
        'email': _emailController.text.trim(),
        'code': _codeController.text.trim(),
        'new_password': newPass,
      });
      setState(() => _step = 3);
    } catch (e) {
      final msg = _extractError(e);
      _showError(msg);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mot de passe oublié')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProgressIndicator(),
              const SizedBox(height: 32),
              if (_step == 0) _buildEmailStep(),
              if (_step == 1) _buildCodeStep(),
              if (_step == 2) _buildNewPasswordStep(),
              if (_step == 3) _buildSuccessStep(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final steps = ['Email', 'Code', 'Nouveau mdp', 'Terminé'];
    return Row(
      children: steps.asMap().entries.map((e) {
        final done = _step > e.key;
        final current = _step == e.key;
        return Expanded(
          child: Row(
            children: [
              if (e.key > 0)
                Expanded(
                  child: Container(
                    height: 2,
                    color: done || current
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done
                      ? AppColors.success
                      : current
                          ? AppColors.primary
                          : AppColors.surfaceVariant,
                  border: current
                      ? null
                      : Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text(
                          '${e.key + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: current
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Réinitialiser le mot de passe',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text(
          'Entrez votre adresse email. Vous recevrez un code de réinitialisation.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 32),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Adresse email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendCode,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Envoyer le code'),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Entrer le code',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(
          'Un code à 6 chiffres a été envoyé à ${_emailController.text}.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        if (_demoCode != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.warning.withValues(alpha:0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 16, color: AppColors.warning),
                const SizedBox(width: 8),
                Text('Code démo : $_demoCode',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 32),
        TextFormField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: const TextStyle(
              fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.w700),
          decoration: const InputDecoration(
            labelText: 'Code à 6 chiffres',
            counterText: '',
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _verifyCode,
            child: const Text('Vérifier le code'),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _step = 0),
            child: const Text('Renvoyer un code'),
          ),
        ),
      ],
    );
  }

  Widget _buildNewPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nouveau mot de passe',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text('Choisissez un nouveau mot de passe sécurisé.',
            style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 32),
        TextField(
          controller: _newPassController,
          obscureText: _obscure,
          decoration: InputDecoration(
            labelText: 'Nouveau mot de passe',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirmPassController,
          obscureText: _obscure,
          decoration: const InputDecoration(
            labelText: 'Confirmer le mot de passe',
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _resetPassword,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Réinitialiser le mot de passe'),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessStep() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Center(
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha:0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle,
                color: AppColors.success, size: 48),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Mot de passe réinitialisé !',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        const Text(
          'Tu peux maintenant te connecter avec ton nouveau mot de passe.',
          style: TextStyle(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Retour à la connexion'),
          ),
        ),
      ],
    );
  }
}
