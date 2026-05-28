import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart' hide Headers;
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;
import 'package:get_storage/get_storage.dart';
import 'package:http_parser/http_parser.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:methna_app/app/data/models/user_model.dart';
import 'package:methna_app/app/data/services/auth_service.dart';
import 'package:methna_app/app/data/services/api_service.dart';
import 'package:methna_app/app/data/services/verification_service.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/data/services/location_service.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/core/constants/api_constants.dart';
import 'package:methna_app/core/constants/app_constants.dart';
import 'package:methna_app/core/utils/upload_image_optimizer.dart';
import 'package:methna_app/core/utils/helpers.dart';
import 'package:methna_app/core/utils/validators.dart';
import 'package:methna_app/core/widgets/backend_wait_overlay.dart';
import 'signup_data.dart';

class SignupController extends GetxController {
  // ─── Constants & Dependencies ──────────────────────────────
  static const int totalSteps = 12;
  static const int maxHobbiesSelection = 5;
  static const Set<int> _skippableOptionalSteps = {6, 7};
  static const String _draftKey = AppConstants.signupDraftKey;

  final AuthService _auth = Get.find<AuthService>();
  final ApiService _api = Get.find<ApiService>();

  // ─── Step Tracking State ───────────────────────────────────
  final RxInt currentStep = 0.obs;
  final RxBool isLoading = false.obs;
  final RxBool isProcessing = false.obs;
  final RxBool isNavigatingStep = false.obs;
  bool _navigating = false;
  bool _isDirty = false;
  bool _isLoadingDraft = false;
  bool _photosUploaded = false;
  bool _selfieUploaded = false;
  bool _selfieVerificationRequested = false;
  Future<void>? _photosUploadFuture;
  Future<void>? _selfieUploadFuture;

  // ─── Workers & Triggers ─────────────────────────────────────
  Worker? _usernameWorker;
  Worker? _draftWorker;
  final RxInt _draftTrigger = 0.obs;

  // ─── Step 1: Username ──────────────────────────────────────
  final usernameController = TextEditingController();
  final RxBool usernameAvailable = false.obs;
  final RxBool checkingUsername = false.obs;
  final RxBool usernameCheckFailed = false.obs;
  final RxBool usernameChecked = false.obs;
  final RxBool usernameTaken = false.obs;
  final RxInt usernameInputTick = 0.obs;
  final RxString usernameError = ''.obs;
  final RxString debouncedUsername = ''.obs;

  // ─── Step 2: Gender ────────────────────────────────────────
  final RxString selectedGender = ''.obs;

  // ─── Step 3: Marital Status ────────────────────────────────
  final RxString selectedMaritalStatus = ''.obs;

  // ─── Step 4: Profile Details ───────────────────────────────
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final cityController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final Rx<DateTime?> dateOfBirth = Rx<DateTime?>(null);
  final profileFormKey = GlobalKey<FormState>();

  // ─── Step 5: Email Verification ────────────────────────────
  final otpController = TextEditingController();

  // ─── Step 6: Faith & Religion ──────────────────────────────
  final RxString selectedSect = ''.obs;
  final RxString selectedReligiousLevel = ''.obs;
  final RxString selectedPrayerFrequency = ''.obs;
  final RxString selectedDietary = ''.obs;
  final RxString selectedAlcohol = ''.obs;
  final RxString selectedHijab = ''.obs;
  // ─── Step 7: Hobbies & Interests ──────────────────────────
  final RxList<String> selectedHobbies = <String>[].obs;

  // ─── Step 8: Profession & Personal ─────────────────────────
  final jobTitleController = TextEditingController();
  final RxString selectedEducation = ''.obs;
  final companyController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final bioController = TextEditingController();
  final describeIdealSpouseController = TextEditingController();
  final RxnBool hasChildren = RxnBool();
  final RxnBool willingToRelocate = RxnBool();
  final numberOfChildrenController = TextEditingController();
  final RxList<String> selectedLanguages = <String>[].obs;
  final RxList<String> selectedNationalities = <String>[].obs;
  final RxString selectedEthnicity = ''.obs;
  final RxString selectedSkinComplexion = ''.obs;
  final RxString selectedBodyBuild = ''.obs;
  final RxList<String> selectedFamilyValues = <String>[].obs;
  final RxString selectedMarriageTimeline = '3-6 MONTHS'.obs;

  // ─── Step 9: Photos ────────────────────────────────────────
  final RxList<File> selectedPhotos = <File>[].obs;
  final RxInt mainPhotoIndex = 0.obs;
  List<String> _draftPhotoPaths = const <String>[];
  String? _draftSelfiePath;
  bool _mediaDraftHydrated = false;

  // ─── Step 10: Selfie ──────────────────────────────────────
  final Rx<File?> selfiePhoto = Rx<File?>(null);

  // ─── Step 11: Location ─────────────────────────────────────
  final RxBool locationEnabled = false.obs;
  final RxString selectedCountry = 'Algeria'.obs;
  final RxString selectedCity = ''.obs;
  final RxDouble preferredDistanceKm = 80.0.obs;
  final RxString selectedPhoneDialCode = '+213'.obs;
  final RxString selectedPhoneCountryCode = 'DZ'.obs;
  final RxString selectedPhoneCountryName = 'Algeria'.obs;

  List<String> get availableCities =>
      SignupData.countryCities[selectedCountry.value] ?? [];
  List<String> get arabicCountries => SignupData.arabicCountries;
  int get formChangeTick => _draftTrigger.value;
  String? get primaryNationality =>
      selectedNationalities.isNotEmpty ? selectedNationalities.first : null;
  String? get secondaryNationality =>
      selectedNationalities.length > 1 ? selectedNationalities[1] : null;

  // ─── Loading states ────────────────────────────────────────
  final RxBool obscurePassword = true.obs;
  final RxBool agreePrivacy = false.obs;
  final RxBool agreeOath = false.obs;

  void togglePasswordVisibility() => obscurePassword.toggle();

  // Lists moved to SignupData

  // ─── Route → step index map (source of truth for progress) ──
  static const _routeToStep = {
    '/signup/username': 0,
    '/signup/gender': 1,
    '/signup/marital-status': 2,
    '/signup/profile-details': 3,
    '/signup/birthday': 4,
    '/signup/email-verification': 5,
    '/signup/faith-religion': 6,
    '/signup/hobbies': 7,
    '/signup/profession': 8,
    '/signup/photos': 9,
    '/signup/selfie': 10,
    '/signup/location': 11,
  };

  /// Derive progress from the ACTUAL current route — never desyncs.
  double get progressPercent {
    final current = currentStep.value; // Force Rx read for Obx
    final step = _routeToStep[Get.currentRoute] ?? current;
    return (step + 1) / totalSteps;
  }

  /// Call this from every signup screen's build method to sync the step.
  void syncStep(String route) {
    final idx = _routeToStep[route];
    if (Get.currentRoute == route && _navigating && !isNavigatingStep.value) {
      _navigating = false;
    }
    if (idx != null) {
      _maybeHydrateMediaDraft(idx);
    }

    if (idx != null &&
        (currentStep.value != idx || Get.currentRoute != route)) {
      Future.microtask(() {
        currentStep.value = idx;
        _triggerSave(); // Use the debounced save
      });
      debugPrint('[Signup] SyncStep: $route (index: $idx)');
    }

    // Start listening for username changes if we're on the username screen
    if (route == AppRoutes.signupUsername && _usernameWorker == null) {
      _usernameWorker = debounce(
        debouncedUsername,
        (value) => _checkUsername(value),
        time: const Duration(milliseconds: 600),
      );

      usernameController.addListener(() {
        usernameInputTick.value++;
        final rawValue = usernameController.text.trim();
        final normalizedValue = rawValue.toLowerCase();

        if (rawValue.isEmpty) {
          usernameAvailable.value = false;
          checkingUsername.value = false;
          usernameCheckFailed.value = false;
          usernameChecked.value = false;
          usernameTaken.value = false;
          usernameError.value = '';
          return;
        }

        final localValidation = Validators.username(rawValue);
        if (localValidation != null) {
          usernameError.value = localValidation;
          usernameAvailable.value = false;
          checkingUsername.value = false;
          usernameCheckFailed.value = false;
          usernameChecked.value = false;
          usernameTaken.value = false;
          return;
        }

        // This triggers the debounce Worker above
        if (normalizedValue != debouncedUsername.value) {
          usernameError.value = '';
          usernameAvailable.value = false;
          usernameCheckFailed.value = false;
          usernameChecked.value = false;
          usernameTaken.value = false;
          checkingUsername.value = true;
          debouncedUsername.value = normalizedValue;
        }
      });
    }
  }

