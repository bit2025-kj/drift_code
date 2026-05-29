import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nafa_edu/providers/auth_provider.dart';
import 'package:nafa_edu/screens/auth/login_screen.dart';

/// Checks if the user is authenticated. 
/// If not, displays the login screen modally.
/// Returns true if the user is authenticated (or successfully logs in).
Future<bool> requireAuth(BuildContext context, WidgetRef ref) async {
  final auth = ref.read(authProvider);
  if (auth.status == AuthStatus.authenticated) {
    return true;
  }
  // Show confirmation dialog
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Connexion requise'),
      content: const Text('Veuillez créer un compte ou vous connecter pour continuer.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Se connecter'),
        ),
      ],
    ),
  );

  if (confirm != true) {
    return false;
  }

  if (!context.mounted) return false;

  // Navigate to login screen
  final result = await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const LoginScreen(isModal: true)),
  );
  
  // Returns true if login was successful
  return result == true;
}
