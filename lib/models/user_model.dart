import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final Timestamp createdAt;
  final String? invitingMessengerId;
  final String? role;
  final bool setupComplete;
  final bool isMessengerActive;
  final String subscriptionStatus;
  final Timestamp? lastPaymentDate;
  final String? displayName;
  final String? phoneNumber;
  final String? photoURL;
  final String? vehicleDescription;
  final String? mainAddress;
  final List<String> availableServices;
  final double rating;
  final int numberOfRatings;
  final GeoPoint? workZoneCenter;
  final String? subscriptionType;
  final Timestamp? trialEndDate;
  final double maxRadiusMiles;
  final double maxDropoffRadiusMiles;
  final int referralCountLite;
  final int referralCountPro;
  final GeoPoint? lastKnownLocation; 
  final Timestamp? lastActiveAt; // 🛡️ SISTEMA LAD: Para control de inactividad
  
  // 🛡️ BLINDAJE LEGAL LAD DIGITAL SYSTEMS LLC
  final bool acceptedTerms;
  final Timestamp? acceptedTermsDate;
  final String? acceptedTermsIP;
  final String? acceptedTermsVersion; 
  final String verificationStatus; // ACEPTACIÓN_PENDIENTE, IDENTIDAD_PENDIENTE, RECORDS_PENDIENTE, BAJO_REVISIÓN, APROBADO
  final bool isEligibleForTrial;

  // 🛡️ PROTECCIÓN DE IDENTIDAD (Stripe Identity)
  final bool isIdentityVerified;
  final Timestamp? lastIdentityVerification;
  final Timestamp? lastBiometricVerification;
  final String? lastSessionSelfieUrl; // 🤳 NUEVO: Selfie de la jornada actual

  // 💳 PAGOS DIRECTOS (Stripe Connect / Customer)
  final String? stripeAccountId;
  final String? stripeCustomerId; // ID de Cliente para pagos
  final String? defaultPaymentMethodId; // ID del método de pago predeterminado
  final bool isStripeConnected;
  final bool isStripeVerified;
  final String? stripeStatus;

  // ✨ ESTRATEGIA LAD DIGITAL SYSTEMS LLC - BONOS Y RED
  final String? driverCategory; 
  final String? recruitedBy;    

  // 🛡️ REGLAS ANTI-FRAUDE (Bonos de Reclutamiento)
  final bool hasBeenCountedForBonus; 
  final String? lastBonusMonthEarned; 
  final String? currentReferralMonth; 

  final int monthlyDirectNetworkCount;
  final int monthlyBagReferralCount;
  final int monthlyClientReferralCount;

  UserModel({
    required this.uid,
    required this.email,
    required this.createdAt,
    this.invitingMessengerId,
    this.isMessengerActive = false,
    this.subscriptionStatus = 'none',
    this.lastPaymentDate,
    this.role,
    this.setupComplete = false,
    this.displayName,
    this.phoneNumber,
    this.photoURL,
    this.vehicleDescription,
    this.mainAddress,
    this.availableServices = const [],
    this.rating = 5.0,
    this.numberOfRatings = 0,
    this.workZoneCenter,
    this.subscriptionType,
    this.trialEndDate,
    this.maxRadiusMiles = 5.0,
    this.maxDropoffRadiusMiles = 5.0,
    this.referralCountLite = 0,
    this.referralCountPro = 0,
    this.lastKnownLocation,
    this.lastActiveAt,
    this.acceptedTerms = false,
    this.acceptedTermsDate,
    this.acceptedTermsIP,
    this.acceptedTermsVersion,
    this.verificationStatus = 'ACEPTACIÓN_PENDIENTE',
    this.isEligibleForTrial = true,
    this.isIdentityVerified = false,
    this.lastIdentityVerification,
    this.lastBiometricVerification,
    this.lastSessionSelfieUrl,
    this.stripeAccountId,
    this.stripeCustomerId,
    this.defaultPaymentMethodId,
    this.isStripeConnected = false,
    this.isStripeVerified = false,
    this.stripeStatus,
    this.recruitedBy,
    this.driverCategory,
    this.hasBeenCountedForBonus = false,
    this.lastBonusMonthEarned,
    this.currentReferralMonth,
    this.monthlyDirectNetworkCount = 0,
    this.monthlyBagReferralCount = 0,
    this.monthlyClientReferralCount = 0,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      invitingMessengerId: data['invitingMessengerId'],
      isMessengerActive: data['isMessengerActive'] ?? false,
      subscriptionStatus: data['subscriptionStatus'] ?? 'none',
      lastPaymentDate: data['lastPaymentDate'],
      role: data['role'],
      setupComplete: data['setupComplete'] ?? false,
      displayName: data['displayName'] ?? data['name'],
      phoneNumber: data['phoneNumber'],
      photoURL: data['photoURL'],
      vehicleDescription: data['vehicleDescription'],
      mainAddress: data['mainAddress'],
      availableServices: List<String>.from(data['availableServices'] ?? []),
      rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
      numberOfRatings: data['numberOfRatings'] ?? 0,
      workZoneCenter: data['workZoneCenter'],
      subscriptionType: data['subscriptionType'],
      trialEndDate: data['trialEndDate'],
      maxRadiusMiles: (data['maxRadiusMiles'] as num?)?.toDouble() ?? 5.0,
      maxDropoffRadiusMiles: (data['maxDropoffRadiusMiles'] as num?)?.toDouble() ?? 5.0,
      referralCountLite: data['referralCountLite'] ?? 0,
      referralCountPro: data['referralCountPro'] ?? 0,
      lastKnownLocation: data['lastKnownLocation'],
      lastActiveAt: data['lastActiveAt'], // 🛡️ SISTEMA LAD
      acceptedTerms: data['acceptedTerms'] ?? false,
      acceptedTermsDate: data['acceptedTermsDate'],
      acceptedTermsIP: data['acceptedTermsIP'],
      acceptedTermsVersion: data['acceptedTermsVersion'],
      verificationStatus: data['verificationStatus'] ?? 'ACEPTACIÓN_PENDIENTE',
      isEligibleForTrial: data['isEligibleForTrial'] ?? true,
      isIdentityVerified: data['isIdentityVerified'] ?? false,
      lastIdentityVerification: data['lastIdentityVerification'],
      lastBiometricVerification: data['last_biometric_verification'],
      lastSessionSelfieUrl: data['lastSessionSelfieUrl'],
      stripeAccountId: data['stripeAccountId'],
      stripeCustomerId: data['stripeCustomerId'],
      defaultPaymentMethodId: data['defaultPaymentMethodId'],
      isStripeConnected: data['isStripeConnected'] ?? false,
      isStripeVerified: data['isStripeVerified'] ?? false,
      stripeStatus: data['stripeStatus'],
      recruitedBy: data['recruitedBy'],
      driverCategory: data['driverCategory'],
      hasBeenCountedForBonus: data['hasBeenCountedForBonus'] ?? false,
      lastBonusMonthEarned: data['lastBonusMonthEarned'],
      currentReferralMonth: data['currentReferralMonth'],
      monthlyDirectNetworkCount: data['monthlyDirectNetworkCount'] ?? 0,
      monthlyBagReferralCount: data['monthlyBagReferralCount'] ?? 0,
      monthlyClientReferralCount: data['monthlyClientReferralCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'createdAt': createdAt,
      'invitingMessengerId': invitingMessengerId,
      'isMessengerActive': isMessengerActive,
      'subscriptionStatus': subscriptionStatus,
      'lastPaymentDate': lastPaymentDate,
      'role': role,
      'setupComplete': setupComplete,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'vehicleDescription': vehicleDescription,
      'mainAddress': mainAddress,
      'availableServices': availableServices,
      'rating': rating,
      'numberOfRatings': numberOfRatings,
      'workZoneCenter': workZoneCenter,
      'subscriptionType': subscriptionType,
      'trialEndDate': trialEndDate,
      'maxRadiusMiles': maxRadiusMiles,
      'maxDropoffRadiusMiles': maxDropoffRadiusMiles,
      'referralCountLite': referralCountLite,
      'referralCountPro': referralCountPro,
      'lastKnownLocation': lastKnownLocation,
      'lastActiveAt': lastActiveAt, // 🛡️ SISTEMA LAD
      'acceptedTerms': acceptedTerms,
      'acceptedTermsDate': acceptedTermsDate,
      'acceptedTermsIP': acceptedTermsIP,
      'acceptedTermsVersion': acceptedTermsVersion,
      'verificationStatus': verificationStatus,
      'isEligibleForTrial': isEligibleForTrial,
      'isIdentityVerified': isIdentityVerified,
      'lastIdentityVerification': lastIdentityVerification,
      'last_biometric_verification': lastBiometricVerification,
      'lastSessionSelfieUrl': lastSessionSelfieUrl,
      'stripeAccountId': stripeAccountId,
      'stripeCustomerId': stripeCustomerId,
      'defaultPaymentMethodId': defaultPaymentMethodId,
      'isStripeConnected': isStripeConnected,
      'isStripeVerified': isStripeVerified,
      'stripeStatus': stripeStatus,
      'recruitedBy': recruitedBy,
      'driverCategory': driverCategory,
      'hasBeenCountedForBonus': hasBeenCountedForBonus,
      'lastBonusMonthEarned': lastBonusMonthEarned,
      'currentReferralMonth': currentReferralMonth,
      'monthlyDirectNetworkCount': monthlyDirectNetworkCount,
      'monthlyBagReferralCount': monthlyBagReferralCount,
      'monthlyClientReferralCount': monthlyClientReferralCount,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    Timestamp? createdAt,
    String? invitingMessengerId,
    String? role,
    bool? setupComplete,
    bool? isMessengerActive,
    String? subscriptionStatus,
    Timestamp? lastPaymentDate,
    String? displayName,
    String? phoneNumber,
    String? photoURL,
    String? vehicleDescription,
    String? mainAddress,
    List<String>? availableServices,
    double? rating,
    int? numberOfRatings,
    GeoPoint? workZoneCenter,
    String? subscriptionType,
    Timestamp? trialEndDate,
    double? maxRadiusMiles,
    double? maxDropoffRadiusMiles,
    int? referralCountLite,
    int? referralCountPro,
    GeoPoint? lastKnownLocation,
    Timestamp? lastActiveAt, // 🛡️ SISTEMA LAD
    bool? acceptedTerms,
    Timestamp? acceptedTermsDate,
    String? acceptedTermsIP,
    String? acceptedTermsVersion,
    String? verificationStatus,
    bool? isEligibleForTrial,
    bool? isIdentityVerified,
    Timestamp? lastIdentityVerification,
    Timestamp? lastBiometricVerification,
    String? lastSessionSelfieUrl,
    String? stripeAccountId,
    String? stripeCustomerId,
    String? defaultPaymentMethodId,
    bool? isStripeConnected,
    bool? isStripeVerified,
    String? stripeStatus,
    String? recruitedBy,
    String? driverCategory,
    bool? hasBeenCountedForBonus,
    String? lastBonusMonthEarned,
    String? currentReferralMonth,
    int? monthlyDirectNetworkCount,
    int? monthlyBagReferralCount,
    int? monthlyClientReferralCount,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      invitingMessengerId: invitingMessengerId ?? this.invitingMessengerId,
      role: role ?? this.role,
      setupComplete: setupComplete ?? this.setupComplete,
      isMessengerActive: isMessengerActive ?? this.isMessengerActive,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoURL: photoURL ?? this.photoURL,
      vehicleDescription: vehicleDescription ?? this.vehicleDescription,
      mainAddress: mainAddress ?? this.mainAddress,
      availableServices: availableServices ?? this.availableServices,
      rating: rating ?? this.rating,
      numberOfRatings: numberOfRatings ?? this.numberOfRatings,
      workZoneCenter: workZoneCenter ?? this.workZoneCenter,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      trialEndDate: trialEndDate ?? this.trialEndDate,
      maxRadiusMiles: maxRadiusMiles ?? this.maxRadiusMiles,
      maxDropoffRadiusMiles: maxDropoffRadiusMiles ?? this.maxDropoffRadiusMiles,
      referralCountLite: referralCountLite ?? this.referralCountLite,
      referralCountPro: referralCountPro ?? this.referralCountPro,
      lastKnownLocation: lastKnownLocation ?? this.lastKnownLocation,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt, // 🛡️ SISTEMA LAD
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
      acceptedTermsDate: acceptedTermsDate ?? this.acceptedTermsDate,
      acceptedTermsIP: acceptedTermsIP ?? this.acceptedTermsIP,
      acceptedTermsVersion: acceptedTermsVersion ?? this.acceptedTermsVersion,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      isEligibleForTrial: isEligibleForTrial ?? this.isEligibleForTrial,
      isIdentityVerified: isIdentityVerified ?? this.isIdentityVerified,
      lastIdentityVerification: lastIdentityVerification ?? this.lastIdentityVerification,
      lastBiometricVerification: lastBiometricVerification ?? this.lastBiometricVerification,
      lastSessionSelfieUrl: lastSessionSelfieUrl ?? this.lastSessionSelfieUrl,
      stripeAccountId: stripeAccountId ?? this.stripeAccountId,
      stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
      defaultPaymentMethodId: defaultPaymentMethodId ?? this.defaultPaymentMethodId,
      isStripeConnected: isStripeConnected ?? this.isStripeConnected,
      isStripeVerified: isStripeVerified ?? this.isStripeVerified,
      stripeStatus: stripeStatus ?? this.stripeStatus,
      recruitedBy: recruitedBy ?? this.recruitedBy,
      driverCategory: driverCategory ?? this.driverCategory,
      hasBeenCountedForBonus: hasBeenCountedForBonus ?? this.hasBeenCountedForBonus,
      lastBonusMonthEarned: lastBonusMonthEarned ?? this.lastBonusMonthEarned,
      currentReferralMonth: currentReferralMonth ?? this.currentReferralMonth,
      monthlyDirectNetworkCount: monthlyDirectNetworkCount ?? this.monthlyDirectNetworkCount,
      monthlyBagReferralCount: monthlyBagReferralCount ?? this.monthlyBagReferralCount,
      monthlyClientReferralCount: monthlyClientReferralCount ?? this.monthlyClientReferralCount,
    );
  }
}