  void _maybeHydrateMediaDraft(int stepIdx) {
    if (_mediaDraftHydrated || stepIdx < 9) return;

    try {
      if (_draftPhotoPaths.isNotEmpty && selectedPhotos.isEmpty) {
        selectedPhotos.assignAll(_draftPhotoPaths.map((p) => File(p)).toList());
      }
      if (_draftSelfiePath != null && selfiePhoto.value == null) {
        selfiePhoto.value = File(_draftSelfiePath!);
      }
      _mediaDraftHydrated = true;
      debugPrint(
        '[Signup] Media draft hydrated: photos=${selectedPhotos.length}, selfie=${selfiePhoto.value != null}',
      );
    } catch (e) {
      debugPrint('[Signup] Media draft hydration failed: $e');
    }
  }

  Future<void> _checkUsername(String value) async {
    if (value.length < 3) {
      checkingUsername.value = false;
      usernameAvailable.value = false;
      usernameCheckFailed.value = false;
      usernameChecked.value = false;
      usernameTaken.value = false;
      return;
    }

    checkingUsername.value = true;
    try {
      debugPrint('[Signup] Checking username: $value');
      final response = await _api.get(
        ApiConstants.checkUsername,
        queryParameters: {'username': value.toLowerCase()},
        options: Options(
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
          extra: {
            'disable_retry': true,
            'skip_auth': true,
            'skip_auth_refresh': true,
          },
        ),
      );
      debugPrint('[Signup] Username check response: ${response.data}');

      final isAvailable = _extractUsernameAvailability(response.data);

      // Only update if the username hasn't changed while we were checking
      if (debouncedUsername.value == value) {
        if (isAvailable == null) {
          usernameAvailable.value = false;
          usernameCheckFailed.value = true;
          usernameChecked.value = true;
          usernameTaken.value = false;
          usernameError.value = 'username_check_fail'.tr;
        } else {
          usernameAvailable.value = isAvailable;
          usernameCheckFailed.value = false;
          usernameChecked.value = true;
          usernameTaken.value = !isAvailable;
          usernameError.value = isAvailable ? '' : 'username_taken'.tr;
        }
      }
    } catch (e) {
      debugPrint('[Signup] Username check ERROR: $e');
      // Don't block user on network errors — allow them to proceed
      if (debouncedUsername.value == value) {
        usernameAvailable.value = false;
        usernameCheckFailed.value = true;
        usernameChecked.value = true;
        usernameTaken.value = false;
        usernameError.value = 'username_check_fail'.tr;
      }
    } finally {
      checkingUsername.value = false;
    }
  }

  bool? _extractUsernameAvailability(dynamic data) {
    dynamic value = data;

    if (data is Map) {
      value =
          data['available'] ??
          data['isAvailable'] ??
          data['is_available'] ??
          data['status'];
      if (value == null && data['data'] is Map) {
        final nested = data['data'] as Map;
        value =
            nested['available'] ??
            nested['isAvailable'] ??
            nested['is_available'] ??
            nested['status'];
      }
    }

    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      const truthy = {'true', '1', 'yes', 'available'};
      const falsy = {'false', '0', 'no', 'taken', 'unavailable'};
      if (truthy.contains(normalized)) return true;
      if (falsy.contains(normalized)) return false;
    }

