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
  
  // Navigate to login screen
  final result = await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const LoginScreen(isModal: true)),
  );
  
  // Returns true if login was successful
  return result == true;
}
