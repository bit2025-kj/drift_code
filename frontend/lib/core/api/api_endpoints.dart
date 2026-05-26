class ApiEndpoints {
  ApiEndpoints._();

  // ── Auth ─────────────────────────────────────────────────────────────────────
  static const register = '/auth/register';
  static const login = '/auth/login';
  static const refresh = '/auth/refresh';
  static const logout = '/auth/logout';
  static const changePassword = '/auth/change-password';
  static const forgotPassword = '/auth/forgot-password';
  static const resetPassword = '/auth/reset-password';

  // ── Users ────────────────────────────────────────────────────────────────────
  static const me = '/users/me';
  static const updateMe = '/users/me';
  static const uploadAvatar = '/users/me/avatar';
  static const myStats = '/users/me/stats';
  static const myActivity = '/users/me/activity';
  static const myBadges = '/users/me/badges';
  static const myFavorites = '/users/me/favorites';
  static const myDownloads = '/users/me/downloads';
  static const myPurchases = '/users/me/purchases';
  static const leaderboard = '/users/leaderboard';

  // ── Education ────────────────────────────────────────────────────────────────
  static const levels = '/education/levels';
  static const classes = '/education/classes';
  static const matieres = '/education/matieres';
  static const typesExamens = '/education/types-examens';
  static const years = '/education/annees';

  // ── Documents ────────────────────────────────────────────────────────────────
  static const documents = '/documents';
  static const trending = '/documents/trending';
  static const uploadDocument = '/documents/upload';
  static String document(String id) => '/documents/$id';
  static String downloadDocument(String id) => '/documents/$id/download';
  static String favoriteDocument(String id) => '/documents/$id/favorite';
  static String rateDocument(String id) => '/documents/$id/rate';

  // ── Quiz ─────────────────────────────────────────────────────────────────────
  static const quizList = '/quiz';
  static const generateQuiz = '/quiz/generate';
  static const generateQuizFromFile = '/quiz/generate-from-file';
  static const generateQuizFromProfile = '/quiz/generate-from-profile';
  static const quizHistory = '/quiz/history';
  static const quizStats = '/quiz/stats';
  static const mySessions = '/quiz/my-sessions';
  static String quizDetail(String id) => '/quiz/$id';
  static String submitSession(String id) => '/quiz/sessions/$id/submit';
  static String sessionResult(String id) => '/quiz/sessions/$id/result';

  // ── Forum ────────────────────────────────────────────────────────────────────
  static const forumStats = '/forum/stats';
  static const forumCategories = '/forum/categories';
  static const forumUploadMedia = '/forum/upload-media';
  static const discussions = '/forum';
  static String discussion(String id) => '/forum/$id';
  static String discussionComments(String id) => '/forum/$id/comments';
  static String likeDiscussion(String id) => '/forum/$id/like';
  static String likeComment(String did, String cid) => '/forum/$did/comments/$cid/like';
  static String markSolution(String did, String cid) => '/forum/$did/comments/$cid/solution';

  // ── Marketplace ──────────────────────────────────────────────────────────────
  static const products = '/marketplace';
  static const featuredProducts = '/marketplace/featured';
  static const myMarketplacePurchases = '/marketplace/me/purchases';
  static const marketplaceUploadMedia = '/marketplace/upload-media';
  static const teacherRequest = '/marketplace/teacher-request';
  static const myTeacherRequest = '/marketplace/teacher-request/me';
  static String teacherRequestDocument(String id) => '/marketplace/teacher-request/$id/document';
  static const myProducts = '/marketplace/me/products';
  static String myProduct(String id) => '/marketplace/me/products/$id';
  static const adminTeacherRequests = '/marketplace/admin/teacher-requests';
  static String adminReviewRequest(String id) => '/marketplace/admin/teacher-requests/$id';
  static String productDetail(String id) => '/marketplace/$id';
  static String purchaseProduct(String id) => '/marketplace/$id/purchase';
  static String rateProduct(String id) => '/marketplace/$id/rate';

  // ── AI Chat & Conversations ───────────────────────────────────────────────
  static const aiChat = '/ai/chat';
  static const aiUploadDocument = '/ai/upload-document';
  static const conversations = '/ai/conversations';
  static String conversation(String id) => '/ai/conversations/$id';
  static String sendMessage(String threadId) => '/ai/conversations/$threadId/messages';
  static String uploadToConversation(String threadId) => '/ai/conversations/$threadId/upload';
  static String conversationDocuments(String threadId) => '/ai/conversations/$threadId/documents';

  // ── Sync offline ─────────────────────────────────────────────────────────────
  static const syncPing = '/sync/ping';
  static const syncState = '/sync/state';
  static const syncBatch = '/sync/batch';
  static const syncFavorites = '/sync/favorites';
  static const syncDownloads = '/sync/downloads';
}