    return null;
  }

  int? _parseChildrenCount() {
    final raw = numberOfChildrenController.text.trim();
    if (raw.isEmpty) return null;

    final normalized = _normalizeDigits(raw);
    final parsed = int.tryParse(normalized);
    if (parsed == null || parsed < 0) return null;
    return parsed;
  }

  String _normalizeDigits(String value) {
    const arabicIndic = <String, String>{
      '٠': '0',
      '١': '1',
      '٢': '2',
      '٣': '3',
      '٤': '4',
      '٥': '5',
      '٦': '6',
      '٧': '7',
      '٨': '8',
      '٩': '9',
      '۰': '0',
      '۱': '1',
      '۲': '2',
      '۳': '3',
      '۴': '4',
      '۵': '5',
      '۶': '6',
      '۷': '7',
      '۸': '8',
      '۹': '9',
    };

    final buffer = StringBuffer();
    for (final rune in value.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(arabicIndic[char] ?? char);
    }
    return buffer.toString();
  }

  final List<String> stepRoutes = [
    AppRoutes.signupUsername, // 0
    AppRoutes.signupGender, // 1
    AppRoutes.signupMaritalStatus, // 2
    AppRoutes.signupProfileDetails, // 3
    AppRoutes.signupBirthday, // 4
    AppRoutes.signupEmailVerification, // 5
    AppRoutes.signupFaithReligion, // 6
    AppRoutes.signupHobbies, // 7
    AppRoutes.signupProfession, // 8
    AppRoutes.signupPhotos, // 9
    AppRoutes.signupSelfie, // 10
    AppRoutes.signupLocation, // 11
  ];

  @override
  void onInit() {
    super.onInit();
    _loadDraft();

    final List<RxInterface> autoSaveFields = [
      selectedGender,
      selectedMaritalStatus,
      dateOfBirth,
      selectedSect,
      selectedReligiousLevel,
      selectedPrayerFrequency,
      selectedDietary,
      selectedAlcohol,
      selectedHijab,
      selectedEducation,
      hasChildren,
      willingToRelocate,
      selectedEthnicity,
      selectedSkinComplexion,
      selectedBodyBuild,
      selectedMarriageTimeline,
      locationEnabled,
      selectedCountry,
      selectedCity,
      preferredDistanceKm,
      agreePrivacy,
      agreeOath,
      mainPhotoIndex,
      selfiePhoto,
    ];
    for (var field in autoSaveFields) {
      ever(field, (_) => _triggerSave());
    }

    // Auto-save hobbies & photos
    ever(selectedHobbies, (_) => _triggerSave());
    ever(selectedPhotos, (_) => _triggerSave());
    ever(selectedLanguages, (_) => _triggerSave());
    ever(selectedNationalities, (_) => _triggerSave());
    ever(selectedFamilyValues, (_) => _triggerSave());

    // Debounced auto-save for text controllers
    final textControllers = [
      usernameController,
      firstNameController,
      lastNameController,
      emailController,
      phoneController,
      cityController,
      jobTitleController,
      companyController,
      heightController,
      weightController,
      numberOfChildrenController,
      bioController,
      describeIdealSpouseController,
    ];
    for (var tc in textControllers) {
      tc.addListener(() => _triggerSave());
    }

    _draftWorker = debounce(
      _draftTrigger,
      (_) => _saveDraft(),
      time: const Duration(milliseconds: 2000),
    );
  }

  void _triggerSave() {
    if (_isLoadingDraft) return;
    _isDirty = true;
    _draftTrigger.value++;
  }

  // ─── Draft Persistence ──────────────────────────────────

  void _loadDraft() {
    Future.microtask(() {
      final draft = GetStorage().read<Map<String, dynamic>>(_draftKey);
      if (draft == null) return;

      _isLoadingDraft = true;
      debugPrint('[Signup] Loading draft data...');
      try {
        if (draft['username'] != null) {
          final savedUsername = draft['username'].toString().trim();
          usernameController.text = savedUsername;
          // Senior Fix: Trigger check immediately if we have a draft value
          if (savedUsername.length >= 3) {
            debouncedUsername.value = savedUsername.toLowerCase();
            _checkUsername(debouncedUsername.value);
          }
        }
        if (draft['gender'] != null) {
          selectedGender.value = draft['gender'];
        }
        if (draft['maritalStatus'] != null) {
          selectedMaritalStatus.value = draft['maritalStatus'];
        }
        if (draft['firstName'] != null) {
          firstNameController.text = draft['firstName'];
        }
        if (draft['lastName'] != null) {
          lastNameController.text = draft['lastName'];
        }
        if (draft['email'] != null) {
          emailController.text = draft['email'];
        }
        if (draft['phone'] != null) {
          phoneController.text = draft['phone'];
        }
        if (draft['dob'] != null) {
          dateOfBirth.value = DateTime.tryParse(draft['dob']);
        }
        if (draft['sect'] != null) {
          selectedSect.value = draft['sect'];
        }
        if (draft['religiousLevel'] != null) {
          selectedReligiousLevel.value = draft['religiousLevel'];
        }
        if (draft['prayerFrequency'] != null) {
          selectedPrayerFrequency.value = draft['prayerFrequency'];
        }
        if (draft['dietary'] != null) {
          selectedDietary.value = draft['dietary'];
        }
        if (draft['alcohol'] != null) {
          selectedAlcohol.value = draft['alcohol'];
        }
        if (draft['hijabStatus'] != null) {
          selectedHijab.value = draft['hijabStatus'];
        }
        if (draft['hobbies'] != null) {
          selectedHobbies.assignAll(
            List<String>.from(draft['hobbies']).take(maxHobbiesSelection),
          );
        }
        if (draft['jobTitle'] != null) {
          jobTitleController.text = draft['jobTitle'];
        }
        if (draft['education'] != null) {
          selectedEducation.value = draft['education'];
        }
        if (draft['company'] != null) {
          companyController.text = draft['company'];
        }
        if (draft['height'] != null) {
          heightController.text = draft['height'];
        }
        if (draft['weight'] != null) {
          weightController.text = draft['weight'].toString();
        }
        if (draft['hasChildren'] != null) {
          hasChildren.value = draft['hasChildren'] == true;
        }
        final draftWillingToRelocate =
            draft['willingToRelocate'] ?? draft['willing_to_relocate'];
        if (draftWillingToRelocate != null) {
          willingToRelocate.value = draftWillingToRelocate == true;
        }
        if (draft['numberOfChildren'] != null) {
          numberOfChildrenController.text = draft['numberOfChildren']
              .toString();
        }
        if (draft['languages'] != null) {
          selectedLanguages.assignAll(List<String>.from(draft['languages']));
        }
        if (draft['nationalities'] != null) {
          selectedNationalities.assignAll(
            List<String>.from(draft['nationalities']).take(2),
          );
        }
        if (draft['ethnicity'] != null) {
          selectedEthnicity.value = draft['ethnicity'].toString();
        }
        if (draft['skinComplexion'] != null) {
          selectedSkinComplexion.value = draft['skinComplexion'].toString();
        }
        if (draft['build'] != null) {
          selectedBodyBuild.value = draft['build'].toString();
        }
        if (draft['familyValues'] != null) {
          selectedFamilyValues.assignAll(
            List<String>.from(draft['familyValues']),
          );
        }
        if ((draft['marriageTimeline']?.toString().trim() ?? '').isNotEmpty) {
          selectedMarriageTimeline.value = _normalizeStoredMarriageTimeline(
            draft['marriageTimeline'].toString(),
          );
        }
        if (draft['bio'] != null) {
          bioController.text = draft['bio'];
        }
        if (draft['describeIdealSpouse'] != null) {
          describeIdealSpouseController.text =
              draft['describeIdealSpouse'].toString();
        }
        if (draft['country'] != null) {
          selectedCountry.value = draft['country'];
        }
        if (draft['city'] != null) {
          selectedCity.value = draft['city'];
          cityController.text = draft['city'].toString();
        }
        if (draft['phoneDialCode'] != null) {
          selectedPhoneDialCode.value = _normalizeDialCode(
            draft['phoneDialCode'].toString(),
          );
        }
        if (draft['phoneCountryCode'] != null) {
          selectedPhoneCountryCode.value = draft['phoneCountryCode'].toString();
        }
        if (draft['phoneCountryName'] != null) {
          selectedPhoneCountryName.value = draft['phoneCountryName'].toString();
        }
        if (draft['locationEnabled'] != null) {
          locationEnabled.value = draft['locationEnabled'];
        }
        if (draft['agreePrivacy'] != null) {
          agreePrivacy.value = draft['agreePrivacy'] == true;
        }
        if (draft['agreeOath'] != null) {
          agreeOath.value = draft['agreeOath'] == true;
        }
        if (draft['preferredDistanceKm'] != null) {
          final rawDistance = draft['preferredDistanceKm'];
          if (rawDistance is num) {
            preferredDistanceKm.value = rawDistance.toDouble();
          } else if (rawDistance is String) {
            final parsed = double.tryParse(rawDistance);
            if (parsed != null) {
              preferredDistanceKm.value = parsed;
            }
          }
        }

        _draftPhotoPaths = draft['photoPaths'] != null
            ? List<String>.from(draft['photoPaths'])
            : const <String>[];
        if (draft['mainPhotoIndex'] != null) {
          mainPhotoIndex.value = draft['mainPhotoIndex'];
        }

        _draftSelfiePath = draft['selfiePath']?.toString();
        // Note: Navigation to lastRoute is now handled by SplashController for better stability
      } catch (e) {
        debugPrint('[Signup] Failed to load draft: $e');
      } finally {
        _isLoadingDraft = false;
      }
    });
  }

  // ─── Persistence ───────────────────────────────────────────
  void _saveDraft() {
    if (!_isDirty || _isLoadingDraft || _navigating || isNavigatingStep.value) {
      return;
    }

    // Senior Fix: Use a background task approach (Future.delayed(0) or compute)
    // to ensure Disk I/O never blocks the current UI frame during navigation.
    Future.delayed(Duration.zero, () async {
      try {
        final stopwatch = Stopwatch()..start();
        final photoPaths = selectedPhotos.isNotEmpty
            ? selectedPhotos.map((f) => f.path).toList()
            : _draftPhotoPaths;
        final selfiePath = selfiePhoto.value?.path ?? _draftSelfiePath;
        final draft = {
          'username': usernameController.text,
          'gender': selectedGender.value,
          'maritalStatus': selectedMaritalStatus.value,
          'firstName': firstNameController.text,
          'lastName': lastNameController.text,
          'email': emailController.text,
          'phone': phoneController.text,
          'dob': dateOfBirth.value?.toIso8601String(),
          'sect': selectedSect.value,
          'religiousLevel': selectedReligiousLevel.value,
          'prayerFrequency': selectedPrayerFrequency.value,
          'dietary': selectedDietary.value,
          'alcohol': selectedAlcohol.value,
          'hijabStatus': selectedHijab.value,
          'hobbies': selectedHobbies.toList(),
          'jobTitle': jobTitleController.text,
          'education': selectedEducation.value,
          'company': companyController.text,
          'height': heightController.text,
          'weight': weightController.text,
          'hasChildren': hasChildren.value,
          'willingToRelocate': willingToRelocate.value,
          'numberOfChildren': numberOfChildrenController.text,
          'languages': selectedLanguages.toList(),
          'nationalities': selectedNationalities.toList(),
          'ethnicity': selectedEthnicity.value,
          'skinComplexion': selectedSkinComplexion.value,
          'build': selectedBodyBuild.value,
          'familyValues': selectedFamilyValues.toList(),
          'marriageTimeline': selectedMarriageTimeline.value,
          'bio': bioController.text,
          'describeIdealSpouse': describeIdealSpouseController.text,
          'photoPaths': photoPaths,
          'mainPhotoIndex': mainPhotoIndex.value,
          'country': selectedCountry.value,
          'city': cityController.text.trim(),
          'phoneDialCode': selectedPhoneDialCode.value,
          'phoneCountryCode': selectedPhoneCountryCode.value,
          'phoneCountryName': selectedPhoneCountryName.value,
          'locationEnabled': locationEnabled.value,
          'preferredDistanceKm': preferredDistanceKm.value,
          'agreePrivacy': agreePrivacy.value,
          'agreeOath': agreeOath.value,
          'lastRoute': Get.currentRoute,
          // ignore: use_null_aware_elements
          if (selfiePath case final value?) 'selfiePath': value,
        };

        await GetStorage().write(_draftKey, draft);
        _isDirty = false;
        stopwatch.stop();
        debugPrint(
          '[Signup] Draft saved successfully in ${stopwatch.elapsedMilliseconds}ms',
        );
      } catch (e) {
        debugPrint('[Signup] Failed to save draft: $e');
      }
    });
  }

  Future<void> _persistDraftRoute(String route) async {
    try {
      final storage = GetStorage();
      final existing = Map<String, dynamic>.from(
        storage.read<Map<String, dynamic>>(_draftKey) ?? <String, dynamic>{},
      );
      existing['lastRoute'] = route;
      await storage.write(_draftKey, existing);
    } catch (e) {
      debugPrint('[Signup] Failed to persist draft route ($route): $e');
    }
  }

  void _clearDraft() {
    GetStorage().remove(_draftKey);
    _draftPhotoPaths = const <String>[];
    _draftSelfiePath = null;
    _mediaDraftHydrated = false;
    preferredDistanceKm.value = 80.0;
    selectedPhoneDialCode.value = '+213';
    selectedPhoneCountryCode.value = 'DZ';
    selectedPhoneCountryName.value = 'Algeria';
    selectedMarriageTimeline.value = '3-6 MONTHS';
    willingToRelocate.value = null;
    selectedSkinComplexion.value = '';
    selectedBodyBuild.value = '';
    agreePrivacy.value = false;
    agreeOath.value = false;
    cityController.clear();
    selectedCity.value = '';
    weightController.clear();
    describeIdealSpouseController.clear();
    _photosUploaded = false;
    _selfieUploaded = false;
    _selfieVerificationRequested = false;
    _photosUploadFuture = null;
    _selfieUploadFuture = null;
    debugPrint('[Signup] Draft cleared');
  }

  void onCountryChanged(String country) {
    selectedCountry.value = country;
    final city = cityController.text.trim();
    selectedCity.value = city;
    _triggerSave();
  }

  void setPhoneCountry({
    required String dialCode,
    required String countryCode,
    required String countryName,
  }) {
    selectedPhoneDialCode.value = _normalizeDialCode(dialCode);
    selectedPhoneCountryCode.value = countryCode;
    selectedPhoneCountryName.value = countryName;
    _triggerSave();
  }

  String _normalizeDialCode(String rawDialCode) {
    final compact = rawDialCode.trim().replaceAll(RegExp(r'\s+'), '');
    final digitsOnly = compact.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return '+213';
    }
    return '+$digitsOnly';
  }

  String _composePhoneForSubmit(String rawPhone) {
    final normalized = rawPhone.trim().replaceAll(RegExp(r'\s+'), '');
    if (normalized.isEmpty) return '';
    if (normalized.startsWith('+')) return normalized;

    final dialCode = selectedPhoneDialCode.value.trim().isNotEmpty
        ? _normalizeDialCode(selectedPhoneDialCode.value)
        : '+213';
    final localNumber = normalized.startsWith('0')
        ? normalized.substring(1)
        : normalized;
    return '$dialCode$localNumber';
  }

  void navigateTo(String route) {
    if (_navigating) return;
    _navigating = true;
    debugPrint('[Signup] navigateTo: $route');
    Get.focusScope?.unfocus();
    syncStep(route);
    _saveDraft(); // Immediate save before navigation to ensure persistence
    Get.toNamed(route);
    Future.delayed(
      const Duration(milliseconds: 500),
      () => _navigating = false,
    );
  }

  void goBack() {
    Get.focusScope?.unfocus();
    Get.back();
    Future.microtask(() {
      final idx = _routeToStep[Get.currentRoute];
      if (idx != null) currentStep.value = idx;
    });
  }

  Future<void> goToNextStep() async {
    if (_navigating && !isNavigatingStep.value) {
      _navigating = false;
    }
    if (_navigating || isNavigatingStep.value) return;
    _navigating = true;
    isNavigatingStep.value = true;
    Get.focusScope?.unfocus();

    var transitionLoaderShown = false;

    try {
      final currentIdx = _routeToStep[Get.currentRoute] ?? currentStep.value;
      final isOptionalStep = _skippableOptionalSteps.contains(currentIdx);
      final stepIsComplete = isOptionalStep
          ? _isOptionalStepComplete(currentIdx)
          : validateStep(currentIdx);

      if (!isOptionalStep && !stepIsComplete) {
        return;
      }

      if (_requiresBlockingSync(currentIdx, stepIsComplete)) {
        _showStepTransitionLoader();
        transitionLoaderShown = true;
        await _runBlockingStepSync(currentIdx);
      }

      final nextIdx = currentIdx + 1;
      final nextRoute = nextIdx < totalSteps ? stepRoutes[nextIdx] : null;

      debugPrint(
        '[Signup] goToNextStep: currentIdx=$currentIdx -> nextIdx=$nextIdx, target=$nextRoute',
      );

      if (nextRoute != null) {
        if (transitionLoaderShown && (Get.isDialogOpen ?? false)) {
          Get.back();
          transitionLoaderShown = false;
        }

        currentStep.value = nextIdx;
        debugPrint('[Signup] Transition -> $nextRoute (from $currentIdx)');
        Get.toNamed(nextRoute);

        // Persist route out of the transition critical path.
        Future.microtask(() => unawaited(_persistDraftRoute(nextRoute)));
      }

      _triggerSave();
    } catch (e) {
      debugPrint('[Signup] goToNextStep unexpected error: $e');
    } finally {
      if (transitionLoaderShown && (Get.isDialogOpen ?? false)) {
        Get.back();
      }

      isNavigatingStep.value = false;
      Future.delayed(
        const Duration(milliseconds: 500),
        () => _navigating = false,
      );
    }
  }

  bool _requiresBlockingSync(int currentIdx, bool stepIsComplete) {
    if (!stepIsComplete) return false;
    return currentIdx == 6 || currentIdx == 8 || currentIdx == 9 || currentIdx == 10;
  }

  Future<void> _runBlockingStepSync(int currentIdx) async {
    switch (currentIdx) {
      case 6:
      case 8:
        await updateProfile(setLoading: false);
        return;
      case 9:
        await uploadPhotos();
        return;
      case 10:
        await uploadSelfie();
        return;
      default:
        return;
    }
  }

  void _showStepTransitionLoader() {
    if (Get.isDialogOpen ?? false) return;

    Get.dialog(
      PopScope(
        canPop: false,
        child: Center(
          child: BackendWaitPanel(message: 'loading'.tr),
        ),
      ),
      barrierDismissible: false,
      useSafeArea: false,
    );
  }

  bool _isOptionalStepComplete(int step) {
    switch (step) {
      case 6:
        return selectedSect.value.isNotEmpty ||
            selectedReligiousLevel.value.isNotEmpty ||
            selectedPrayerFrequency.value.isNotEmpty ||
            selectedDietary.value.isNotEmpty ||
            selectedAlcohol.value.isNotEmpty ||
            selectedHijab.value.isNotEmpty;
      case 7:
        return selectedHobbies.isNotEmpty;
      case 8:
        final hasChildrenValue = hasChildren.value;
        final validChildrenCount =
            !(hasChildrenValue ?? false) || _parseChildrenCount() != null;
        if (!validChildrenCount) {
          return false;
        }

        return selectedEducation.value.isNotEmpty ||
            jobTitleController.text.trim().isNotEmpty ||
            companyController.text.trim().isNotEmpty ||
            heightController.text.trim().isNotEmpty ||
            weightController.text.trim().isNotEmpty ||
            bioController.text.trim().isNotEmpty ||
            describeIdealSpouseController.text.trim().isNotEmpty ||
            selectedLanguages.isNotEmpty ||
            selectedNationalities.isNotEmpty ||
            selectedEthnicity.value.isNotEmpty ||
            selectedSkinComplexion.value.isNotEmpty ||
            selectedBodyBuild.value.isNotEmpty ||
            hasChildrenValue != null ||
          willingToRelocate.value != null ||
            selectedFamilyValues.isNotEmpty ||
            selectedMarriageTimeline.value.isNotEmpty;
      default:
        return true;
    }
  }

  Future<void> skipCurrentOptionalStep() async {
    if (_navigating && !isNavigatingStep.value) {
      _navigating = false;
    }
    if (_navigating || isNavigatingStep.value) return;

    final currentIdx = _routeToStep[Get.currentRoute] ?? currentStep.value;
    if (!_skippableOptionalSteps.contains(currentIdx)) {
      debugPrint(
        '[Signup] skipCurrentOptionalStep ignored for step $currentIdx',
      );
      return;
    }

    _navigating = true;
    isNavigatingStep.value = true;
    Get.focusScope?.unfocus();

    try {
      final nextIdx = currentIdx + 1;
      final nextRoute = nextIdx < totalSteps ? stepRoutes[nextIdx] : null;

      debugPrint(
        '[Signup] skipCurrentOptionalStep: currentIdx=$currentIdx -> nextIdx=$nextIdx, target=$nextRoute',
      );

      if (nextRoute != null) {
        currentStep.value = nextIdx;
        Get.toNamed(nextRoute);
        Future.microtask(() => unawaited(_persistDraftRoute(nextRoute)));
      }

      _triggerSave();
    } catch (e) {
      debugPrint('[Signup] skipCurrentOptionalStep unexpected error: $e');
    } finally {
      isNavigatingStep.value = false;
      Future.delayed(
        const Duration(milliseconds: 500),
        () => _navigating = false,
      );
    }
  }

  bool validateStep(int step) {
    switch (step) {
      case 0: // Username
        final usernameValidation = Validators.username(
          usernameController.text.trim(),
        );
        if (usernameValidation != null) {
          _handleError(null, usernameValidation);
          return false;
        }
        if (checkingUsername.value) {
          _handleError(null, 'checking_username'.tr);
          return false;
        }
        if (usernameTaken.value) {
          _handleError(null, 'username_not_available'.tr);
          return false;
        }
        if (!usernameAvailable.value && !usernameCheckFailed.value) {
          _handleError(null, 'checking_username'.tr);
          return false;
        }
        return true;
      case 1: // Gender
        if (selectedGender.value.isEmpty) {
          _handleError(null, 'gender_required'.tr);
          return false;
        }
        return true;
      case 2: // Marital Status
        if (selectedMaritalStatus.value.isEmpty) {
          _handleError(null, 'marital_status_required'.tr);
          return false;
        }
        return true;
      case 3: // Profile Details (Form)
        if (profileFormKey.currentState == null ||
            !profileFormKey.currentState!.validate()) {
          return false;
        }
        return true;
      case 4: // Birthday
        if (dateOfBirth.value == null) {
          _handleError(null, 'birthday_required'.tr);
          return false;
        }
        return true;
      case 5: // Email verification is handled by verifyEmailOtp
        return true;
      case 6: // Faith
        return true;
      case 7: // Hobbies
        if (selectedHobbies.length > maxHobbiesSelection) {
          _handleError(
            null,
            'max_hobbies_reached'.trParams({'count': '$maxHobbiesSelection'}),
          );
          return false;
        }
        return true;
      case 8: // Profession
        if (selectedMarriageTimeline.value.trim().isEmpty) {
          _handleError(null, 'marriage_timeline_required'.tr);
          return false;
        }
        if ((hasChildren.value ?? false) && _parseChildrenCount() == null) {
          _handleError(
            null,
            'Please enter the number of children or set it to 0.',
          );
          return false;
        }
        if (selectedNationalities.length > 2) {
          _handleError(null, 'You can select up to 2 nationalities only.');
          return false;
        }
        return true;
      case 9: // Photos
        if (selectedPhotos.length < 2) {
          _handleError(null, 'min_photos_required'.trParams({'count': '2'}));
          return false;
        }
        return true;
      case 10: // Selfie
        if (selfiePhoto.value == null) {
          _handleError(null, 'selfie_required'.tr);
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  // ─── Register account & advance to email verification ────
  Future<void> registerAccount() async {
    if (isLoading.value) return;
    isLoading.value = true;
    debugPrint(
      '[Signup] registerAccount: email=${emailController.text.trim()}',
    );
    try {
      final submittedPhone = _composePhoneForSubmit(phoneController.text);
      final result = await _auth.register(
        email: emailController.text.trim(),
        password: passwordController.text,
        confirmPassword: confirmPasswordController.text,
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        agreeToTerms: agreePrivacy.value,
        agreeToPrivacyPolicy: agreePrivacy.value,
        oathAccepted: agreeOath.value,
        username: usernameController.text.trim().isNotEmpty
            ? usernameController.text.trim()
            : null,
        phone: submittedPhone.isNotEmpty ? submittedPhone : null,
      );
      debugPrint('[Signup] registerAccount success: $result');

      final emailSent = result['emailSent'] == true;
      if (emailSent) {
        Helpers.showSnackbar(message: 'account_created_check_email'.tr);
      } else {
        Helpers.showSnackbar(
          message: 'account_created_email_fail'.tr,
          isError: true,
          duration: const Duration(seconds: 5),
        );
      }
      goToNextStep();
    } catch (e) {
      _handleError(e, 'registration_failed'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyEmailOtp() async {
    isLoading.value = true;
    try {
      await _auth.verifyOtp(
        emailController.text.trim(),
        otpController.text.trim(),
      );
      Helpers.showSnackbar(message: 'email_verified_continue'.tr);
      // Ensure restart resume never returns to pre-OTP screens after a verified account.
      await _persistDraftRoute(AppRoutes.signupFaithReligion);
      goToNextStep();
    } catch (e) {
      _handleError(e, 'verification_failed'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendOtp() async {
    try {
      await _auth.resendOtp(emailController.text.trim());
      Helpers.showSnackbar(message: 'new_otp_sent'.tr);
    } catch (e) {
      Helpers.showSnackbar(message: 'wait_before_retry'.tr, isError: true);
    }
  }

  String _toEnumValue(String label) {
    return label.toLowerCase().replaceAll("'", "").replaceAll(' ', '_');
  }

  String _normalizeTimelineKey(String timelineKey) {
    return timelineKey.trim().toUpperCase().replaceAll('-', '_').replaceAll(
      ' ',
      '_',
    );
  }

  String _normalizeStoredMarriageTimeline(String value) {
    switch (_normalizeTimelineKey(value)) {
      case 'WITHIN_MONTHS':
        return '1-3 MONTHS';
      case 'WITHIN_YEAR':
        return 'UP TO 1 YEAR';
      default:
        return value;
    }
  }

  String? _marriageIntentionFromTimeline(String timelineKey) {
    switch (_normalizeTimelineKey(timelineKey)) {
      case '1_3_MONTHS':
      case 'WITHIN_MONTHS':
        return 'within_months';
      case '3_6_MONTHS':
      case 'UP_TO_1_YEAR':
      case 'WITHIN_YEAR':
        return 'within_year';
      case '1_2_YEARS':
      case 'ONE_TO_TWO_YEARS':
        return 'one_to_two_years';
      case 'NOT_SURE':
        return 'not_sure';
      case 'JUST_EXPLORING':
        return 'just_exploring';
      default:
        return null;
    }
  }

  String? _intentModeFromTimeline(String timelineKey) {
    switch (_normalizeTimelineKey(timelineKey)) {
      case '1_3_MONTHS':
      case 'WITHIN_MONTHS':
        return 'family_introduction';
      case '3_6_MONTHS':
      case 'UP_TO_1_YEAR':
      case 'WITHIN_YEAR':
      case '1_2_YEARS':
      case 'ONE_TO_TWO_YEARS':
        return 'serious_marriage';
      case 'NOT_SURE':
      case 'JUST_EXPLORING':
        return 'exploring';
      default:
        return null;
    }
  }

  int _uploadedPhotoCount(UserModel? user) {
    final photos = user?.photos;
    if (photos == null || photos.isEmpty) return 0;
    return photos.where((photo) => photo.url.trim().isNotEmpty).length;
  }

  bool _hasUploadedSelfie(UserModel? user) {
    final selfieUrl = user?.selfieUrl?.trim() ?? '';
    return selfieUrl.isNotEmpty || (user?.selfieVerified ?? false);
  }

  Future<void> _syncDiscoveryPreference() async {
    final roundedDistance = preferredDistanceKm.value.round();
    final payload = {
      'maxDistance': roundedDistance,
      'preferredDistanceKm': roundedDistance,
      'distanceUnit': 'km',
    };

    try {
      await _api.patch(ApiConstants.preferences, data: payload);
    } catch (_) {
      try {
        await _api.post(ApiConstants.preferences, data: payload);
      } catch (e) {
        debugPrint('[Signup] discovery preference sync skipped: $e');
      }
    }
  }

  Future<UserModel?> _refreshSignupState({int attempts = 4}) async {
    UserModel? latest = _auth.currentUser.value;

    for (var attempt = 0; attempt < attempts; attempt++) {
      try {
        latest = await _auth.fetchMe();
      } catch (e) {
        if (attempt == attempts - 1) {
          debugPrint('[Signup] fetchMe during completion failed: $e');
          break;
        }
      }

      if (_isSignupPersisted(latest)) {
        return latest;
      }

      if (attempt < attempts - 1) {
        await Future.delayed(Duration(milliseconds: 600 * (attempt + 1)));
      }
    }

    return latest;
  }

  bool _isSignupPersisted(UserModel? user) {
    final profile = user?.profile;
    final profileMarkedComplete =
        (profile?.isComplete ?? false) ||
        ((profile?.profileCompletionPercentage ?? 0) >= 50);
    final hasCoreProfile =
        profile != null &&
        (profile.gender?.trim().isNotEmpty ?? false) &&
        profile.dateOfBirth != null;

    return _uploadedPhotoCount(user) >= 2 &&
        _hasUploadedSelfie(user) &&
        (hasCoreProfile || profileMarkedComplete);
  }

  Future<void> updateProfile({bool setLoading = true}) async {
    if (setLoading) {
      isLoading.value = true;
    }
    try {
      if (selectedCountry.value.trim().isEmpty) {
        selectedCountry.value = 'Algeria';
      }
      selectedCity.value = cityController.text.trim();

      final resolvedMarriageIntention = _marriageIntentionFromTimeline(
        selectedMarriageTimeline.value,
      );
      final resolvedIntentMode = _intentModeFromTimeline(
        selectedMarriageTimeline.value,
      );

      final profileData = {
        'gender': selectedGender.value.toLowerCase(),
        'dateOfBirth': dateOfBirth.value?.toIso8601String().split('T')[0],
        'maritalStatus': _toEnumValue(selectedMaritalStatus.value),
        if (selectedSect.value.isNotEmpty)
          'sect': _toEnumValue(selectedSect.value),
        if (selectedReligiousLevel.value.isNotEmpty)
          'religiousLevel': _toEnumValue(selectedReligiousLevel.value),
        if (selectedPrayerFrequency.value.isNotEmpty)
          'prayerFrequency': _toEnumValue(selectedPrayerFrequency.value),
        if (selectedDietary.value.isNotEmpty)
          'dietary': _toEnumValue(selectedDietary.value),
        if (selectedAlcohol.value.isNotEmpty)
          'alcohol': _toEnumValue(selectedAlcohol.value),
        if (selectedGender.value.toLowerCase() == 'female' &&
            selectedHijab.value.isNotEmpty)
          'hijabStatus': _toEnumValue(selectedHijab.value),
        'interests': selectedHobbies.toList(),
        if (selectedEducation.value.isNotEmpty)
          'education': _toEnumValue(selectedEducation.value),
        if (selectedLanguages.isNotEmpty)
          'languages': selectedLanguages.toList(),
        if (selectedNationalities.isNotEmpty)
          'nationalities': selectedNationalities.toList(),
        if (selectedNationalities.isNotEmpty)
          'nationality': selectedNationalities.first,
        if (selectedEthnicity.value.isNotEmpty)
          'ethnicity': selectedEthnicity.value,
        if (selectedSkinComplexion.value.isNotEmpty)
          'skinComplexion': selectedSkinComplexion.value,
        if (selectedBodyBuild.value.isNotEmpty)
          'build': selectedBodyBuild.value,
        if (selectedFamilyValues.isNotEmpty)
          'familyValues': selectedFamilyValues.map(_toEnumValue).toList(),
        if (resolvedMarriageIntention != null)
          'marriageIntention': resolvedMarriageIntention,
        if (resolvedIntentMode != null) 'intentMode': resolvedIntentMode,
        if (hasChildren.value != null) 'hasChildren': hasChildren.value,
        if (willingToRelocate.value != null)
          'willingToRelocate': willingToRelocate.value,
        if ((hasChildren.value ?? false) && _parseChildrenCount() != null)
          'numberOfChildren': _parseChildrenCount(),
        if (jobTitleController.text.isNotEmpty)
          'jobTitle': jobTitleController.text.trim(),
        if (companyController.text.isNotEmpty)
          'company': companyController.text.trim(),
        if (heightController.text.isNotEmpty)
          'height': int.tryParse(heightController.text),
        if (weightController.text.isNotEmpty)
          'weight': int.tryParse(weightController.text),
        if (bioController.text.isNotEmpty) 'bio': bioController.text.trim(),
        if (describeIdealSpouseController.text.trim().isNotEmpty)
          'aboutPartner': describeIdealSpouseController.text.trim(),
        'country': selectedCountry.value,
        if (selectedCity.value.isNotEmpty) 'city': selectedCity.value,
      };

      debugPrint('[SignupController] Updating profile with data: $profileData');
      await _api.post(ApiConstants.createOrUpdateProfile, data: profileData);
    } catch (e) {
      _handleError(e, 'profile_update_failed'.tr);
      rethrow; // Rethrow so completeSignup knows it failed
    } finally {
      if (setLoading) {
        isLoading.value = false;
      }
    }
  }

  Future<void> uploadPhotos() async {
    if (selectedPhotos.isEmpty) return;
    if (_photosUploaded) return;
    if (_photosUploadFuture != null) {
      await _photosUploadFuture;
      return;
    }

    final operation = _uploadPhotosInternal();
    _photosUploadFuture = operation;
    try {
      await operation;
    } finally {
      if (identical(_photosUploadFuture, operation)) {
        _photosUploadFuture = null;
      }
    }
  }

  Future<void> _uploadPhotosInternal() async {
    isProcessing.value = true;
    try {
      for (int i = 0; i < selectedPhotos.length; i++) {
        final file = selectedPhotos[i];
        final optimizedPhoto = await UploadImageOptimizer.optimizeProfilePhoto(
          file,
        );
        final subtype = _imageSubtypeFromPath(optimizedPhoto.path);
        Object? lastError;
        var uploaded = false;

        for (var attempt = 0; attempt < 2 && !uploaded; attempt++) {
          try {
            final formData = FormData.fromMap({
              'photo': await MultipartFile.fromFile(
                optimizedPhoto.path,
                filename:
                    'photo_${DateTime.now().millisecondsSinceEpoch}_$i.${_fileExtensionForSubtype(subtype)}',
                contentType: MediaType('image', subtype),
              ),
              'isMain': i == mainPhotoIndex.value,
            });

            await _api
                .upload(ApiConstants.uploadPhoto, formData)
                .timeout(const Duration(seconds: 45));
            uploaded = true;
          } catch (e) {
            lastError = e;
            if (attempt == 0) {
              await Future.delayed(const Duration(milliseconds: 800));
            }
          }
        }

        if (!uploaded) {
          throw lastError ?? Exception('Photo upload failed at index $i');
        }
      }

      _photosUploaded = true;
      try {
        await _auth.fetchMe().timeout(const Duration(seconds: 15));
      } catch (e) {
        debugPrint('[Signup] fetchMe after photo upload failed: $e');
      }
      debugPrint('[Signup] All photos uploaded successfully');
    } catch (e) {
      _photosUploaded = false;
      _handleError(e, 'photo_upload_failed'.tr);
      rethrow;
    } finally {
      isProcessing.value = false;
    }
  }

  String _imageSubtypeFromPath(String path) {
    final ext = p.extension(path).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
      case '.jpe':
        return 'jpeg';
      case '.png':
        return 'png';
      case '.webp':
        return 'webp';
      case '.heic':
        return 'heic';
      case '.heif':
        return 'heif';
      default:
        return 'jpeg';
    }
  }

  String _fileExtensionForSubtype(String subtype) {
    switch (subtype) {
      case 'jpeg':
        return 'jpg';
      case 'png':
      case 'webp':
      case 'heic':
      case 'heif':
        return subtype;
      default:
        return 'jpg';
    }
  }

  void addPhoto(File file) {
    if (selectedPhotos.length < 6) {
      selectedPhotos.add(file);
      _photosUploaded = false;
    } else {
      Get.snackbar('limit_reached'.tr, 'photo_limit_desc'.tr);
    }
  }

  void removePhoto(int index) {
    if (index < selectedPhotos.length) {
      // If we've already uploaded photos to the DB, we'd need to call a delete endpoint here.
      // For now, satisfy the local list.
      selectedPhotos.removeAt(index);
      if (mainPhotoIndex.value >= selectedPhotos.length) {
        mainPhotoIndex.value = 0;
      }
      _photosUploaded = false;
      _triggerSave();
    }
  }

  void setMainPhoto(int index) {
    mainPhotoIndex.value = index;
    _photosUploaded = false;
    _triggerSave();
  }

  void setSelfie(File file) {
    selfiePhoto.value = file;
    _selfieUploaded = false;
    _selfieVerificationRequested = false;
    _triggerSave();
  }

  Future<void> uploadSelfie() async {
    if (selfiePhoto.value == null) return;
    if (_selfieUploaded) {
      _triggerSelfieVerificationInBackground();
      return;
    }
    if (_selfieUploadFuture != null) {
      await _selfieUploadFuture;
      return;
    }

    final operation = _uploadSelfieInternal();
    _selfieUploadFuture = operation;
    try {
      await operation;
    } finally {
      if (identical(_selfieUploadFuture, operation)) {
        _selfieUploadFuture = null;
      }
    }
  }

  Future<void> _uploadSelfieInternal() async {
    try {
      final optimizedSelfie = await UploadImageOptimizer.optimizeSelfie(
        selfiePhoto.value!,
      );
      final formData = FormData.fromMap({
        'selfie': await MultipartFile.fromFile(
          optimizedSelfie.path,
          filename: 'selfie_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });
      await _api
          .upload(ApiConstants.selfieUpload, formData)
          .timeout(const Duration(seconds: 45));

      _selfieUploaded = true;
      try {
        await _auth.fetchMe().timeout(const Duration(seconds: 15));
      } catch (e) {
        debugPrint('[Signup] fetchMe after selfie upload failed: $e');
      }

      _triggerSelfieVerificationInBackground();
    } catch (e) {
      _selfieUploaded = false;
      _handleError(e, 'selfie_upload_failed'.tr);
      rethrow;
    }
  }

  void _triggerSelfieVerificationInBackground() {
    if (_selfieVerificationRequested) return;
    _selfieVerificationRequested = true;

    unawaited(() async {
      var verificationTriggered = false;
      final verificationService = Get.isRegistered<VerificationService>()
          ? Get.find<VerificationService>()
          : null;

      for (var attempt = 0; attempt < 3 && !verificationTriggered; attempt++) {
        try {
          if (verificationService != null) {
            final result = await verificationService.verifySelfie().timeout(
              const Duration(seconds: 30),
            );
            verificationTriggered = result.success;
          } else {
            await _api
                .post(
                  ApiConstants.selfieVerify,
                  data: const {'selfieVerified': true, 'selfie_verified': true},
                )
                .timeout(const Duration(seconds: 30));
            verificationTriggered = true;
          }
          debugPrint('[Signup] Selfie verification triggered successfully');
        } catch (e) {
          if (attempt < 2) {
            await Future.delayed(Duration(seconds: attempt + 1));
          } else {
            debugPrint('[Signup] Selfie verification trigger failed: $e');
          }
        }
      }

      if (!verificationTriggered) {
        _selfieVerificationRequested = false;
        return;
      }

      if (verificationService != null) {
        try {
          await verificationService.ensureSelfieVerificationPersisted(
            attempts: 2,
          );
        } catch (e) {
          debugPrint(
            '[Signup] selfie verification persistence ensure failed: $e',
          );
        }
      }

      try {
        await _auth.fetchMe().timeout(const Duration(seconds: 15));
      } catch (e) {
        debugPrint('[Signup] fetchMe after selfie verify trigger failed: $e');
      }

      if (Get.isRegistered<VerificationService>()) {
        try {
          await Get.find<VerificationService>().fetchVerificationStatus();
        } catch (e) {
          debugPrint('[Signup] verification status refresh failed: $e');
        }
      }
    }());
  }

  Future<void> completeSignup({bool fastEnterHome = false}) async {
    if (isLoading.value) return;

    final cachedUser = _auth.currentUser.value;

    // final double-check validation
    if (selectedPhotos.length < 2 && _uploadedPhotoCount(cachedUser) < 2) {
      Helpers.showSnackbar(
        message: 'min_photos_required'.trParams({'count': '2'}),
        isError: true,
      );
      return;
    }
    if (selfiePhoto.value == null && !_hasUploadedSelfie(cachedUser)) {
      Helpers.showSnackbar(message: 'selfie_required'.tr, isError: true);
      return;
    }

    isLoading.value = true;
    var enteredHome = false;

    Future<void> enterHomeNow() async {
      if (enteredHome) return;
      enteredHome = true;
      _clearDraft();
      await GetStorage().write(AppConstants.swipeTutorialPendingKey, true);
      Get.offAllNamed(AppRoutes.main);
    }

    try {
      debugPrint('[Signup] Starting final completion flow...');

      if (fastEnterHome) {
        await enterHomeNow();
      }

      await updateProfile();
      var syncedUser = await _auth.fetchMe();

      final backendPhotoCount = _uploadedPhotoCount(syncedUser);
      final hasBackendPhotos = backendPhotoCount >= 2;
      if (hasBackendPhotos) {
        _photosUploaded = true;
      }

      final needsPhotoUpload =
          selectedPhotos.isNotEmpty && !_photosUploaded && !hasBackendPhotos;
      if (needsPhotoUpload) {
        try {
          await uploadPhotos();
        } catch (e) {
          syncedUser = await _auth.fetchMe();
          if (_uploadedPhotoCount(syncedUser) < 2) {
            rethrow;
          }
          _photosUploaded = true;
          debugPrint('[Signup] Photo upload recovered from backend state');
        }
        syncedUser = await _auth.fetchMe();
      }

      final hasBackendSelfie = _hasUploadedSelfie(syncedUser);
      if (hasBackendSelfie) {
        _selfieUploaded = true;
      }

      final needsSelfieUpload = selfiePhoto.value != null && !_selfieUploaded;
      if (needsSelfieUpload && !hasBackendSelfie) {
        try {
          await uploadSelfie();
        } catch (e) {
          syncedUser = await _auth.fetchMe();
          if (!_hasUploadedSelfie(syncedUser)) {
            rethrow;
          }
          _selfieUploaded = true;
          debugPrint('[Signup] Selfie upload recovered from backend state');
        }
        syncedUser = await _auth.fetchMe();
      }

      if (!syncedUser.selfieVerified &&
          Get.isRegistered<VerificationService>()) {
        try {
          final persisted = await Get.find<VerificationService>()
              .ensureSelfieVerificationPersisted(attempts: 2);
          if (persisted) {
            syncedUser = await _auth.fetchMe();
          }
        } catch (e) {
          debugPrint(
            '[Signup] selfie verification persistence check failed: $e',
          );
        }
      }

      await _syncDiscoveryPreference();

      if (locationEnabled.value) {
        try {
          final locationService = Get.find<LocationService>();
          var position = locationService.currentPosition.value;
          position ??= await locationService.getCurrentPosition();

          if (position != null) {
            await _api.patch(
              ApiConstants.updateLocation,
              data: {
                'latitude': position.latitude,
                'longitude': position.longitude,
              },
            );
          }
        } catch (e) {
          debugPrint('[Signup] location sync error: $e');
        }
      }

      debugPrint('[Signup] Refreshing user data...');
      final refreshedUser = await _refreshSignupState();
      if (!_isSignupPersisted(refreshedUser)) {
        debugPrint(
          '[Signup] Completion persisted check still pending; continuing to main.',
        );
      }

      if (!fastEnterHome) {
        await enterHomeNow();
        Helpers.showSnackbar(message: 'welcome_to_methna'.tr);
      }
    } catch (e) {
      debugPrint('[Signup] completeSignup unexpected error: $e');
      if (!enteredHome) {
        _handleError(e, 'Unable to finish signup. Please try again.');
      }
    } finally {
      isLoading.value = false;
      if (enteredHome) {
        Future.delayed(const Duration(seconds: 1), () {
          if (Get.isRegistered<SignupController>()) {
            Get.delete<SignupController>(force: true);
          }
        });
      }
    }
  }

  void toggleHobby(String hobby) {
    if (selectedHobbies.contains(hobby)) {
      selectedHobbies.remove(hobby);
    } else {
      if (selectedHobbies.length >= maxHobbiesSelection) {
        Helpers.showSnackbar(
          message: 'max_hobbies_reached'.trParams({
            'count': '$maxHobbiesSelection',
          }),
          isError: true,
        );
        return;
      }
      selectedHobbies.add(hobby);
    }
    _triggerSave();
  }

  void toggleLanguage(String language) {
    if (selectedLanguages.contains(language)) {
      selectedLanguages.remove(language);
    } else {
      selectedLanguages.add(language);
    }
    _triggerSave();
  }

  void toggleNationality(String nationality) {
    if (selectedNationalities.contains(nationality)) {
      selectedNationalities.remove(nationality);
      _triggerSave();
      return;
    }
    if (selectedNationalities.length >= 2) {
      Helpers.showSnackbar(
        message: 'You can select up to 2 nationalities only.',
        isError: true,
      );
      return;
    }
    selectedNationalities.add(nationality);
    _triggerSave();
  }

  void setPrimaryNationality(String nationality) {
    final secondary = secondaryNationality;
    selectedNationalities
      ..clear()
      ..add(nationality);

    if (secondary != null && secondary != nationality) {
      selectedNationalities.add(secondary);
    }
    _triggerSave();
  }

  void setSecondaryNationality(String? nationality) {
    final primary = primaryNationality;
    if (primary == null || primary.isEmpty) {
      Helpers.showSnackbar(
        message: 'Please select first nationality first.',
        isError: true,
      );
      return;
    }

    selectedNationalities
      ..clear()
      ..add(primary);

    if (nationality != null &&
        nationality.isNotEmpty &&
        nationality != primary) {
      selectedNationalities.add(nationality);
    }
    _triggerSave();
  }

  void setEthnicity(String ethnicity) {
    selectedEthnicity.value = ethnicity;
    _triggerSave();
  }

  void setSkinComplexion(String value) {
    selectedSkinComplexion.value = value;
    _triggerSave();
  }

  void setBodyBuild(String value) {
    selectedBodyBuild.value = value;
    _triggerSave();
  }

  void setHasChildren(bool value) {
    hasChildren.value = value;
    if (!value) {
      numberOfChildrenController.clear();
    }
    _triggerSave();
  }

  void setWillingToRelocate(bool value) {
    willingToRelocate.value = value;
    _triggerSave();
  }

  void toggleFamilyValue(String value) {
    if (selectedFamilyValues.contains(value)) {
      selectedFamilyValues.remove(value);
    } else {
      selectedFamilyValues.add(value);
    }
    _triggerSave();
  }

  void setMarriageTimeline(String timelineKey) {
    selectedMarriageTimeline.value = timelineKey;
    _triggerSave();
  }

  // ─── Error Handling Helper ────────────────────────────────
  void _handleError(dynamic e, String defaultMessage) {
    debugPrint('[Signup] Error Details: $e');

    if (e is DioException) {
      // ── SENIOR SESSION RECOVERY: Handle Unauthorized 401 ──
      if (e.response?.statusCode == 401) {
        _showSessionExpiredDialog();
        return;
      }

      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        final msg = data['message'];
        final errorMsg = msg is List ? msg.join('\n') : msg.toString();
        Helpers.showSnackbar(message: errorMsg, isError: true);
        return;
      }
    }

    final extracted = (e != null) ? Helpers.extractErrorMessage(e) : null;
    Helpers.showSnackbar(
      message: (extracted != null && extracted != 'something_went_wrong'.tr)
          ? extracted
          : defaultMessage,
      isError: true,
    );
  }

  void _showSessionExpiredDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(LucideIcons.shieldAlert, color: AppColors.primary),
            const SizedBox(width: 12),
            Text('session_expired'.tr),
          ],
        ),
        content: Text('session_expired_signup_msg'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'cancel'.tr,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back(); // Close dialog
              Get.offAllNamed(AppRoutes.login);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text('login'.tr),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  @override
  void onClose() {
    _usernameWorker?.dispose();
    _draftWorker?.dispose();

    final controllers = [
      usernameController,
      firstNameController,
      lastNameController,
      emailController,
      phoneController,
      cityController,
      passwordController,
      confirmPasswordController,
      otpController,
      jobTitleController,
      companyController,
      heightController,
      weightController,
      numberOfChildrenController,
      bioController,
      describeIdealSpouseController,
    ];

    for (var c in controllers) {
      c.dispose();
    }

    super.onClose();
  }
}
