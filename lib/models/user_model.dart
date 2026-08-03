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
  final GeoPoint? lastKnownLocation; 
  final Timestamp? lastActiveAt; 
  
  final bool acceptedTerms;
  final Timestamp? acceptedTermsDate;
  final String? acceptedTermsIP;
  final String? acceptedTermsVersion; 
  final String verificationStatus;
  final bool isEligibleForTrial;

  final bool isIdentityVerified;
  final Timestamp? lastIdentityVerification;
  final Timestamp? lastBiometricVerification;
  final String? lastSessionSelfieUrl;
  final String? totpSecret; 
  final bool isVipTester; // 🛡️ PUENTE VIP PARA INSPECTORES
  final String driverFranchiseStatus; // 🛡️ ACTIVE, SUSPENDED, REVOKED
  final String? suspensionMessage;    // 🛡️ Motivo de la sanción
  final Timestamp? suspendedUntil;    // 🛡️ Fecha de fin de sanción

  // 💳 PAGOS DIRECTOS (Stripe Connect / Customer) - DOBLE ADN (TEST/LIVE)
  final String? stripeAccountId;
  final String? stripeCustomerId;
  final String? defaultPaymentMethodId;
  
  final String? stripeAccountIdLive;
  final String? stripeCustomerIdLive;
  final String? defaultPaymentMethodIdLive;
  final String? stripeStatusLive; 

  final bool isStripeConnected;
  final bool isStripeVerified;
  final String? stripeStatus;

  final String? driverCategory; 
  final String? recruitedBy;    

  final String? lastIncomingChatId;
  final String? lastIncomingChatTitle;
  final List<String> linkedMessengerIds;

  String? getActiveCustomerId(bool isLive) => isLive ? stripeCustomerIdLive : stripeCustomerId;
  String? getActivePaymentMethodId(bool isLive) {
    final id = isLive ? defaultPaymentMethodIdLive : defaultPaymentMethodId;
    return id;
  }
  String? getActiveAccountId(bool isLive) => isLive ? stripeAccountIdLive : stripeAccountId;

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
    this.totpSecret,
    this.isVipTester = false, // 🛡️ DEFAULT: Nadie es VIP a menos que se diga lo contrario
    this.driverFranchiseStatus = 'ACTIVE',
    this.suspensionMessage,
    this.suspendedUntil,
    this.stripeAccountId,
    this.stripeCustomerId,
    this.defaultPaymentMethodId,
    this.stripeAccountIdLive,
    this.stripeCustomerIdLive,
    this.defaultPaymentMethodIdLive,
    this.stripeStatusLive,
    this.isStripeConnected = false,
    this.isStripeVerified = false,
    this.stripeStatus,
    this.recruitedBy,
    this.driverCategory,
    this.lastIncomingChatId,
    this.lastIncomingChatTitle,
    this.linkedMessengerIds = const [],
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
      lastKnownLocation: data['lastKnownLocation'],
      lastActiveAt: data['lastActiveAt'],
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
      totpSecret: data['totpSecret'],
      isVipTester: data['isVipTester'] ?? false, // 🛡️ CAPTURA DESDE FIRESTORE
      driverFranchiseStatus: data['driverFranchiseStatus'] ?? 'ACTIVE',
      suspensionMessage: data['suspensionMessage'],
      suspendedUntil: data['suspendedUntil'],
      stripeAccountId: data['stripeAccountId'],
      stripeCustomerId: data['stripeCustomerId'],
      defaultPaymentMethodId: data['defaultPaymentMethodId'],
      stripeAccountIdLive: data['stripeAccountIdLive'],
      stripeCustomerIdLive: data['stripeCustomerIdLive'],
      defaultPaymentMethodIdLive: data['defaultPaymentMethodIdLive'],
      stripeStatusLive: data['stripeStatusLive'],
      isStripeConnected: data['isStripeConnected'] ?? false,
      isStripeVerified: data['isStripeVerified'] ?? false,
      stripeStatus: data['stripeStatus'],
      recruitedBy: data['recruitedBy'],
      driverCategory: data['driverCategory'],
      lastIncomingChatId: data['lastIncomingChatId'],
      lastIncomingChatTitle: data['lastIncomingChatTitle'],
      linkedMessengerIds: List<String>.from(data['linkedMessengerIds'] ?? []),
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
      'lastKnownLocation': lastKnownLocation,
      'lastActiveAt': lastActiveAt,
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
      'totpSecret': totpSecret,
      'isVipTester': isVipTester, // 🛡️ SINCRO CON FIRESTORE
      'driverFranchiseStatus': driverFranchiseStatus,
      'suspensionMessage': suspensionMessage,
      'suspendedUntil': suspendedUntil,
      'stripeAccountId': stripeAccountId,
      'stripeCustomerId': stripeCustomerId,
      'defaultPaymentMethodId': defaultPaymentMethodId,
      'stripeAccountIdLive': stripeAccountIdLive,
      'stripeCustomerIdLive': stripeCustomerIdLive,
      'defaultPaymentMethodIdLive': defaultPaymentMethodIdLive,
      'stripeStatusLive': stripeStatusLive,
      'isStripeConnected': isStripeConnected,
      'isStripeVerified': isStripeVerified,
      'stripeStatus': stripeStatus,
      'recruitedBy': recruitedBy,
      'driverCategory': driverCategory,
      'lastIncomingChatId': lastIncomingChatId,
      'lastIncomingChatTitle': lastIncomingChatTitle,
      'linkedMessengerIds': linkedMessengerIds,
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
    GeoPoint? lastKnownLocation,
    Timestamp? lastActiveAt,
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
    String? totpSecret,
    String? stripeAccountId,
    String? stripeCustomerId,
    String? defaultPaymentMethodId,
    String? stripeAccountIdLive,
    String? stripeCustomerIdLive,
    String? defaultPaymentMethodIdLive,
    String? stripeStatusLive,
    bool? isStripeConnected,
    bool? isStripeVerified,
    String? stripeStatus,
    String? recruitedBy,
    String? driverCategory,
    String? lastIncomingChatId,
    String? lastIncomingChatTitle,
    List<String>? linkedMessengerIds,
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
      lastKnownLocation: lastKnownLocation ?? this.lastKnownLocation,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
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
      totpSecret: totpSecret ?? this.totpSecret,
      stripeAccountId: stripeAccountId ?? this.stripeAccountId,
      stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
      defaultPaymentMethodId: defaultPaymentMethodId ?? this.defaultPaymentMethodId,
      stripeAccountIdLive: stripeAccountIdLive ?? this.stripeAccountIdLive,
      stripeCustomerIdLive: stripeCustomerIdLive ?? this.stripeCustomerIdLive,
      defaultPaymentMethodIdLive: defaultPaymentMethodIdLive ?? this.defaultPaymentMethodIdLive,
      stripeStatusLive: stripeStatusLive ?? this.stripeStatusLive,
      isStripeConnected: isStripeConnected ?? this.isStripeConnected,
      isStripeVerified: isStripeVerified ?? this.isStripeVerified,
      stripeStatus: stripeStatus ?? this.stripeStatus,
      recruitedBy: recruitedBy ?? this.recruitedBy,
      driverCategory: driverCategory ?? this.driverCategory,
      lastIncomingChatId: lastIncomingChatId ?? this.lastIncomingChatId,
      lastIncomingChatTitle: lastIncomingChatTitle ?? this.lastIncomingChatTitle,
      linkedMessengerIds: linkedMessengerIds ?? this.linkedMessengerIds,
    );
  }
}
