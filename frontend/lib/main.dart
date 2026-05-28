import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafa_edu/app.dart';
import 'package:nafa_edu/services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Désactiver le téléchargement de polices à l'exécution pour éviter les
  // crashs hors ligne. Les polices sont servies depuis le cache appareil ou
  // la police système est utilisée en fallback.
  GoogleFonts.config.allowRuntimeFetching = false;

  // Initialiser le service de synchronisation et surveillance réseau
  await SyncService.instance.init();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const ProviderScope(child: NafaEduApp()));
}
