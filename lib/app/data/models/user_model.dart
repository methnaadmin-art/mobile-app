// Safe parsers — backend may return String or num for numeric fields
int _safeInt(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

String _safeString(dynamic v, [String fallback = '']) {
  if (v is String) return v;
  if (v == null) return fallback;
  return v.toString();
}

bool _safeBool(dynamic v, [bool fallback = false]) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final normalized = v.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }
  }
  return fallback;
}

DateTime? _safeDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

String? _firstNonEmptyString(Iterable<dynamic> values) {
  for (final value in values) {
    if (value is Map || value is Iterable) continue;
    final asString = _safeString(value).trim();
    if (asString.isNotEmpty) return asString;
  }
  return null;
}

double? _safeDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
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
  final String? documentType;
  final bool documentVerified;
  final DateTime? documentVerifiedAt;
  final String? documentRejectionReason;
  final bool isShadowBanned;
  final int trustScore;
  final String backgroundCheckStatus;
  final DateTime? backgroundCheckedAt;
  final int flagCount;
  final int deviceCount;
  final bool notificationsEnabled;
  final String? lastKnownIp;
  final DateTime? lastLoginAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ProfileModel? profile;
  final List<PhotoModel>? photos;
  final String? fallbackPhotoUrl;
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
    this.documentType,
    this.documentVerified = false,
    this.documentVerifiedAt,
    this.documentRejectionReason,
    this.isShadowBanned = false,
    this.trustScore = 100,
    this.backgroundCheckStatus = 'not_started',
    this.backgroundCheckedAt,
    this.flagCount = 0,
    this.deviceCount = 0,
    this.notificationsEnabled = true,
    this.lastKnownIp,
    this.lastLoginAt,
    required this.createdAt,
    required this.updatedAt,
    this.profile,
    this.photos,
    this.fallbackPhotoUrl,
    this.subscription,
    this.sentComplimentsCount = 0,
    this.profileBoostsCount = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final createdAt =
        _safeDate(json['createdAt']) ??
        _safeDate(json['created_at']) ??
        DateTime.now();
    final updatedAt =
        _safeDate(json['updatedAt']) ??
        _safeDate(json['updated_at']) ??
        createdAt;
    final rawPresence = json['presence'];
    final presenceMap = rawPresence is Map
      ? Map<String, dynamic>.from(rawPresence)
      : null;
    final activityMap = json['activity'] is Map
      ? Map<String, dynamic>.from(json['activity'] as Map)
      : null;
    final lastSeenAt =
        _safeDate(json['lastLoginAt']) ??
        _safeDate(json['lastSeenAt']) ??
        _safeDate(json['lastActiveAt']) ??
      _safeDate(json['lastActive']) ??
      _safeDate(json['activeAt']) ??
      _safeDate(json['active_at']) ??
      _safeDate(json['seenAt']) ??
      _safeDate(json['seen_at']) ??
      _safeDate(json['onlineAt']) ??
      _safeDate(json['online_at']) ??
      _safeDate(json['activityAt']) ??
      _safeDate(json['activity']) ??
      _safeDate(json['activity_at']) ??
      _safeDate(presenceMap?['lastLoginAt']) ??
      _safeDate(presenceMap?['last_login_at']) ??
      _safeDate(presenceMap?['lastSeenAt']) ??
      _safeDate(presenceMap?['last_seen_at']) ??
      _safeDate(presenceMap?['lastActiveAt']) ??
      _safeDate(presenceMap?['lastActive']) ??
      _safeDate(presenceMap?['last_active_at']) ??
      _safeDate(presenceMap?['seenAt']) ??
      _safeDate(presenceMap?['activeAt']) ??
      _safeDate(activityMap?['lastSeenAt']) ??
      _safeDate(activityMap?['lastActiveAt']) ??
      _safeDate(activityMap?['lastActive']) ??
      _safeDate(activityMap?['activeAt']) ??
        _safeDate(json['lastSeen']) ??
        _safeDate(json['last_seen']);
    final rawStatus = _firstNonEmptyString([
      json['status'],
      if (rawPresence is Map) rawPresence['status'],
      if (rawPresence is Map) rawPresence['state'],
      if (rawPresence is! Map) rawPresence,
      json['state'],
    ]);
    final explicitOnline =
        _safeBool(json['isOnline']) ||
        _safeBool(json['online']) ||
        _safeBool(json['is_online']) ||
      _safeBool(json['isLiveToday']) ||
      _safeBool(json['liveToday']) ||
      _safeBool(json['is_live_today']) ||
        _safeBool(json['presenceOnline']) ||
      _safeBool(presenceMap?['isOnline']) ||
      _safeBool(presenceMap?['online']) ||
      _safeBool(activityMap?['isOnline']) ||
      _safeBool(activityMap?['online']) ||
        (rawStatus?.toLowerCase() == 'online');
    final profileMap = _asMap(json['profile']);
    final mediaMap = _asMap(json['media']);
    final mainPhotoMap = _asMap(json['mainPhoto']);
    final avatarMap = _asMap(json['avatar']);
    final locationMap = _asMap(json['location']);
    final photosJson =
        json['photos'] ??
        json['images'] ??
        json['profilePhotos'] ??
        json['pictures'] ??
        json['gallery'] ??
        json['mediaPhotos'] ??
        json['media_photos'] ??
        profileMap?['photos'] ??
        profileMap?['images'] ??
        profileMap?['profilePhotos'] ??
        mediaMap?['photos'] ??
        mediaMap?['images'];
    final parsedPhotos = () {
      if (photosJson is List) {
        return photosJson
            .map((entry) {
              if (entry is Map) {
                return Map<String, dynamic>.from(entry);
              }
              if (entry is String && entry.trim().isNotEmpty) {
                return <String, dynamic>{'url': entry.trim()};
              }
              return null;
            })
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
      }
      if (photosJson is Map) {
        final photosMap = Map<String, dynamic>.from(photosJson);
        final nested =
            photosMap['items'] ??
            photosMap['photos'] ??
            photosMap['results'] ??
            photosMap['data'] ??
            photosMap['gallery'];
        if (nested is List) {
          return nested
              .map((entry) {
                if (entry is Map) {
                  return Map<String, dynamic>.from(entry);
                }
                if (entry is String && entry.trim().isNotEmpty) {
                  return <String, dynamic>{'url': entry.trim()};
                }
                return null;
              })
              .whereType<Map<String, dynamic>>()
              .toList(growable: false);
        }

        final singleUrl = _firstNonEmptyString([
          photosMap['url'],
          photosMap['secureUrl'],
          photosMap['secure_url'],
          photosMap['photoUrl'],
          photosMap['photo_url'],
          photosMap['imageUrl'],
          photosMap['image_url'],
          photosMap['avatarUrl'],
          photosMap['avatar_url'],
          photosMap['avatar'],
        ]);
        if (singleUrl != null) {
          return <Map<String, dynamic>>[
            <String, dynamic>{'url': singleUrl, 'isMain': true},
          ];
        }
      }
      return null;
    }();
    final List<dynamic>? parsedPhotoList = parsedPhotos is List
        ? parsedPhotos
        : null;
    final profileFromTopLevel = () {
      if (profileMap != null) return profileMap;

      final synthetic = <String, dynamic>{};

      void assign(String targetKey, List<dynamic> candidates) {
        dynamic value;
        for (final candidate in candidates) {
          if (candidate != null) {
            value = candidate;
            break;
          }
        }
        if (value == null) return;
        synthetic[targetKey] = value;
      }

      assign('bio', [json['bio']]);
      assign('gender', [json['gender']]);
      assign('dateOfBirth', [json['dateOfBirth'], json['date_of_birth']]);
      assign('city', [json['city'], locationMap?['city']]);
      assign('country', [json['country'], locationMap?['country']]);
      assign('latitude', [json['latitude'], locationMap?['latitude']]);
      assign('longitude', [json['longitude'], locationMap?['longitude']]);
      assign('religiousLevel', [json['religiousLevel'], json['religious_level']]);
      assign('prayerFrequency', [json['prayerFrequency'], json['prayer_frequency']]);
      assign('marriageIntention', [json['marriageIntention'], json['marriage_intention']]);
      assign('intentMode', [json['intentMode'], json['intent_mode']]);
      assign('education', [json['education']]);
      assign('educationDetails', [json['educationDetails'], json['education_details']]);
      assign('jobTitle', [json['jobTitle'], json['job_title'], json['profession']]);
      assign('company', [json['company']]);
      assign('height', [json['height']]);
      assign('weight', [json['weight']]);
      assign('livingSituation', [json['livingSituation'], json['living_situation']]);
      assign('familyPlans', [json['familyPlans'], json['family_plans']]);
      assign('familyValues', [json['familyValues'], json['family_values']]);
      assign('nationality', [json['nationality']]);
      assign('nationalities', [json['nationalities']]);
      assign('interests', [json['interests']]);
      assign('languages', [json['languages']]);
      assign('aboutPartner', [json['aboutPartner'], json['about_partner']]);
      assign('showAge', [json['showAge']]);
      assign('showDistance', [json['showDistance']]);
      assign('showOnlineStatus', [json['showOnlineStatus']]);
      assign('showLastSeen', [json['showLastSeen']]);

      if (synthetic.isEmpty) {
        return null;
      }
      return synthetic;
    }();
    final trustSafety =
        json['trustSafety'] is Map ? (json['trustSafety'] as Map) : null;
    final verification =
        json['verification'] is Map ? (json['verification'] as Map) : null;
    final selfieStatus = _firstNonEmptyString([
      json['selfieStatus'],
      json['selfie_status'],
      json['verificationStatus'],
      json['verification_status'],
      verification?['selfieStatus'],
      verification?['selfie_status'],
      trustSafety?['selfieStatus'],
      trustSafety?['selfie_status'],
      verification?['status'],
      trustSafety?['status'],
    ])?.trim().toLowerCase();
    final selfieStatusVerified =
      selfieStatus == 'verified' ||
      selfieStatus == 'approved' ||
      selfieStatus == 'matched' ||
      selfieStatus == 'match' ||
      selfieStatus == 'complete' ||
      selfieStatus == 'completed' ||
      selfieStatus == 'success' ||
      selfieStatus == 'selfie_verified' ||
      selfieStatus == 'selfie-verified';

    return UserModel(
      id:
          _firstNonEmptyString([
            json['id'],
            json['_id'],
            json['userId'],
            json['user_id'],
            json['participantId'],
            json['participant_id'],
            json['memberId'],
            json['member_id'],
            json['targetUserId'],
            json['target_user_id'],
          ]) ??
          '',
      username: _firstNonEmptyString([json['username'], json['userName']]),
      email: _safeString(json['email']),
      firstName: _firstNonEmptyString([json['firstName'], json['first_name']]),
      lastName: _firstNonEmptyString([json['lastName'], json['last_name']]),
      phone: _firstNonEmptyString([json['phone'], json['phoneNumber']]),
      role: _safeString(json['role'], 'user'),
      status: explicitOnline ? 'online' : _safeString(rawStatus, 'active'),
      emailVerified: _safeBool(json['emailVerified']),
      phoneVerified: _safeBool(json['phoneVerified']),
      selfieVerified: _safeBool(
        json['selfieVerified'] ??
            json['selfie_verified'] ??
            json['isSelfieVerified'] ??
            trustSafety?['selfieVerified'] ??
            trustSafety?['selfie_verified'] ??
            verification?['selfieVerified'] ??
            verification?['selfie_verified'],
        selfieStatusVerified,
      ),
      selfieUrl: _firstNonEmptyString([
        json['selfieUrl'],
        json['selfie_url'],
        json['selfiePhotoUrl'],
        json['selfie'],
        trustSafety?['selfieUrl'],
        trustSafety?['selfie_url'],
        verification?['selfieUrl'],
        verification?['selfie_url'],
      ]),
      documentUrl: _firstNonEmptyString([
        json['documentUrl'],
        json['document_url'],
      ]),
      documentType: _firstNonEmptyString([
        json['documentType'],
        json['document_type'],
      ]),
      documentVerified: _safeBool(json['documentVerified']),
      documentVerifiedAt: _safeDate(
        _firstNonEmptyString([
          json['documentVerifiedAt'],
          json['document_verified_at'],
        ]),
      ),
      documentRejectionReason: _firstNonEmptyString([
        json['documentRejectionReason'],
        json['document_rejection_reason'],
      ]),
      isShadowBanned: _safeBool(json['isShadowBanned']),
      trustScore: _safeInt(json['trustScore'], 100),
      backgroundCheckStatus: _firstNonEmptyString([
            json['backgroundCheckStatus'],
            json['background_check_status'],
            if (json['trustSafety'] is Map)
              (json['trustSafety'] as Map)['backgroundCheckStatus'],
            if (json['trustSafety'] is Map)
              (json['trustSafety'] as Map)['background_check_status'],
          ]) ??
          'not_started',
      backgroundCheckedAt: _safeDate(
        _firstNonEmptyString([
          json['backgroundCheckedAt'],
          json['background_checked_at'],
          if (json['trustSafety'] is Map)
            (json['trustSafety'] as Map)['backgroundCheckedAt'],
          if (json['trustSafety'] is Map)
            (json['trustSafety'] as Map)['background_checked_at'],
        ]),
      ),
      flagCount: _safeInt(json['flagCount']),
      deviceCount: _safeInt(json['deviceCount']),
      notificationsEnabled: _safeBool(json['notificationsEnabled'], true),
      lastKnownIp: _safeString(json['lastKnownIp']).isNotEmpty
          ? _safeString(json['lastKnownIp'])
          : null,
      lastLoginAt: explicitOnline ? (lastSeenAt ?? DateTime.now()) : lastSeenAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      profile: profileFromTopLevel != null
          ? ProfileModel.fromJson(profileFromTopLevel)
          : null,
      photos: parsedPhotoList
          ?.whereType<Map>()
          .map((p) => PhotoModel.fromJson(Map<String, dynamic>.from(p)))
          .where((photo) => photo.url.trim().isNotEmpty)
          .toList(growable: false),
      fallbackPhotoUrl: _firstNonEmptyString([
        mainPhotoMap?['url'],
        mainPhotoMap?['secureUrl'],
        mainPhotoMap?['secure_url'],
        mainPhotoMap?['photoUrl'],
        mainPhotoMap?['photo_url'],
        avatarMap?['url'],
        avatarMap?['secureUrl'],
        avatarMap?['secure_url'],
        avatarMap?['avatarUrl'],
        avatarMap?['avatar_url'],
        json['mainPhotoUrl'],
        json['main_photo_url'],
        json['photoUrl'],
        json['photo_url'],
        json['photo'],
        json['avatarUrl'],
        json['avatar_url'],
        json['imageUrl'],
        json['image_url'],
        json['image'],
        json['picture'],
        json['profilePicture'],
        json['profile_picture'],
        json['avatar'],
        json['profilePhoto'],
        json['profile_photo'],
        profileMap?['mainPhotoUrl'],
        profileMap?['main_photo_url'],
        profileMap?['photoUrl'],
        profileMap?['photo_url'],
        profileMap?['photo'],
        profileMap?['avatarUrl'],
        profileMap?['avatar_url'],
        profileMap?['avatar'],
        profileMap?['profilePhoto'],
        profileMap?['profile_photo'],
        mediaMap?['mainPhotoUrl'],
        mediaMap?['photoUrl'],
        mediaMap?['avatarUrl'],
        mediaMap?['imageUrl'],
        if (parsedPhotoList != null && parsedPhotoList.isNotEmpty)
          (parsedPhotoList.first as Map)['url'],
      ]),
      subscription: json['subscription'] is Map
          ? SubscriptionModel.fromJson(
              Map<String, dynamic>.from(json['subscription'] as Map),
            )
          : null,
      sentComplimentsCount: _safeInt(json['sentComplimentsCount']),
      profileBoostsCount: _safeInt(json['profileBoostsCount']),
    );
  }

  /// Handles API entries that wrap a user object in keys like `user`.
  /// This prevents using wrapper record IDs instead of real user IDs.
  static UserModel fromApiEntry(dynamic raw) {
    if (raw is! Map) {
      return UserModel.fromJson(const <String, dynamic>{});
    }

    final map = Map<String, dynamic>.from(raw);
    const nestedKeys = [
      'user',
      'otherUser',
      'other_user',
      'matchedUser',
      'matched_user',
      'targetUser',
      'target_user',
      'participant',
      'participant_user',
      'member',
      'profileUser',
      'chatUser',
      'chat_user',
      'remoteUser',
      'remote_user',
    ];

    for (final key in nestedKeys) {
      final nested = map[key];
      if (nested is! Map) continue;

      final nestedMap = Map<String, dynamic>.from(nested);
      final merged = Map<String, dynamic>.from(map);
      nestedMap.forEach((k, v) {
        if (v != null) merged[k] = v;
      });

      // Prefer nested user identity over wrapper record IDs.
      final nestedUserId = _firstNonEmptyString([
        nestedMap['id'],
        nestedMap['_id'],
        nestedMap['userId'],
        nestedMap['user_id'],
      ]);
      if (nestedUserId != null) {
        merged['id'] = nestedUserId;
        merged['_id'] = nestedUserId;
        merged['userId'] = nestedUserId;
        merged['user_id'] = nestedUserId;
      }

      final candidate = UserModel.fromJson(merged);
      if (candidate.id.isNotEmpty) {
        return candidate;
      }
    }

    return UserModel.fromJson(map);
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
    'documentType': documentType,
    'documentVerified': documentVerified,
    'documentVerifiedAt': documentVerifiedAt?.toIso8601String(),
    'documentRejectionReason': documentRejectionReason,
    'isShadowBanned': isShadowBanned,
    'trustScore': trustScore,
    'backgroundCheckStatus': backgroundCheckStatus,
    'backgroundCheckedAt': backgroundCheckedAt?.toIso8601String(),
    'flagCount': flagCount,
    'deviceCount': deviceCount,
    'notificationsEnabled': notificationsEnabled,
    'lastKnownIp': lastKnownIp,
    'lastLoginAt': lastLoginAt?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'profile': profile?.toJson(),
    'photos': photos?.map((p) => p.toJson()).toList(),
    'mainPhotoUrl': fallbackPhotoUrl,
    'subscription': subscription?.toJson(),
    'sentComplimentsCount': sentComplimentsCount,
    'profileBoostsCount': profileBoostsCount,
  };

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();
  String get displayName => username ?? fullName;
  String? get mainPhotoUrl => photos?.isNotEmpty == true
      ? (photos!.firstWhere((p) => p.isMain, orElse: () => photos!.first)).url
      : fallbackPhotoUrl;
  int get age => profile?.age ?? 0;
  bool get isOnline {
    final normalized = status.toLowerCase();
    if (normalized == 'online') return true;
    if (lastLoginAt == null) return false;
    return DateTime.now().difference(lastLoginAt!).inMinutes < 5;
  }

  bool get wasLiveInLast24Hours {
    if (isOnline) return true;
    if (lastLoginAt == null) return false;
    return DateTime.now().difference(lastLoginAt!) <= const Duration(hours: 24);
  }

  bool get isTrialActive {
    final trialDuration = const Duration(days: 3);
    final now = DateTime.now();
    return now.difference(createdAt) < trialDuration;
  }

  Duration get trialTimeRemaining {
    final trialDuration = const Duration(days: 3);
    final expiration = createdAt.add(trialDuration);
    final remaining = expiration.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get hasProfilePhoto {
    final approvedPhotos =
        photos
            ?.where((p) => p.url.trim().isNotEmpty)
            .toList(growable: false) ??
        const <PhotoModel>[];
    if (approvedPhotos.isNotEmpty) return true;
    return (fallbackPhotoUrl ?? '').trim().isNotEmpty;
  }

  int get profileCompletenessScore {
    final backendCompletion = profile?.profileCompletionPercentage ?? 0;
    if (backendCompletion > 0) {
      return backendCompletion.clamp(0, 100);
    }

    int score = 0;
    if ((firstName ?? '').trim().isNotEmpty) score += 10;
    if ((lastName ?? '').trim().isNotEmpty) score += 5;
    if (age > 0) score += 10;
    if ((profile?.bio ?? '').trim().isNotEmpty) score += 15;
    if ((profile?.city ?? '').trim().isNotEmpty) score += 5;
    if ((profile?.country ?? '').trim().isNotEmpty) score += 5;
    if ((profile?.education ?? '').trim().isNotEmpty) score += 5;
    if ((profile?.jobTitle ?? '').trim().isNotEmpty) score += 5;

    final interestsCount =
        profile?.interests
            ?.where((value) => value.trim().isNotEmpty)
            .length ??
        0;
    if (interestsCount >= 3) {
      score += 15;
    } else if (interestsCount > 0) {
      score += 8;
    }

    final languagesCount =
        profile?.languages
            ?.where((value) => value.trim().isNotEmpty)
            .length ??
        0;
    if (languagesCount > 0) score += 5;

    if (hasProfilePhoto) score += 10;
    if (selfieVerified) score += 3;
    if (documentVerified) score += 4;

    return score.clamp(0, 100);
  }

  int get profileQualityScore {
    int score = 0;

    final photoCount = photos?.where((p) => p.url.trim().isNotEmpty).length ?? 0;
    if (photoCount >= 3) {
      score += 30;
    } else if (photoCount >= 2) {
      score += 20;
    } else if (photoCount == 1 || hasProfilePhoto) {
      score += 10;
    }

    if (selfieVerified) score += 15;
    if (documentVerified) score += 15;
    if (emailVerified) score += 10;

    if ((firstName ?? '').trim().isNotEmpty && age > 0) score += 10;
    if ((profile?.bio ?? '').trim().isNotEmpty) score += 10;
    if ((profile?.interests?.isNotEmpty ?? false)) score += 10;

    return score.clamp(0, 100);
  }

  bool get isQualityVerified => profileQualityScore >= 60 && selfieVerified;

  int get activityRankingScore {
    if (isOnline) return 100;
    if (wasLiveInLast24Hours) return 80;

    final backendActivity = profile?.activityScore ?? 0;
    if (backendActivity > 0) return backendActivity.clamp(0, 100);

    if (lastLoginAt == null) return 35;
    final inactiveDays = DateTime.now().difference(lastLoginAt!).inDays;
    if (inactiveDays <= 7) return 65;
    if (inactiveDays <= 30) return 45;
    if (inactiveDays <= 60) return 25;
    return 10;
  }

  bool get isBackgroundCheckCleared {
    final normalized = backgroundCheckStatus.trim().toLowerCase();
    return normalized == 'completed' ||
        normalized == 'approved' ||
        normalized == 'verified' ||
        normalized == 'cleared';
  }

  bool get isPremium =>
      (subscription != null && subscription!.isPremium) || isTrialActive;
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
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'])
          : null,
      bio: json['bio'],
      ethnicity: json['ethnicity'],
      nationality: json['nationality'],
      nationalities: json['nationalities'] != null
          ? List<String>.from(json['nationalities'])
          : null,
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
      familyValues: json['familyValues'] != null
          ? List<String>.from(json['familyValues'])
          : null,
      hasChildren: json['hasChildren'],
      numberOfChildren: json['numberOfChildren'] != null
          ? _safeInt(json['numberOfChildren'])
          : null,
      wantsChildren: json['wantsChildren'],
      willingToRelocate: json['willingToRelocate'],
      interests: json['interests'] != null
          ? List<String>.from(json['interests'])
          : null,
      languages: json['languages'] != null
          ? List<String>.from(json['languages'])
          : null,
      favoriteMusic: json['favoriteMusic'] != null
          ? List<String>.from(json['favoriteMusic'])
          : null,
      favoriteMovies: json['favoriteMovies'] != null
          ? List<String>.from(json['favoriteMovies'])
          : null,
      favoriteBooks: json['favoriteBooks'] != null
          ? List<String>.from(json['favoriteBooks'])
          : null,
      travelPreferences: json['travelPreferences'] != null
          ? List<String>.from(json['travelPreferences'])
          : null,
      aboutPartner: json['aboutPartner'],
      showAge: json['showAge'] ?? true,
      showDistance: json['showDistance'] ?? true,
      showOnlineStatus: json['showOnlineStatus'] ?? true,
      showLastSeen: json['showLastSeen'] ?? true,
      profileCompletionPercentage: _safeInt(
        json['profileCompletionPercentage'],
      ),
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
      if (secondWifePreference != null)
        'secondWifePreference': secondWifePreference,
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
      id: _firstNonEmptyString([
            json['id'],
            json['_id'],
            json['photoId'],
            json['photo_id'],
          ]) ??
          '',
      url: _firstNonEmptyString([
            json['url'],
            json['secureUrl'],
            json['secure_url'],
            json['imageUrl'],
            json['image_url'],
            json['photoUrl'],
            json['photo_url'],
        json['photo'],
        json['image'],
        json['avatar'],
        json['avatarUrl'],
        json['avatar_url'],
        json['file'],
        json['src'],
        json['link'],
        json['location'],
            json['path'],
          ]) ??
          '',
      publicId: _firstNonEmptyString([json['publicId'], json['public_id']]),
      isMain: _safeBool(json['isMain'] ?? json['main']),
      isSelfieVerification: _safeBool(
        json['isSelfieVerification'] ?? json['selfieVerification'],
      ),
      order: _safeInt(json['order'] ?? json['index']),
      moderationStatus:
          _safeString(json['moderationStatus'] ?? json['status'], 'approved'),
      moderationNote:
          _firstNonEmptyString([json['moderationNote'], json['note']]),
      createdAt: _safeDate(json['createdAt'] ?? json['created_at']),
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
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : null,
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
