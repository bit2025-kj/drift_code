import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nafa_edu/config/theme.dart';
import 'package:nafa_edu/providers/education_provider.dart';
import 'package:nafa_edu/providers/marketplace_provider.dart';

const _kTypes = [
  ('cours', 'Cours', Icons.menu_book_outlined),
  ('resume', 'Résumé', Icons.article_outlined),
  ('video', 'Vidéo', Icons.play_circle_outline),
  ('sujet_corrige', 'Sujets & Corrigés', Icons.fact_check_outlined),
  ('pack', 'Pack', Icons.inventory_2_outlined),
];

class CreateProductScreen extends ConsumerStatefulWidget {
  const CreateProductScreen({super.key});

  @override
  ConsumerState<CreateProductScreen> createState() =>
      _CreateProductScreenState();
}

class _CreateProductScreenState extends ConsumerState<CreateProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  String _selectedType = 'cours';
  int _discountPercent = 0;
  int? _matiereId;
  int? _classeId;

  // Uploaded media list: each entry = {url, type, name}
  final List<Map<String, dynamic>> _mediaItems = [];

  // Pack-specific: list of items to build
  final List<_PackItemDraft> _packItems = [];

  bool _isUploading = false;
  bool _isPublishing = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  bool get _isPack => _selectedType == 'pack';

  Future<void> _pickAndUploadFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: [
        'pdf', 'jpg', 'jpeg', 'png', 'webp', 'gif',
        'mp4', 'mov', 'avi', 'mkv'
      ],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    setState(() => _isUploading = true);

    final notifier = ref.read(marketplaceProvider.notifier);
    for (final file in result.files) {
      final uploaded = await notifier.uploadMedia(file);
      if (uploaded != null) {
        setState(() => _mediaItems.add(uploaded));
      }
    }
    setState(() => _isUploading = false);
  }

  Future<void> _addPackItemFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'mp4', 'mov'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    setState(() => _isUploading = true);

    final notifier = ref.read(marketplaceProvider.notifier);
    final uploaded = await notifier.uploadMedia(file);
    if (uploaded != null && mounted) {
      setState(() {
        _packItems.add(_PackItemDraft(
          title: file.name,
          url: uploaded['url'] as String,
          type: uploaded['type'] as String,
          order: _packItems.length,
        ));
      });
    }
    setState(() => _isUploading = false);
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isPack && _packItems.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Un pack doit contenir au moins 2 éléments')),
      );
      return;
    }

    setState(() => _isPublishing = true);

    final price = int.tryParse(_priceCtrl.text.trim()) ?? 0;
    final product = await ref.read(marketplaceProvider.notifier).createProduct(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          price: price,
          productType: _selectedType,
          matiereId: _matiereId,
          classeId: _classeId,
          discountPercent: _discountPercent,
          mediaUrls: _mediaItems,
          packItems: _packItems
              .map((p) => p.toJson())
              .toList(),
        );

    if (mounted) {
      setState(() => _isPublishing = false);
      if (product != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('«${product.title}» publié avec succès !'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, product);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Erreur lors de la publication. Réessayez.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final matieresAsync = ref.watch(matieresProvider);
    final classesAsync = ref.watch(classesByLevelProvider(null));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nouveau produit'),
        elevation: 0,
        actions: [
          if (_isPublishing)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _publish,
              child: const Text('Publier',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      fontSize: 15)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Type selector
            const _SectionTitle('Type de contenu'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _kTypes.map((t) {
                final selected = _selectedType == t.$1;
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = t.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(t.$3,
                            size: 16,
                            color: selected
                                ? Colors.white
                                : AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(t.$2,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? Colors.white
                                    : AppColors.textPrimary)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),
            const _SectionTitle('Informations'),
            const SizedBox(height: 10),

            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Titre *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Titre requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description *',
                alignLabelWithHint: true,
              ),
              validator: (v) => (v == null || v.trim().length < 20)
                  ? 'Minimum 20 caractères'
                  : null,
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Prix (FCFA) *',
                      suffixText: 'FCFA',
                    ),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 0) return 'Prix invalide';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Réduction: $_discountPercent%',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                      Slider(
                        value: _discountPercent.toDouble(),
                        min: 0,
                        max: 70,
                        divisions: 14,
                        label: '$_discountPercent%',
                        activeColor: AppColors.primary,
                        onChanged: (v) =>
                            setState(() => _discountPercent = v.round()),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const _SectionTitle('Classification (optionnel)'),
            const SizedBox(height: 10),

            // Matiere selector
            matieresAsync.when(
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
              data: (matieres) => DropdownButtonFormField<int>(
                initialValue: _matiereId,
                decoration: const InputDecoration(labelText: 'Matière'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Toutes')),
                  ...matieres.map((m) => DropdownMenuItem(
                      value: m.id, child: Text(m.name))),
                ],
                onChanged: (v) => setState(() => _matiereId = v),
              ),
            ),
            const SizedBox(height: 12),

            // Classe selector
            classesAsync.when(
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
              data: (classes) => DropdownButtonFormField<int>(
                initialValue: _classeId,
                decoration: const InputDecoration(labelText: 'Classe'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Toutes')),
                  ...classes.map((c) => DropdownMenuItem(
                      value: c.id, child: Text(c.name))),
                ],
                onChanged: (v) => setState(() => _classeId = v),
              ),
            ),

            const SizedBox(height: 24),

            // ── Media section ─────────────────────────────────────────────
            if (!_isPack) ...[
              Row(
                children: [
                  const _SectionTitle('Fichiers & médias'),
                  const Spacer(),
                  if (_isUploading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary),
                    )
                  else
                    TextButton.icon(
                      onPressed: _pickAndUploadFiles,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Ajouter'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (_mediaItems.isEmpty)
                GestureDetector(
                  onTap: _pickAndUploadFiles,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.border,
                          style: BorderStyle.solid),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.cloud_upload_outlined,
                            size: 40, color: AppColors.textHint),
                        SizedBox(height: 8),
                        Text(
                          'PDF, images, vidéos — plusieurs fichiers acceptés',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._mediaItems.asMap().entries.map((e) =>
                    _MediaItemTile(
                      item: e.value,
                      onRemove: () =>
                          setState(() => _mediaItems.removeAt(e.key)),
                    )),
              const SizedBox(height: 8),
              if (_mediaItems.isNotEmpty)
                TextButton.icon(
                  onPressed: _pickAndUploadFiles,
                  icon: const Icon(Icons.add, size: 16),
                  label:
                      const Text('Ajouter d\'autres fichiers'),
                ),
            ],

            // ── Pack items ────────────────────────────────────────────────
            if (_isPack) ...[
              Row(
                children: [
                  const _SectionTitle('Éléments du pack'),
                  const Spacer(),
                  if (_isUploading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary),
                    )
                  else
                    TextButton.icon(
                      onPressed: _addPackItemFile,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Ajouter'),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Minimum 2 éléments requis pour un pack.',
                style: TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              if (_packItems.isEmpty)
                GestureDetector(
                  onTap: _addPackItemFile,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 40, color: AppColors.textHint),
                        SizedBox(height: 8),
                        Text(
                          'Ajoutez les fichiers qui composent ce pack',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _packItems.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex--;
                      final item = _packItems.removeAt(oldIndex);
                      _packItems.insert(newIndex, item);
                      for (int i = 0; i < _packItems.length; i++) {
                        _packItems[i] = _packItems[i].copyWith(order: i);
                      }
                    });
                  },
                  itemBuilder: (_, i) {
                    final item = _packItems[i];
                    return _PackItemTile(
                      key: ValueKey(item.url),
                      item: item,
                      index: i,
                      onTitleChanged: (t) => setState(
                          () => _packItems[i] = item.copyWith(title: t)),
                      onRemove: () =>
                          setState(() => _packItems.removeAt(i)),
                    );
                  },
                ),
            ],

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isPublishing ? null : _publish,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                child: _isPublishing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Publier le produit'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Media item tile ───────────────────────────────────────────────────────────

class _MediaItemTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onRemove;

  const _MediaItemTile({required this.item, required this.onRemove});

  IconData _icon() {
    switch (item['type']) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'video':
        return Icons.play_circle_outline;
      default:
        return Icons.image_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_icon(), color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? 'Fichier',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  (item['type'] as String? ?? '').toUpperCase(),
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: AppColors.error),
            onPressed: onRemove,
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

// ── Pack item tile ────────────────────────────────────────────────────────────

class _PackItemTile extends StatelessWidget {
  final _PackItemDraft item;
  final int index;
  final ValueChanged<String> onTitleChanged;
  final VoidCallback onRemove;

  const _PackItemTile({
    super.key,
    required this.item,
    required this.index,
    required this.onTitleChanged,
    required this.onRemove,
  });

  IconData _icon() {
    switch (item.type) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'video':
        return Icons.play_circle_outline;
      default:
        return Icons.image_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.drag_handle, color: AppColors.textHint, size: 20),
          const SizedBox(width: 8),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(_icon(), color: AppColors.primary, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Titre de l\'élément',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              controller: TextEditingController(text: item.title),
              onChanged: onTitleChanged,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: AppColors.error),
            onPressed: onRemove,
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

// ── Section title ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style:
            const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      );
}

// ── Pack item draft model ─────────────────────────────────────────────────────

class _PackItemDraft {
  final String title;
  final String url;
  final String type;
  final int order;

  const _PackItemDraft({
    required this.title,
    required this.url,
    required this.type,
    required this.order,
  });

  _PackItemDraft copyWith({String? title, int? order}) => _PackItemDraft(
        title: title ?? this.title,
        url: url,
        type: type,
        order: order ?? this.order,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': '',
        'url': url,
        'type': type,
        'order': order,
      };
}
