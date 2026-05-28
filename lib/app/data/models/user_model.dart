import 'package:methna_app/app/routes/app_routes.dart';

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

String? _capitalizeNameValue(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return null;

  return trimmed
      .split(RegExp(r'\s+'))
      .where((segment) => segment.trim().isNotEmpty)
      .map((segment) {
        final lowerCased = segment.toLowerCase();
        return '${lowerCased[0].toUpperCase()}${lowerCased.substring(1)}';
      })
      .join(' ');
}

String? _normalizeLifecycleStatus(String? value) {
  final normalized = value?.trim().toLowerCase() ?? '';
  switch (normalized) {
    case 'pending-review':
    case 'pending_review':
    case 'under_review':
    case 'under-review':
    case 'in_review':
    case 'in-review':
    case 'review':
      return 'pending_verification';
    case 'verification_rejected':
    case 'declined':
    case 'denied':
    case 'reverify_required':
      return 'rejected';
    case 'blacklisted':
    case 'blocked_permanently':
      return 'banned';
    case 'disabled':
    case 'frozen':
      return 'suspended';
    case 'shadow_banned':
    case 'shadow-banned':
    case 'shadowban':
      return 'shadow_suspended';
    case 'restricted':
    case 'limited_access':
    case 'limited-access':
      return 'limited';
    default:
      return normalized.isEmpty ? null : normalized;
  }
}

