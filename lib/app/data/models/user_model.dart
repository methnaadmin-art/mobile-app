// Safe parsers — backend may return String or num for numeric fields
int _safeInt(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

double? _safeDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

class UserModel {
  final String id;
  final String? username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String role;
  final String status;
  final bool emailVerified;
  final bool phoneVerified;
  final bool selfieVerified;
  final String? selfieUrl;
  final String? documentUrl;
  final bool isShadowBanned;
  final int trustScore;
  final int flagCount;
  final int deviceCount;
  final bool notificationsEnabled;
  final String? lastKnownIp;
  final DateTime? lastLoginAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ProfileModel? profile;
  final List<PhotoModel>? photos;
  final SubscriptionModel? subscription;
  final int sentComplimentsCount;
  final int profileBoostsCount;

  UserModel({
    required this.id,
    this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.role = 'user',
    this.status = 'active',
    this.emailVerified = false,
    this.phoneVerified = false,
    this.selfieVerified = false,
    this.selfieUrl,
    this.documentUrl,
    this.isShadowBanned = false,
    this.trustScore = 100,
    this.flagCount = 0,
    this.deviceCount = 0,
    this.notificationsEnabled = true,
    this.lastKnownIp,
    this.lastLoginAt,
    required this.createdAt,
    required this.updatedAt,
    this.profile,
    this.photos,
    this.subscription,
    this.sentComplimentsCount = 0,
    this.profileBoostsCount = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      username: json['username'],
      email: json['email'] ?? '',
      firstName: json['firstName'],
      lastName: json['lastName'],
      phone: json['phone'],
      role: json['role'] ?? 'user',
      status: json['status'] ?? 'active',
      emailVerified: json['emailVerified'] ?? false,
      phoneVerified: json['phoneVerified'] ?? false,
      selfieVerified: json['selfieVerified'] ?? false,
      selfieUrl: json['selfieUrl'],
      documentUrl: json['documentUrl'],
      isShadowBanned: json['isShadowBanned'] ?? false,
      trustScore: _safeInt(json['trustScore'], 100),
      flagCount: _safeInt(json['flagCount']),
      deviceCount: _safeInt(json['deviceCount']),
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      lastKnownIp: json['lastKnownIp'],
      lastLoginAt: json['lastLoginAt'] != null ? DateTime.parse(json['lastLoginAt']) : null,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      profile: json['profile'] != null ? ProfileModel.fromJson(json['profile']) : null,
      photos: json['photos'] != null
          ? (json['photos'] as List).map((p) => PhotoModel.fromJson(p)).toList()
          : null,
      subscription: json['subscription'] != null
          ? SubscriptionModel.fromJson(json['subscription'])
          : null,
      sentComplimentsCount: _safeInt(json['sentComplimentsCount']),
      profileBoostsCount: _safeInt(json['profileBoostsCount']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'role': role,
        'status': status,
        'emailVerified': emailVerified,
        'phoneVerified': phoneVerified,
        'selfieVerified': selfieVerified,
        'selfieUrl': selfieUrl,
        'documentUrl': documentUrl,
        'isShadowBanned': isShadowBanned,
        'trustScore': trustScore,
        'flagCount': flagCount,
        'deviceCount': deviceCount,
        'notificationsEnabled': notificationsEnabled,
        'lastKnownIp': lastKnownIp,
        'lastLoginAt': lastLoginAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'profile': profile?.toJson(),
        'photos': photos?.map((p) => p.toJson()).toList(),
        'subscription': subscription?.toJson(),
        'sentComplimentsCount': sentComplimentsCount,
        'profileBoostsCount': profileBoostsCount,
      };

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();
  String get displayName => username ?? fullName;
  String? get mainPhotoUrl => photos?.isNotEmpty == true
      ? (photos!.firstWhere((p) => p.isMain, orElse: () => photos!.first)).url
      : null;
  bool get isOnline => status == 'active' && lastLoginAt != null &&
      DateTime.now().difference(lastLoginAt!).inMinutes < 5;
  bool get isTrialActive {
    final trialDuration = const Duration(days: 2);
    final now = DateTime.now();
    return now.difference(createdAt) < trialDuration;
  }

  Duration get trialTimeRemaining {
    final trialDuration = const Duration(days: 2);
    final expiration = createdAt.add(trialDuration);
    final remaining = expiration.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get isPremium => (subscription != null && subscription!.isPremium) || isTrialActive;
}

class ProfileModel {
  final String? id;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? bio;
  final String? ethnicity;
  final String? nationality;
  final List<String>? nationalities;
  final String? city;
  final String? country;
  final double? latitude;
  final double? longitude;

  // Religious & Cultural
  final String? religiousLevel;
  final String? sect;
  final String? prayerFrequency;
  final String? marriageIntention;
  final String? maritalStatus;
  final String? secondWifePreference;
  final String? intentMode;

  // Education & Career
  final String? education;
  final String? educationDetails;
  final String? jobTitle;
  final String? company;

  // Physical
  final int? height;
  final int? weight;

  // Lifestyle
  final String? livingSituation;
  final String? communicationStyle;
  final String? alcohol;
  final String? dietary;
  final String? hijabStatus;
  final String? workoutFrequency;
  final String? sleepSchedule;
  final String? socialMediaUsage;
  final bool? hasPets;
  final String? petPreference;

  // Health
  final bool? vaccinationStatus;
  final String? bloodType;
  final String? healthNotes;

  // Family
  final String? familyPlans;
  final List<String>? familyValues;
  final bool? hasChildren;
  final int? numberOfChildren;
  final bool? wantsChildren;
  final bool? willingToRelocate;

  // Preferences & Hobbies
  final List<String>? interests;
  final List<String>? languages;
  final List<String>? favoriteMusic;
  final List<String>? favoriteMovies;
  final List<String>? favoriteBooks;
  final List<String>? travelPreferences;

  // About Partner
  final String? aboutPartner;

  // Privacy
  final bool showAge;
  final bool showDistance;
  final bool showOnlineStatus;
  final bool showLastSeen;

  // Scoring
  final int profileCompletionPercentage;
  final int activityScore;
  final bool isComplete;

  ProfileModel({
    this.id,
    this.gender,
    this.dateOfBirth,
    this.bio,
    this.ethnicity,
    this.nationality,
    this.nationalities,
    this.city,
    this.country,
    this.latitude,
    this.longitude,
    this.religiousLevel,
    this.sect,
    this.prayerFrequency,
    this.marriageIntention,
    this.maritalStatus,
    this.secondWifePreference,
    this.intentMode,
    this.education,
    this.educationDetails,
    this.jobTitle,
    this.company,
    this.height,
    this.weight,
    this.livingSituation,
    this.communicationStyle,
    this.alcohol,
    this.dietary,
    this.hijabStatus,
    this.workoutFrequency,
    this.sleepSchedule,
    this.socialMediaUsage,
    this.hasPets,
    this.petPreference,
    this.vaccinationStatus,
    this.bloodType,
    this.healthNotes,
    this.familyPlans,
    this.familyValues,
    this.hasChildren,
    this.numberOfChildren,
    this.wantsChildren,
    this.willingToRelocate,
    this.interests,
    this.languages,
    this.favoriteMusic,
    this.favoriteMovies,
    this.favoriteBooks,
    this.travelPreferences,
    this.aboutPartner,
    this.showAge = true,
    this.showDistance = true,
    this.showOnlineStatus = true,
    this.showLastSeen = true,
    this.profileCompletionPercentage = 0,
    this.activityScore = 0,
    this.isComplete = false,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'],
      gender: json['gender'],
      dateOfBirth: json['dateOfBirth'] != null ? DateTime.parse(json['dateOfBirth']) : null,
      bio: json['bio'],
      ethnicity: json['ethnicity'],
      nationality: json['nationality'],
      nationalities: json['nationalities'] != null ? List<String>.from(json['nationalities']) : null,
      city: json['city'],
      country: json['country'],
      latitude: _safeDouble(json['latitude']),
      longitude: _safeDouble(json['longitude']),
      religiousLevel: json['religiousLevel'],
      sect: json['sect'],
      prayerFrequency: json['prayerFrequency'],
      marriageIntention: json['marriageIntention'],
      maritalStatus: json['maritalStatus'],
      secondWifePreference: json['secondWifePreference'],
      intentMode: json['intentMode'],
      education: json['education'],
      educationDetails: json['educationDetails'],
      jobTitle: json['jobTitle'],
      company: json['company'],
      height: json['height'] != null ? _safeInt(json['height']) : null,
      weight: json['weight'] != null ? _safeInt(json['weight']) : null,
      livingSituation: json['livingSituation'],
      communicationStyle: json['communicationStyle'],
      alcohol: json['alcohol'],
      dietary: json['dietary'],
      hijabStatus: json['hijabStatus'],
      workoutFrequency: json['workoutFrequency'],
      sleepSchedule: json['sleepSchedule'],
      socialMediaUsage: json['socialMediaUsage'],
      hasPets: json['hasPets'],
      petPreference: json['petPreference'],
      vaccinationStatus: json['vaccinationStatus'],
      bloodType: json['bloodType'],
      healthNotes: json['healthNotes'],
      familyPlans: json['familyPlans'],
      familyValues: json['familyValues'] != null ? List<String>.from(json['familyValues']) : null,
      hasChildren: json['hasChildren'],
      numberOfChildren: json['numberOfChildren'] != null ? _safeInt(json['numberOfChildren']) : null,
      wantsChildren: json['wantsChildren'],
      willingToRelocate: json['willingToRelocate'],
      interests: json['interests'] != null ? List<String>.from(json['interests']) : null,
      languages: json['languages'] != null ? List<String>.from(json['languages']) : null,
      favoriteMusic: json['favoriteMusic'] != null ? List<String>.from(json['favoriteMusic']) : null,
      favoriteMovies: json['favoriteMovies'] != null ? List<String>.from(json['favoriteMovies']) : null,
      favoriteBooks: json['favoriteBooks'] != null ? List<String>.from(json['favoriteBooks']) : null,
      travelPreferences: json['travelPreferences'] != null ? List<String>.from(json['travelPreferences']) : null,
      aboutPartner: json['aboutPartner'],
      showAge: json['showAge'] ?? true,
      showDistance: json['showDistance'] ?? true,
      showOnlineStatus: json['showOnlineStatus'] ?? true,
      showLastSeen: json['showLastSeen'] ?? true,
      profileCompletionPercentage: _safeInt(json['profileCompletionPercentage']),
      activityScore: _safeInt(json['activityScore']),
      isComplete: json['isComplete'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (gender != null) 'gender': gender,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
      if (bio != null) 'bio': bio,
      if (ethnicity != null) 'ethnicity': ethnicity,
      if (nationality != null) 'nationality': nationality,
      if (nationalities != null) 'nationalities': nationalities,
      if (city != null) 'city': city,
      if (country != null) 'country': country,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (religiousLevel != null) 'religiousLevel': religiousLevel,
      if (sect != null) 'sect': sect,
      if (prayerFrequency != null) 'prayerFrequency': prayerFrequency,
      if (marriageIntention != null) 'marriageIntention': marriageIntention,
      if (maritalStatus != null) 'maritalStatus': maritalStatus,
      if (secondWifePreference != null) 'secondWifePreference': secondWifePreference,
      if (intentMode != null) 'intentMode': intentMode,
      if (education != null) 'education': education,
      if (educationDetails != null) 'educationDetails': educationDetails,
      if (jobTitle != null) 'jobTitle': jobTitle,
      if (company != null) 'company': company,
      if (height != null) 'height': height,
      if (weight != null) 'weight': weight,
      if (livingSituation != null) 'livingSituation': livingSituation,
      if (communicationStyle != null) 'communicationStyle': communicationStyle,
      if (alcohol != null) 'alcohol': alcohol,
      if (dietary != null) 'dietary': dietary,
      if (hijabStatus != null) 'hijabStatus': hijabStatus,
      if (workoutFrequency != null) 'workoutFrequency': workoutFrequency,
      if (sleepSchedule != null) 'sleepSchedule': sleepSchedule,
      if (socialMediaUsage != null) 'socialMediaUsage': socialMediaUsage,
      if (hasPets != null) 'hasPets': hasPets,
      if (petPreference != null) 'petPreference': petPreference,
      if (vaccinationStatus != null) 'vaccinationStatus': vaccinationStatus,
      if (bloodType != null) 'bloodType': bloodType,
      if (healthNotes != null) 'healthNotes': healthNotes,
      if (familyPlans != null) 'familyPlans': familyPlans,
      if (familyValues != null) 'familyValues': familyValues,
      if (hasChildren != null) 'hasChildren': hasChildren,
      if (numberOfChildren != null) 'numberOfChildren': numberOfChildren,
      if (wantsChildren != null) 'wantsChildren': wantsChildren,
      if (willingToRelocate != null) 'willingToRelocate': willingToRelocate,
      if (interests != null) 'interests': interests,
      if (languages != null) 'languages': languages,
      if (favoriteMusic != null) 'favoriteMusic': favoriteMusic,
      if (favoriteMovies != null) 'favoriteMovies': favoriteMovies,
      if (favoriteBooks != null) 'favoriteBooks': favoriteBooks,
      if (travelPreferences != null) 'travelPreferences': travelPreferences,
      if (aboutPartner != null) 'aboutPartner': aboutPartner,
      'showAge': showAge,
      'showDistance': showDistance,
      'showOnlineStatus': showOnlineStatus,
      'showLastSeen': showLastSeen,
      'profileCompletionPercentage': profileCompletionPercentage,
      'activityScore': activityScore,
      'isComplete': isComplete,
    };
  }

  int get age => dateOfBirth != null
      ? DateTime.now().difference(dateOfBirth!).inDays ~/ 365
      : 0;
}

class PhotoModel {
  final String id;
  final String url;
  final String? publicId;
  final bool isMain;
  final bool isSelfieVerification;
  final int order;
  final String moderationStatus;
  final String? moderationNote;
  final DateTime? createdAt;

  PhotoModel({
    required this.id,
    required this.url,
    this.publicId,
    this.isMain = false,
    this.isSelfieVerification = false,
    this.order = 0,
    this.moderationStatus = 'approved',
    this.moderationNote,
    this.createdAt,
  });

  factory PhotoModel.fromJson(Map<String, dynamic> json) {
    return PhotoModel(
      id: json['id'] ?? '',
      url: json['url'] ?? '',
      publicId: json['publicId'],
      isMain: json['isMain'] ?? false,
      isSelfieVerification: json['isSelfieVerification'] ?? false,
      order: _safeInt(json['order']),
      moderationStatus: json['moderationStatus'] ?? 'approved',
      moderationNote: json['moderationNote'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'isMain': isMain,
        'order': order,
      };
}

class SubscriptionModel {
  final String id;
  final String plan;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? paymentReference;

  SubscriptionModel({
    required this.id,
    required this.plan,
    required this.status,
    this.startDate,
    this.endDate,
    this.paymentReference,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] ?? '',
      plan: json['plan'] ?? 'free',
      status: json['status'] ?? 'active',
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      paymentReference: json['paymentReference'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'plan': plan,
        'status': status,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'paymentReference': paymentReference,
      };

  bool get isActive => status == 'active';
  bool get isExpired => endDate != null && DateTime.now().isAfter(endDate!);
  bool get isPremium => plan != 'free' && isActive && !isExpired;
  bool get isGold => plan == 'gold' && isActive && !isExpired;
}
