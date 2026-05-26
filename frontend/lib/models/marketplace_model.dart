class ProductMedia {
  final String url;
  final String type; // "pdf" | "image" | "video"
  final String name;

  const ProductMedia({required this.url, required this.type, this.name = ''});

  factory ProductMedia.fromJson(Map<String, dynamic> j) => ProductMedia(
        url: j['url'] ?? '',
        type: j['type'] ?? 'image',
        name: j['name'] ?? '',
      );

  Map<String, dynamic> toJson() => {'url': url, 'type': type, 'name': name};

  bool get isPdf => type == 'pdf';
  bool get isVideo => type == 'video';
  bool get isImage => type == 'image';
}

class PackItem {
  final String title;
  final String description;
  final String url;
  final String type; // "pdf" | "video" | "image"
  final int order;

  const PackItem({
    required this.title,
    this.description = '',
    required this.url,
    required this.type,
    this.order = 0,
  });

  factory PackItem.fromJson(Map<String, dynamic> j) => PackItem(
        title: j['title'] ?? '',
        description: j['description'] ?? '',
        url: j['url'] ?? '',
        type: j['type'] ?? 'pdf',
        order: j['order'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'url': url,
        'type': type,
        'order': order,
      };
}

class ProductModel {
  final String id;
  final String title;
  final String description;
  final int price;
  final String productType;
  final String? thumbnailUrl;
  final List<ProductMedia> mediaUrls;
  final List<PackItem> packItems;
  final double rating;
  final int ratingsCount;
  final int purchasesCount;
  final bool isFeatured;
  final int discountPercent;
  final String? matiereName;
  final String? classeName;
  final String? levelName;
  final String? teacherName;
  final String? teacherId;
  final bool teacherVerified;
  final int effectivePrice;
  final DateTime createdAt;

  const ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.productType,
    this.thumbnailUrl,
    this.mediaUrls = const [],
    this.packItems = const [],
    required this.rating,
    required this.ratingsCount,
    required this.purchasesCount,
    required this.isFeatured,
    required this.discountPercent,
    this.matiereName,
    this.classeName,
    this.levelName,
    this.teacherName,
    this.teacherId,
    required this.teacherVerified,
    required this.effectivePrice,
    required this.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> j) => ProductModel(
        id: j['id'],
        title: j['title'],
        description: j['description'],
        price: j['price'] ?? 0,
        productType: j['product_type'] ?? '',
        thumbnailUrl: j['thumbnail_url'],
        mediaUrls: (j['media_urls'] as List? ?? [])
            .map((m) => ProductMedia.fromJson(m as Map<String, dynamic>))
            .toList(),
        packItems: (j['pack_items'] as List? ?? [])
            .map((i) => PackItem.fromJson(i as Map<String, dynamic>))
            .toList(),
        rating: (j['rating'] ?? 0).toDouble(),
        ratingsCount: j['ratings_count'] ?? 0,
        purchasesCount: j['purchases_count'] ?? 0,
        isFeatured: j['is_featured'] ?? false,
        discountPercent: j['discount_percent'] ?? 0,
        matiereName: j['matiere_name'],
        classeName: j['classe_name'],
        levelName: j['level_name'],
        teacherName: j['teacher_name'],
        teacherId: j['teacher_id'],
        teacherVerified: j['teacher_verified'] ?? false,
        effectivePrice: j['effective_price'] ?? j['price'] ?? 0,
        createdAt: DateTime.parse(j['created_at']),
      );

  String get priceLabel {
    if (effectivePrice == 0) return 'Gratuit';
    return '${effectivePrice.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]} ',
        )} FCFA';
  }

  bool get hasDiscount => discountPercent > 0;
  bool get isPack => productType == 'pack';
  bool get isFree => effectivePrice == 0;

  ProductMedia? get firstImage =>
      mediaUrls.where((m) => m.isImage).firstOrNull;
  ProductMedia? get firstPdf =>
      mediaUrls.where((m) => m.isPdf).firstOrNull;
}

class TeacherRequestModel {
  final String id;
  final String status; // pending | approved | rejected
  final String bio;
  final String specialites;
  final String? etablissement;
  final int anneesExperience;
  final String justification;
  final String? documentUrl;
  final String? adminNote;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  const TeacherRequestModel({
    required this.id,
    required this.status,
    required this.bio,
    required this.specialites,
    this.etablissement,
    required this.anneesExperience,
    required this.justification,
    this.documentUrl,
    this.adminNote,
    required this.createdAt,
    this.reviewedAt,
  });

  factory TeacherRequestModel.fromJson(Map<String, dynamic> j) =>
      TeacherRequestModel(
        id: j['id'],
        status: j['status'] ?? 'pending',
        bio: j['bio'] ?? '',
        specialites: j['specialites'] ?? '',
        etablissement: j['etablissement'],
        anneesExperience: j['annees_experience'] ?? 0,
        justification: j['justification'] ?? '',
        documentUrl: j['document_url'],
        adminNote: j['admin_note'],
        createdAt: DateTime.parse(j['created_at']),
        reviewedAt: j['reviewed_at'] != null
            ? DateTime.parse(j['reviewed_at'])
            : null,
      );

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}
