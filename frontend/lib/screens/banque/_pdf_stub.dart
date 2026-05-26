// Stub for flutter_pdfview on web — provides the same API surface so the
// code compiles, but these widgets are never rendered (kIsWeb guard in reader).

import 'package:flutter/material.dart';

enum FitPolicy { BOTH, WIDTH, HEIGHT }

typedef PDFViewCreatedCallback = void Function(PDFViewController controller);
typedef RenderCallback = void Function(int? pages);
typedef ErrorCallback = void Function(dynamic error);
typedef PageChangedCallback = void Function(int? page, int? total);

class PDFViewController {
  Future<void> setPage(int page) async {}
}

class PDFView extends StatelessWidget {
  final String? filePath;
  final bool enableSwipe;
  final bool swipeHorizontal;
  final bool autoSpacing;
  final bool pageFling;
  final bool pageSnap;
  final FitPolicy fitPolicy;
  final Color backgroundColor;
  final int defaultPage;
  final PDFViewCreatedCallback? onViewCreated;
  final RenderCallback? onRender;
  final PageChangedCallback? onPageChanged;
  final ErrorCallback? onError;

  const PDFView({
    super.key,
    this.filePath,
    this.enableSwipe = true,
    this.swipeHorizontal = false,
    this.autoSpacing = true,
    this.pageFling = true,
    this.pageSnap = true,
    this.fitPolicy = FitPolicy.BOTH,
    this.backgroundColor = Colors.white,
    this.defaultPage = 0,
    this.onViewCreated,
    this.onRender,
    this.onPageChanged,
    this.onError,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
