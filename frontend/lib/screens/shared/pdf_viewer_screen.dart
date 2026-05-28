import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:nafa_edu/config/constants.dart';
import 'package:nafa_edu/config/theme.dart';
import 'package:nafa_edu/core/api/api_client.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

class PdfViewerScreen extends StatefulWidget {
  final String url;
  final String title;
  const PdfViewerScreen({super.key, required this.url, this.title = 'Document'});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  Uint8List? _bytes;
  bool _loading = true;
  String? _error;
  double _progress = 0;
  final _ctrl = PdfViewerController();
  int _currentPage = 1;
  int _totalPages = 0;

  String get _fullUrl => widget.url.startsWith('http')
      ? widget.url
      : '${AppConstants.baseUrl}${widget.url}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; _progress = 0; });
    try {
      // Use authenticated client for backend URLs, plain Dio for external (Cloudinary)
      final dio = _fullUrl.startsWith(AppConstants.baseUrl)
          ? ApiClient.instance.dio
          : Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 60),
            ));
      final response = await dio.get<List<int>>(
        _fullUrl,
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: (rx, total) {
          if (total > 0 && mounted) setState(() => _progress = rx / total);
        },
      );
      if (!mounted) return;
      setState(() {
        _bytes = Uint8List.fromList(response.data!);
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      final code = e.response?.statusCode;
      setState(() {
        _loading = false;
        _error = code == 404
            ? 'Fichier introuvable.\nIl a peut-être été supprimé du serveur.'
            : 'Erreur réseau (${code ?? 'connexion'}).\nVérifiez votre connexion.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _openExternal() async {
    try {
      await launchUrl(Uri.parse(_fullUrl), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D23),
        foregroundColor: Colors.white,
        title: Text(widget.title,
            style: const TextStyle(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        actions: [
          if (_totalPages > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text('$_currentPage / $_totalPages',
                    style: const TextStyle(fontSize: 12, color: Colors.white54)),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded, size: 20),
            tooltip: 'Ouvrir dans le navigateur',
            onPressed: _openExternal,
          ),
        ],
      ),
      body: _loading ? _buildLoader() : _error != null ? _buildError() : _buildPdf(),
    );
  }

  Widget _buildLoader() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          width: 240,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _progress > 0 ? _progress : null,
              backgroundColor: Colors.white12,
              color: AppColors.primary,
              minHeight: 5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _progress > 0 ? 'Chargement ${(_progress * 100).toInt()} %…' : 'Chargement du document…',
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
      ]),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.white38, size: 56),
          const SizedBox(height: 16),
          Text(_error!,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Réessayer'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _openExternal,
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('Ouvrir'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _buildPdf() {
    return SfPdfViewer.memory(
      _bytes!,
      controller: _ctrl,
      canShowScrollHead: false,
      canShowScrollStatus: false,
      onDocumentLoaded: (d) => setState(() => _totalPages = d.document.pages.count),
      onPageChanged: (d) => setState(() => _currentPage = d.newPageNumber),
    );
  }
}
