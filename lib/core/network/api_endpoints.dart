class ApiEndpoints {
  // Authentication (/api/auth)
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String refresh = '/api/auth/refresh';
  static const String logout = '/api/auth/logout';
  static const String sendEmailVerification = '/api/auth/email-verification/send';
  static const String confirmEmailVerification = '/api/auth/email-verification/confirm';
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String resetPassword = '/api/auth/reset-password';
  static const String changePassword = '/api/auth/change-password';
  static const String googleLogin = '/api/auth/google';

  // User Profile
  static const String userMe = '/api/v1/users/me';

  // Seller Onboarding
  static const String sellerOnboardingMe = '/api/v1/seller-onboarding/me';
  static const String sellerOnboardingSendCode = '/api/v1/seller-onboarding/email/send-code';
  static const String sellerOnboardingVerify = '/api/v1/seller-onboarding/email/verify';

  // Seller Verification & eKYC
  static const String sellerVerifications = '/api/v1/seller-verifications';
  static const String sellerVerificationsMe = '/api/v1/seller-verifications/me';
  static const String sellerVerificationsHistory = '/api/v1/seller-verifications/me/history';
  static String sellerVerificationResubmit(String id) => '/api/v1/seller-verifications/$id/resubmit';
  static const String vnptEkycVerify = '/api/v1/ekyc/verify';

  // Media
  static const String mediaUpload = '/api/v1/media/upload';
  static const String mediaUploadMultiple = '/api/v1/media/upload-multiple';
  static const String mediaUploadVideo = '/api/v1/media/upload-video';

  // Seller Credits
  static const String sellerCredits = '/api/v1/seller/credits';
  static const String sellerCreditPricing = '/api/v1/seller/credit-pricing';
  static const String sellerCreditPurchases = '/api/v1/seller/credit-purchases';
  static const String sellerCreditLedger = '/api/v1/seller/credit-ledger';
  static const String topupPackages = '/api/v1/topup/packages';
  static const String topupMyCredit = '/api/v1/topup/my-credit';
  static String topupPurchase(String packageId) => '/api/v1/topup/purchase/$packageId';

  // Categories & Items
  static const String categories = '/api/v1/categories';
  static String itemsByCategory(String categoryId) => '/api/v1/items/category/$categoryId';

  // Posts & Listings
  static const String posts = '/api/v1/posts';
  static const String postsInit = '/api/v1/posts/init';
  static const String myPosts = '/api/v1/posts/my-posts';
  static String postDetail(String postId) => '/api/v1/posts/$postId';
  static String postDraft(String postId) => '/api/v1/posts/$postId/draft';
  static String postFinalizeChat(String sessionId) => '/api/v1/posts/finalize-chat/$sessionId';
  static String postRegenerateChat(String sessionId) => '/api/v1/posts/regenerate-chat/$sessionId';
  static String postSuggestTitle(String postId) => '/api/v1/posts/$postId/suggest-title';
  static String postAiPriceEstimation(String postId) => '/api/v1/posts/$postId/ai-price-estimation';
  static String postShippingPackage(String postId) => '/api/v1/posts/$postId/shipping-package';
  static String postSubmit(String postId) => '/api/v1/posts/submit/$postId';
  static String postDelete(String postId) => '/api/v1/posts/$postId';
  static String postBoost(String postId) => '/api/v1/posts/$postId/boost';

  // AI Chat
  static const String aiChat = '/api/v1/ai/chat';

  // Negotiations (Bargain)
  static const String negotiationsSeller = '/api/v1/negotiations/seller';
  static const String negotiationsBuyer = '/api/v1/negotiations/buyer';
  static String negotiationAccept(String id) => '/api/v1/negotiations/$id/accept';
  static String negotiationReject(String id) => '/api/v1/negotiations/$id/reject';
  static String negotiationCancel(String id) => '/api/v1/negotiations/$id/cancel';

  // Chat
  static const String chatRooms = '/api/v1/chats';
  static String chatRoomMessages(String roomId) => '/api/v1/chats/$roomId/messages';
  static String chatGetOrCreateRoom(String postId) => '/api/v1/chats/rooms?postId=$postId';

  // Shipping & Addresses
  static const String reverseGeocode = '/api/v1/shipping/reverse-geocode';
  static const String shippingPickupAddress = '/api/v1/shipping/pickup-address';
  static const String shippingCities = '/api/v1/shipping/cities';
  static const String shippingQuotes = '/api/v1/shipping/quotes';

  // Orders
  static const String ordersSeller = '/api/v1/orders/seller';
  static const String ordersBuyer = '/api/v1/orders/buyer';
  static String orderShipments(String orderId) => '/api/v1/orders/$orderId/shipments';
  static String orderCommission(String orderId) => '/api/v1/orders/$orderId/commission';
  static String orderSettlement(String orderId) => '/api/v1/orders/$orderId/settlement';
  static String orderPayment(String orderId) => '/api/v1/orders/$orderId/payment';

  // Shipments & Tracking
  static String shipmentTracking(String shipmentId) => '/api/v1/shipments/$shipmentId/tracking';
  static String shipmentEvents(String shipmentId) => '/api/v1/shipments/$shipmentId/events';
  static String shipmentSync(String shipmentId) => '/api/v1/shipments/$shipmentId/sync';
  static String shipmentCancel(String shipmentId) => '/api/v1/shipments/$shipmentId/cancel';

  // Inspection & Tamper Seal
  static const String inspectionMySellerOrders = '/api/v1/inspection/my-seller-orders';
  static const String inspectionMyBuyerOrders = '/api/v1/inspection/my-buyer-orders';
  static String inspectionOrder(String orderId) => '/api/v1/inspection/orders/$orderId';
  static String inspectionRespond(String orderId) => '/api/v1/inspection/requests/$orderId/respond';
  static String inspectionPayFee(String orderId) => '/api/v1/inspection/orders/$orderId/pay-fee';
  static String inspectionConfirmPurchase(String orderId) => '/api/v1/inspection/orders/$orderId/confirm-purchase';
  static String inspectionSchedule(String orderId) => '/api/v1/inspector/orders/$orderId/schedule';
  static String inspectionStart(String orderId) => '/api/v1/inspector/orders/$orderId/start';
  static String inspectionSealLookup(String sealId) => '/api/v1/inspection/seal/$sealId';
  static const String inspectionSealScan = '/api/v1/inspection/seal/scan';

  // Wallets & Payout
  static const String walletMe = '/api/v1/wallets/me';
  static const String walletTransactions = '/api/v1/wallets/me/transactions';
  static const String walletDepositRequest = '/api/v1/wallets/deposit-request';
  static const String walletWithdrawals = '/api/v1/wallets/withdrawals';

  // Notifications
  static const String notifications = '/api/v1/notifications';
  static const String notificationsUnreadCount = '/api/v1/notifications/unread-count';
  static String notificationMarkRead(String id) => '/api/v1/notifications/$id/read';
  static const String notificationReadAll = '/api/v1/notifications/read-all';
  static String notificationDelete(String id) => '/api/v1/notifications/$id';
  static const String notificationClearRead = '/api/v1/notifications/clear-read';
  static const String notificationClearAll = '/api/v1/notifications/clear-all';
  static const String notificationDevices = '/api/v1/notifications/devices';
  static String notificationDeviceDelete(String token) => '/api/v1/notifications/devices/$token';
}