bool _isRestrictedLifecycleStatus(String? value) {
  final normalized = _normalizeLifecycleStatus(value);
  return normalized == 'pending_verification' ||
      normalized == 'rejected' ||
      normalized == 'banned' ||
      normalized == 'suspended' ||
      normalized == 'limited' ||
      normalized == 'shadow_suspended';
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

Map<String, dynamic>? _normalizedLocationMap(dynamic value) {
  final root = _asMap(value);
  if (root == null) return null;

  final nested = _asMap(root['location']);
  final source = nested ?? root;
  final latitude = _safeDouble(source['latitude']);
  final longitude = _safeDouble(source['longitude']);
  final city = _firstNonEmptyString([
    source['city'],
    source['cityName'],
    source['city_name'],
  ]);
  final country = _firstNonEmptyString([
    source['country'],
    source['countryName'],
    source['country_name'],
  ]);

  if (latitude == null &&
      longitude == null &&
      (city == null || city.isEmpty) &&
      (country == null || country.isEmpty)) {
    return null;
  }

  return {
    'latitude': latitude,
    'longitude': longitude,
    'city': city,
    'country': country,
  };
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
  final bool agreedToTerms;
  final bool agreedToPrivacyPolicy;
  final bool oathAccepted;
  final bool phoneVerified;
  final bool selfieVerified;
  final String? selfieUrl;
  final String? documentUrl;
  final String? documentType;
  final bool documentVerified;
  final DateTime? documentVerifiedAt;
  final String? documentRejectionReason;
  final bool isShadowBanned;
  final String? statusReason;
  final String? moderationReasonCode;
  final String? moderationReasonText;
  final String? actionRequired;
  final String? supportMessage;
  final bool isUserVisible;
  final DateTime? moderationExpiresAt;
  final String? internalAdminNote;
  final String? updatedByAdminId;
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
  final bool backendPremium;
  final DateTime? premiumStartDate;
  final DateTime? premiumExpiryDate;
  final SubscriptionModel? subscription;
  final String? subscriptionPlanId;
  final bool isGhostModeEnabled;
  final bool isPassportActive;
  final Map<String, dynamic>? passportLocation;
  final Map<String, dynamic>? realLocation;
  final bool canViewAllPhotos;
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
    this.agreedToTerms = false,
    this.agreedToPrivacyPolicy = false,
    this.oathAccepted = false,
    this.phoneVerified = false,
    this.selfieVerified = false,
    this.selfieUrl,
    this.documentUrl,
    this.documentType,
    this.documentVerified = false,
    this.documentVerifiedAt,
    this.documentRejectionReason,
    this.isShadowBanned = false,
    this.statusReason,
    this.moderationReasonCode,
    this.moderationReasonText,
    this.actionRequired,
    this.supportMessage,
    this.isUserVisible = true,
    this.moderationExpiresAt,
    this.internalAdminNote,
    this.updatedByAdminId,
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
    this.backendPremium = false,
    this.premiumStartDate,
    this.premiumExpiryDate,
    this.subscription,
    this.subscriptionPlanId,
    this.isGhostModeEnabled = false,
    this.isPassportActive = false,
    this.passportLocation,
    this.realLocation,
    this.canViewAllPhotos = true,
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
    final trustSafety =
        json['trustSafety'] is Map ? (json['trustSafety'] as Map) : null;
    final verification =
        json['verification'] is Map ? (json['verification'] as Map) : null;
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
    final rawLifecycleStatus = _firstNonEmptyString([
      json['accountStatus'],
      json['account_status'],
      json['userStatus'],
      json['user_status'],
      json['moderationStatus'],
      json['moderation_status'],
      json['status'],
      json['state'],
      verification?['accountStatus'],
      verification?['account_status'],
      verification?['status'],
      trustSafety?['accountStatus'],
      trustSafety?['account_status'],
      trustSafety?['status'],
    ]);
    final normalizedLifecycleStatus =
        _normalizeLifecycleStatus(rawLifecycleStatus);
    final rawPresenceStatus = _firstNonEmptyString([
      if (rawPresence is Map) rawPresence['status'],
      if (rawPresence is Map) rawPresence['state'],
      if (rawPresence is! Map) rawPresence,
      json['presenceStatus'],
      json['presence_status'],
      activityMap?['status'],
      activityMap?['state'],
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
        (rawPresenceStatus?.toLowerCase() == 'online');
    final profileMap = _asMap(json['profile']);
    final visibilityMap = _asMap(json['visibility']);
    final passportLocation = _normalizedLocationMap(
      visibilityMap?['passportLocation'] ??
          visibilityMap?['passport_location'] ??
          json['passportLocation'] ??
          json['passport_location'],
    );
    final realLocation = _normalizedLocationMap(
      visibilityMap?['realLocation'] ??
          visibilityMap?['real_location'] ??
          json['realLocation'] ??
          json['real_location'],
    );
    final isGhostModeEnabled = _safeBool(
      json['isGhostModeEnabled'] ??
          json['is_ghost_mode_enabled'] ??
          json['isInvisible'] ??
          json['is_invisible'] ??
          visibilityMap?['isGhostModeEnabled'] ??
          visibilityMap?['is_ghost_mode_enabled'] ??
          visibilityMap?['isInvisible'] ??
          visibilityMap?['is_invisible'],
    );
    final isPassportActive = _safeBool(
      json['isPassportActive'] ??
          json['is_passport_active'] ??
          visibilityMap?['isPassportActive'] ??
          visibilityMap?['is_passport_active'],
      passportLocation != null,
    );
    final canViewAllPhotos = _safeBool(
      json['canViewAllPhotos'] ??
          json['can_view_all_photos'] ??
          visibilityMap?['canViewAllPhotos'] ??
          visibilityMap?['can_view_all_photos'],
      true,
    );
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
      assign('sect', [json['sect']]);
      assign('prayerFrequency', [json['prayerFrequency'], json['prayer_frequency']]);
      assign('marriageIntention', [
        json['marriageIntention'],
        json['marriage_intention'],
        json['marriageTimeline'],
        json['marriage_timeline'],
        json['timeFrame'],
        json['time_frame'],
      ]);
      assign('intentMode', [json['intentMode'], json['intent_mode']]);
      assign('ethnicity', [json['ethnicity']]);
      assign('maritalStatus', [json['maritalStatus'], json['marital_status']]);
      assign('education', [json['education']]);
      assign('educationDetails', [json['educationDetails'], json['education_details']]);
      assign('jobTitle', [json['jobTitle'], json['job_title'], json['profession']]);
      assign('company', [json['company']]);
      assign('height', [json['height']]);
      assign('weight', [json['weight']]);
      assign('skinComplexion', [json['skinComplexion'], json['skin_complexion']]);
      assign('build', [json['build']]);
      assign('livingSituation', [json['livingSituation'], json['living_situation']]);
      assign('communicationStyle', [
        json['communicationStyle'],
        json['communication_style'],
      ]);
      assign('dietary', [json['dietary']]);
      assign('alcohol', [json['alcohol']]);
      assign('hijabStatus', [json['hijabStatus'], json['hijab_status']]);
      assign('workoutFrequency', [
        json['workoutFrequency'],
        json['workout_frequency'],
      ]);
      assign('sleepSchedule', [json['sleepSchedule'], json['sleep_schedule']]);
      assign('socialMediaUsage', [
        json['socialMediaUsage'],
        json['social_media_usage'],
      ]);
      assign('familyPlans', [json['familyPlans'], json['family_plans']]);
      assign('familyValues', [json['familyValues'], json['family_values']]);
      assign('willingToRelocate', [
        json['willingToRelocate'],
        json['willing_to_relocate'],
      ]);
      assign('nationality', [json['nationality']]);
      assign('nationalities', [json['nationalities']]);
      assign('interests', [json['interests']]);
      assign('languages', [json['languages']]);
      assign('preferredDistanceKm', [
        json['preferredDistanceKm'],
        json['preferred_distance_km'],
        json['maxDistance'],
        json['max_distance'],
      ]);
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
      // CRITICAL: Prefer the backend's explicit `userId` field FIRST.
      // Discovery/search responses include `userId` as the canonical users.id.
      // Never use nested `profile.id` (that is the profiles row id, not user id).
      // Using profile.id for swipe causes FK violation on likes.likedId.
      id:
          _firstNonEmptyString([
            json['userId'],
            json['user_id'],
            json['id'],
            json['_id'],
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
      firstName: _capitalizeNameValue(
        _firstNonEmptyString([json['firstName'], json['first_name']]),
      ),
      lastName: _capitalizeNameValue(
        _firstNonEmptyString([json['lastName'], json['last_name']]),
      ),
      phone: _firstNonEmptyString([json['phone'], json['phoneNumber']]),
      role: _safeString(json['role'], 'user'),
      status: _isRestrictedLifecycleStatus(normalizedLifecycleStatus)
          ? normalizedLifecycleStatus!
          : explicitOnline
              ? 'online'
              : _safeString(
                  _normalizeLifecycleStatus(rawPresenceStatus) ??
                      normalizedLifecycleStatus ??
                  rawPresenceStatus,
                  'active',
                ),
      emailVerified: _safeBool(json['emailVerified']),
      agreedToTerms: _safeBool(json['agreedToTerms']),
      agreedToPrivacyPolicy: _safeBool(json['agreedToPrivacyPolicy']),
      oathAccepted: _safeBool(json['oathAccepted']),
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
      statusReason: _firstNonEmptyString([json['statusReason'], json['status_reason']]),
      moderationReasonCode: _firstNonEmptyString([json['moderationReasonCode'], json['moderation_reason_code']]),
      moderationReasonText: _firstNonEmptyString([json['moderationReasonText'], json['moderation_reason_text']]),
      actionRequired: _firstNonEmptyString([json['actionRequired'], json['action_required']]),
      supportMessage: _firstNonEmptyString([json['supportMessage'], json['support_message']]),
      isUserVisible: json['isUserVisible'] ?? json['is_user_visible'] ?? true,
      moderationExpiresAt: _safeDate(_firstNonEmptyString([json['moderationExpiresAt'], json['moderation_expires_at'], json['expiresAt']])),
      internalAdminNote: _firstNonEmptyString([json['internalAdminNote'], json['internal_admin_note']]),
      updatedByAdminId: _firstNonEmptyString([json['updatedByAdminId'], json['updated_by_admin_id']]),
      trustScore: _safeInt(json['trustScore'], 100),
      backgroundCheckStatus: _firstNonEmptyString([
            json['backgroundCheckStatus'],
            json['background_check_status'],
            trustSafety?['backgroundCheckStatus'],
            trustSafety?['background_check_status'],
          ]) ??
          'not_started',
      backgroundCheckedAt: _safeDate(
        _firstNonEmptyString([
          json['backgroundCheckedAt'],
          json['background_checked_at'],
          trustSafety?['backgroundCheckedAt'],
          trustSafety?['background_checked_at'],
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
          .where((photo) => photo.isLocked || photo.url.trim().isNotEmpty)
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
      backendPremium: _safeBool(
        json['isPremium'] ??
            json['is_premium'] ??
            json['premium'] ??
            json['hasPremium'],
      ),
      premiumStartDate: _safeDate(
        _firstNonEmptyString([
          json['premiumStartDate'],
          json['premium_start_date'],
          json['premiumStartAt'],
          json['premium_start_at'],
        ]),
      ),
      premiumExpiryDate: _safeDate(
        _firstNonEmptyString([
          json['premiumExpiryDate'],
          json['premium_expiry_date'],
          json['premiumExpiresAt'],
          json['premium_expires_at'],
          json['premiumEndDate'],
          json['premium_end_date'],
        ]),
      ),
      subscription: json['subscription'] is Map
          ? SubscriptionModel.fromJson(
              Map<String, dynamic>.from(json['subscription'] as Map),
            )
          : null,
      subscriptionPlanId: _firstNonEmptyString([
        json['subscriptionPlanId'],
        json['subscription_plan_id'],
      ]),
      isGhostModeEnabled: isGhostModeEnabled,
      isPassportActive: isPassportActive,
      passportLocation: passportLocation,
      realLocation: realLocation,
      canViewAllPhotos: canViewAllPhotos,
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
    'agreedToTerms': agreedToTerms,
    'agreedToPrivacyPolicy': agreedToPrivacyPolicy,
    'oathAccepted': oathAccepted,
    'phoneVerified': phoneVerified,
    'selfieVerified': selfieVerified,
    'selfieUrl': selfieUrl,
    'documentUrl': documentUrl,
    'documentType': documentType,
    'documentVerified': documentVerified,
    'documentVerifiedAt': documentVerifiedAt?.toIso8601String(),
    'documentRejectionReason': documentRejectionReason,
    'isShadowBanned': isShadowBanned,
    'statusReason': statusReason,
    'moderationReasonCode': moderationReasonCode,
    'moderationReasonText': moderationReasonText,
    'actionRequired': actionRequired,
    'supportMessage': supportMessage,
    'isUserVisible': isUserVisible,
    'moderationExpiresAt': moderationExpiresAt?.toIso8601String(),
    'internalAdminNote': internalAdminNote,
    'updatedByAdminId': updatedByAdminId,
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
    'isPremium': backendPremium,
    'premiumStartDate': premiumStartDate?.toIso8601String(),
    'premiumExpiryDate': premiumExpiryDate?.toIso8601String(),
    'subscription': subscription?.toJson(),
    'subscriptionPlanId': subscriptionPlanId,
    'isGhostModeEnabled': isGhostModeEnabled,
    'isPassportActive': isPassportActive,
    'passportLocation': passportLocation,
    'realLocation': realLocation,
    'canViewAllPhotos': canViewAllPhotos,
    'sentComplimentsCount': sentComplimentsCount,
    'profileBoostsCount': profileBoostsCount,
  };

  String get fullName =>
      '${_capitalizeNameValue(firstName) ?? ''} ${_capitalizeNameValue(lastName) ?? ''}'
          .trim();
  String get displayName {
    final full = fullName.trim();
    if (full.isNotEmpty) {
      return full;
    }
    final normalizedUsername = (username ?? '').trim();
    if (normalizedUsername.isNotEmpty) {
      return normalizedUsername;
    }
    return full;
  }
  String get publicDisplayName {
    final full = fullName.trim();
    if (full.isNotEmpty) {
      return full;
    }
    final usernameValue = (username ?? '').trim();
    if (usernameValue.isNotEmpty) {
      return usernameValue;
    }
    return '';
  }
  String get publicShortName {
    final full = publicDisplayName.trim();
    if (full.isEmpty) return '';
    return full.split(RegExp(r'\s+')).first.trim();
  }
  String? get mainPhotoUrl {
    final availablePhotos =
        photos
            ?.where((p) => !p.isLocked && p.url.trim().isNotEmpty)
            .toList(growable: false) ??
        const <PhotoModel>[];
    if (availablePhotos.isNotEmpty) {
      return availablePhotos
          .firstWhere((p) => p.isMain, orElse: () => availablePhotos.first)
          .url;
    }

    final fallback = (fallbackPhotoUrl ?? '').trim();
    return fallback.isNotEmpty ? fallback : null;
  }
  int get age => profile?.age ?? 0;
  bool get isOnline {
    final normalized = status.toLowerCase();
    if (normalized == 'online') return true;
    if (lastLoginAt == null) return false;
    return DateTime.now().difference(lastLoginAt!).inMinutes < 5;
  }

  // ── Moderation status helpers ──────────────────────────────
  bool get isLimited => status == 'limited';
  bool get isSuspended => status == 'suspended';
  bool get isShadowSuspended => status == 'shadow_suspended';
  bool get isBanned => status == 'banned';
  bool get isModerationRestricted =>
      isLimited || isSuspended || isShadowSuspended || isBanned;
  bool get canLike => !isLimited && !isBanned;
  bool get canMessage => !isLimited && !isSuspended && !isBanned;
  bool get canMatch => !isBanned;

  /// Whether the moderation has expired and should auto-revert
  bool get isModerationExpired {
    if (moderationExpiresAt == null) return false;
    return DateTime.now().isAfter(moderationExpiresAt!);
  }

  /// Whether the user should see any moderation UI
  bool get shouldShowModerationUI => isUserVisible && isModerationRestricted && !isModerationExpired;

  /// The primary message to show the user (prefers supportMessage > moderationReasonText > statusReason)
  String get moderationMessage {
    if (supportMessage != null && supportMessage!.isNotEmpty) return supportMessage!;
    if (moderationReasonText != null && moderationReasonText!.isNotEmpty) return moderationReasonText!;
    switch (status) {
      case 'limited':
        return statusReason ?? 'Your account is limited. Some features are restricted. Contact support.';
      case 'suspended':
        return statusReason ?? 'Your account is suspended. Contact support for more information.';
      case 'banned':
        return statusReason ?? 'Your account has been banned. Contact support.';
      default:
        return '';
    }
  }

  /// The CTA label for the action the user must take
  String get actionRequiredLabel {
    switch (_normalizedActionRequired) {
      case 'REUPLOAD_IDENTITY_DOCUMENT':
      case 'UPLOAD_IDENTITY_DOCUMENT':
      case 'IDENTITY_UPLOAD_REQUIRED':
      case 'REVERIFY_REQUIRED':
        return 'Open Verification Center';
      case 'RETAKE_SELFIE':
      case 'SELFIE_RETAKE_REQUIRED':
        return 'Retake Selfie';
      case 'UPLOAD_MARRIAGE_DOCUMENT':
        return 'Upload Marriage Document';
      case 'CONTACT_SUPPORT':
        return 'Contact Support';
      case 'WAIT_FOR_REVIEW':
        return 'Wait for Review';
      case 'VERIFY_PHONE':
        return 'Verify Phone';
      case 'VERIFY_EMAIL':
        return 'Verify Email';
      case 'NO_ACTION':
        return '';
      default:
        return isVerificationAction
            ? 'Open Verification Center'
            : isModerationRestricted
            ? 'Contact Support'
            : '';
    }
  }

  /// The route to navigate to for the required action
  String? get actionRequiredRoute {
    switch (_normalizedActionRequired) {
      case 'REUPLOAD_IDENTITY_DOCUMENT':
      case 'UPLOAD_IDENTITY_DOCUMENT':
      case 'IDENTITY_UPLOAD_REQUIRED':
      case 'REVERIFY_REQUIRED':
      case 'RETAKE_SELFIE':
      case 'SELFIE_RETAKE_REQUIRED':
      case 'UPLOAD_MARRIAGE_DOCUMENT':
        return AppRoutes.verificationCenter;
      case 'VERIFY_PHONE':
        return AppRoutes.contactSupport;
      case 'VERIFY_EMAIL':
        return AppRoutes.signupEmailVerification;
      case 'CONTACT_SUPPORT':
        return AppRoutes.contactSupport;
      default:
        return null;
    }
  }

  /// Whether the required action is a verification-type action
  bool get isVerificationAction =>
      _normalizedActionRequired == 'REUPLOAD_IDENTITY_DOCUMENT' ||
      _normalizedActionRequired == 'UPLOAD_IDENTITY_DOCUMENT' ||
      _normalizedActionRequired == 'IDENTITY_UPLOAD_REQUIRED' ||
      _normalizedActionRequired == 'REVERIFY_REQUIRED' ||
      _normalizedActionRequired == 'RETAKE_SELFIE' ||
      _normalizedActionRequired == 'SELFIE_RETAKE_REQUIRED' ||
      _normalizedActionRequired == 'UPLOAD_MARRIAGE_DOCUMENT';

  String get _normalizedActionRequired =>
      (actionRequired ?? '').trim().toUpperCase().replaceAll('-', '_');

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
            ?.where((p) => !p.isLocked && p.url.trim().isNotEmpty)
            .toList(growable: false) ??
        const <PhotoModel>[];
    if (approvedPhotos.isNotEmpty) return true;
    return (fallbackPhotoUrl ?? '').trim().isNotEmpty;
  }

  int get lockedPhotoCount =>
      photos?.where((photo) => photo.isLocked).length ?? 0;

  bool get hasLockedPhotos => lockedPhotoCount > 0;

  String get lockedPhotosCta {
    for (final photo in photos ?? const <PhotoModel>[]) {
      if (!photo.isLocked) continue;
      final cta = (photo.unlockCta ?? '').trim();
      if (cta.isNotEmpty) return cta;
    }
    return 'Verify your selfie to unlock all photos';
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

  bool get hasActivePremiumEntitlement {
    if (!backendPremium) return false;
    final now = DateTime.now();
    if (premiumStartDate != null && premiumStartDate!.isAfter(now)) {
      return false;
    }
    if (premiumExpiryDate != null && !premiumExpiryDate!.isAfter(now)) {
      return false;
    }
    return true;
  }

  bool get isPremium =>
      hasActivePremiumEntitlement ||
      (subscription != null && subscription!.isPremium);
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
  final String? skinComplexion;
  final String? bodyBuild;

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
  final double? preferredDistanceKm;

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
    this.skinComplexion,
    this.bodyBuild,
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
    this.preferredDistanceKm,
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
      marriageIntention:
          json['marriageIntention'] ??
          json['marriageTimeline'] ??
          json['timeFrame'],
      maritalStatus: json['maritalStatus'],
      secondWifePreference: json['secondWifePreference'],
      intentMode: json['intentMode'],
      education: json['education'],
      educationDetails: json['educationDetails'],
      jobTitle: json['jobTitle'],
      company: json['company'],
      height: json['height'] != null ? _safeInt(json['height']) : null,
      weight: json['weight'] != null ? _safeInt(json['weight']) : null,
      skinComplexion: json['skinComplexion'] ?? json['skin_complexion'],
      bodyBuild: json['build'],
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
      willingToRelocate: _safeBool(
        json['willingToRelocate'] ?? json['willing_to_relocate'],
      ),
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
      preferredDistanceKm: _safeDouble(
        json['preferredDistanceKm'] ??
            json['preferred_distance_km'] ??
            json['maxDistance'] ??
            json['max_distance'],
      ),
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
      if (skinComplexion != null) 'skinComplexion': skinComplexion,
      if (bodyBuild != null) 'build': bodyBuild,
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
      if (preferredDistanceKm != null) 'preferredDistanceKm': preferredDistanceKm,
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
  final String? originalUrl;
  final String? thumbnailUrl;
  final String? cardUrl;
  final String? profileUrl;
  final String? fullscreenUrl;
  final String? publicId;
  final bool isMain;
  final bool isSelfieVerification;
  final int order;
  final String moderationStatus;
  final String? moderationNote;
  final DateTime? createdAt;
  final bool isLocked;
  final String? lockReason;
  final String? unlockCta;

  PhotoModel({
    required this.id,
    required this.url,
    this.originalUrl,
    this.thumbnailUrl,
    this.cardUrl,
    this.profileUrl,
    this.fullscreenUrl,
    this.publicId,
    this.isMain = false,
    this.isSelfieVerification = false,
    this.order = 0,
    this.moderationStatus = 'approved',
    this.moderationNote,
    this.createdAt,
    this.isLocked = false,
    this.lockReason,
    this.unlockCta,
  });

  factory PhotoModel.fromJson(Map<String, dynamic> json) {
    final rawUrl = _firstNonEmptyString([
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
        '';

    return PhotoModel(
      id: _firstNonEmptyString([
            json['id'],
            json['_id'],
            json['photoId'],
            json['photo_id'],
          ]) ??
          '',
      url: rawUrl,
      originalUrl: _firstNonEmptyString([
        json['originalUrl'],
        json['original_url'],
        rawUrl,
      ]),
      thumbnailUrl: _firstNonEmptyString([
        json['thumbnailUrl'],
        json['thumbnail_url'],
      ]),
      cardUrl: _firstNonEmptyString([
        json['cardUrl'],
        json['card_url'],
        json['mediumUrl'],
        json['medium_url'],
      ]),
      profileUrl: _firstNonEmptyString([
        json['profileUrl'],
        json['profile_url'],
        json['largeUrl'],
        json['large_url'],
      ]),
      fullscreenUrl: _firstNonEmptyString([
        json['fullscreenUrl'],
        json['fullscreen_url'],
        json['fullUrl'],
        json['full_url'],
      ]),
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
      isLocked: _safeBool(
        json['isLocked'] ??
            json['locked'] ??
            json['is_locked'] ??
            json['blurred'],
      ),
      lockReason: _firstNonEmptyString([
        json['lockReason'],
        json['lock_reason'],
        json['reason'],
      ]),
      unlockCta: _firstNonEmptyString([
        json['unlockCta'],
        json['unlock_cta'],
        json['cta'],
      ]),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'url': url,
    'originalUrl': originalUrl,
    'thumbnailUrl': thumbnailUrl,
    'cardUrl': cardUrl,
    'profileUrl': profileUrl,
    'fullscreenUrl': fullscreenUrl,
    'isMain': isMain,
    'order': order,
    'isLocked': isLocked,
    'lockReason': lockReason,
    'unlockCta': unlockCta,
  };

  String get cardDeliveryUrl =>
      (cardUrl ?? thumbnailUrl ?? url).trim();

  String get profileDeliveryUrl =>
      (profileUrl ?? cardUrl ?? url).trim();

  String get fullscreenDeliveryUrl =>
      (fullscreenUrl ?? profileUrl ?? cardUrl ?? url).trim();
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

  bool get isActive =>
      status == 'active' ||
      status == 'pending_cancellation' ||
      status == 'past_due' ||
      status == 'trial';
  bool get isExpired => endDate != null && DateTime.now().isAfter(endDate!);
  bool get isPremium => plan != 'free' && isActive && !isExpired;
  bool get isGold => plan == 'gold' && isActive && !isExpired;
}
