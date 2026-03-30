import 'dart:io';
import 'package:dio/dio.dart' hide Headers;
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;
import 'package:get_storage/get_storage.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:methna_app/app/data/services/auth_service.dart';
import 'package:methna_app/app/data/services/api_service.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/data/services/location_service.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/core/constants/api_constants.dart';
import 'package:methna_app/core/constants/app_constants.dart';
import 'package:methna_app/core/utils/helpers.dart';
import 'signup_data.dart';

class SignupController extends GetxController {
  // ─── Constants & Dependencies ──────────────────────────────
  static const int totalSteps = 12;
  static const String _draftKey = AppConstants.signupDraftKey;

  final AuthService _auth = Get.find<AuthService>();
  final ApiService _api = Get.find<ApiService>();

  // ─── Step Tracking State ───────────────────────────────────
  final RxInt currentStep = 0.obs;
  final RxBool isLoading = false.obs;
  final RxBool isProcessing = false.obs;
  bool _navigating = false;
  bool _isDirty = false;
  bool _isLoadingDraft = false;
  
  // ─── Workers & Triggers ─────────────────────────────────────
  Worker? _usernameWorker;
  Worker? _draftWorker;
  final RxInt _draftTrigger = 0.obs;

  // ─── Step 1: Username ──────────────────────────────────────
  final usernameController = TextEditingController();
  final RxBool usernameAvailable = false.obs;
  final RxBool checkingUsername = false.obs;
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
  final bioController = TextEditingController();

  // ─── Step 9: Photos ────────────────────────────────────────
  final RxList<File> selectedPhotos = <File>[].obs;
  final RxInt mainPhotoIndex = 0.obs;

  // ─── Step 10: Selfie ──────────────────────────────────────
  final Rx<File?> selfiePhoto = Rx<File?>(null);

  // ─── Step 11: Location ─────────────────────────────────────
  final RxBool locationEnabled = false.obs;
  final RxString selectedCountry = 'Algeria'.obs;
  final RxString selectedCity = ''.obs;

  List<String> get availableCities => SignupData.countryCities[selectedCountry.value] ?? [];
  List<String> get arabicCountries => SignupData.arabicCountries;

  // ─── Loading states ────────────────────────────────────────
  final RxBool obscurePassword = true.obs;
  final RxBool agreePrivacy = false.obs;

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
    if (idx != null && (currentStep.value != idx || Get.currentRoute != route)) {
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
        final val = usernameController.text.trim().toLowerCase();
        if (val.isEmpty) {
          usernameAvailable.value = false;
          checkingUsername.value = false;
          usernameError.value = '';
          return;
        }
        if (val.length < 3) {
          usernameError.value = 'username_min'.tr;
          usernameAvailable.value = false;
          return;
        }
        
        // This triggers the debounce Worker above
        if (val != debouncedUsername.value) {
          usernameError.value = '';
          checkingUsername.value = true;
          debouncedUsername.value = val;
        }
      });
    }
  }

  Future<void> _checkUsername(String value) async {
    if (value.length < 3) {
      checkingUsername.value = false;
      usernameAvailable.value = false;
      return;
    }
    
    checkingUsername.value = true;
    try {
      debugPrint('[Signup] Checking username: $value');
      final response = await _api.get(ApiConstants.checkUsername, queryParameters: {'username': value.toLowerCase()});
      debugPrint('[Signup] Username check response: ${response.data}');
      
      // Handle both unwrapped {available: true} and raw response
      final data = response.data;
      bool isAvailable = false;
      if (data is Map) {
        isAvailable = data['available'] == true;
      } else if (data is bool) {
        isAvailable = data;
      }
      
      // Only update if the username hasn't changed while we were checking
      if (debouncedUsername.value == value) {
        usernameAvailable.value = isAvailable;
        usernameError.value = isAvailable ? '' : 'username_taken'.tr;
      }
    } catch (e) {
      debugPrint('[Signup] Username check ERROR: $e');
      // Don't block user on network errors — allow them to proceed
      if (debouncedUsername.value == value) {
        usernameAvailable.value = false;
        usernameError.value = 'username_check_fail'.tr;
      }
    } finally {
      checkingUsername.value = false;
    }
  }

  final List<String> stepRoutes = [
    AppRoutes.signupUsername,      // 0
    AppRoutes.signupGender,        // 1
    AppRoutes.signupMaritalStatus, // 2
    AppRoutes.signupProfileDetails,// 3
    AppRoutes.signupBirthday,      // 4
    AppRoutes.signupEmailVerification, // 5
    AppRoutes.signupFaithReligion, // 6
    AppRoutes.signupHobbies,       // 7
    AppRoutes.signupProfession,    // 8
    AppRoutes.signupPhotos,        // 9
    AppRoutes.signupSelfie,        // 10
    AppRoutes.signupLocation,      // 11
  ];

  @override
  void onInit() {
    super.onInit();
    _loadDraft();

    final List<RxInterface> autoSaveFields = [
      selectedGender, selectedMaritalStatus, dateOfBirth, 
      selectedSect, selectedReligiousLevel, selectedPrayerFrequency,
      selectedDietary, selectedAlcohol, selectedHijab,
      selectedEducation, locationEnabled, selectedCountry, selectedCity,
      mainPhotoIndex, selfiePhoto,
    ];
    for (var field in autoSaveFields) {
      ever(field, (_) => _triggerSave());
    }
    
    // Auto-save hobbies & photos
    ever(selectedHobbies, (_) => _triggerSave());
    ever(selectedPhotos, (_) => _triggerSave());

    // Debounced auto-save for text controllers
    final textControllers = [
      usernameController, firstNameController, lastNameController,
      emailController, phoneController, jobTitleController,
      companyController, heightController, bioController,
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
          _checkUsername(savedUsername);
        }
      }
      if (draft['gender'] != null) selectedGender.value = draft['gender'];
      if (draft['maritalStatus'] != null) selectedMaritalStatus.value = draft['maritalStatus'];
      if (draft['firstName'] != null) firstNameController.text = draft['firstName'];
      if (draft['lastName'] != null) lastNameController.text = draft['lastName'];
      if (draft['email'] != null) emailController.text = draft['email'];
      if (draft['phone'] != null) phoneController.text = draft['phone'];
      if (draft['dob'] != null) dateOfBirth.value = DateTime.tryParse(draft['dob']);
      if (draft['sect'] != null) selectedSect.value = draft['sect'];
      if (draft['religiousLevel'] != null) selectedReligiousLevel.value = draft['religiousLevel'];
      if (draft['prayerFrequency'] != null) selectedPrayerFrequency.value = draft['prayerFrequency'];
      if (draft['dietary'] != null) selectedDietary.value = draft['dietary'];
      if (draft['alcohol'] != null) selectedAlcohol.value = draft['alcohol'];
      if (draft['hijabStatus'] != null) selectedHijab.value = draft['hijabStatus'];
      if (draft['hobbies'] != null) selectedHobbies.assignAll(List<String>.from(draft['hobbies']));
      if (draft['jobTitle'] != null) jobTitleController.text = draft['jobTitle'];
      if (draft['education'] != null) selectedEducation.value = draft['education'];
      if (draft['company'] != null) companyController.text = draft['company'];
      if (draft['height'] != null) heightController.text = draft['height'];
      if (draft['bio'] != null) bioController.text = draft['bio'];
      if (draft['country'] != null) selectedCountry.value = draft['country'];
      if (draft['city'] != null) selectedCity.value = draft['city'];
      if (draft['locationEnabled'] != null) locationEnabled.value = draft['locationEnabled'];
      
      if (draft['photoPaths'] != null) {
        final paths = List<String>.from(draft['photoPaths']);
        // Senior Fix: Defer photo loading until after transition to avoid main-thread block
        Future.delayed(const Duration(milliseconds: 800), () {
          selectedPhotos.assignAll(paths.map((p) => File(p)).toList());
          debugPrint('[Signup] Deferred photos loaded: ${selectedPhotos.length}');
        });
      }
      if (draft['mainPhotoIndex'] != null) mainPhotoIndex.value = draft['mainPhotoIndex'];
      
      if (draft['selfiePath'] != null) {
        // Defer selfie too
        Future.delayed(const Duration(milliseconds: 1000), () {
           selfiePhoto.value = File(draft['selfiePath']);
        });
      }
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
    if (!_isDirty || _isLoadingDraft) return;
    
    // Senior Fix: Use a background task approach (Future.delayed(0) or compute) 
    // to ensure Disk I/O never blocks the current UI frame during navigation.
    Future.delayed(Duration.zero, () async {
      try {
        final stopwatch = Stopwatch()..start();
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
          'bio': bioController.text,
          'photoPaths': selectedPhotos.map((f) => f.path).toList(),
          'mainPhotoIndex': mainPhotoIndex.value,
          'country': selectedCountry.value,
          'city': selectedCity.value,
          'locationEnabled': locationEnabled.value,
          'lastRoute': Get.currentRoute,
          if (selfiePhoto.value != null) 'selfiePath': selfiePhoto.value!.path,
        };
        
        await GetStorage().write(_draftKey, draft);
        _isDirty = false;
        stopwatch.stop();
        debugPrint('[Signup] Draft saved successfully in ${stopwatch.elapsedMilliseconds}ms');
      } catch (e) {
        debugPrint('[Signup] Failed to save draft: $e');
      }
    });
  }

  void _clearDraft() {
    GetStorage().remove(_draftKey);
    debugPrint('[Signup] Draft cleared');
  }

  void onCountryChanged(String country) {
    selectedCountry.value = country;
    if (availableCities.isNotEmpty) {
      selectedCity.value = availableCities.first;
    } else {
      selectedCity.value = '';
    }
    _triggerSave();
  }

  void navigateTo(String route) {
    if (_navigating) return;
    _navigating = true;
    debugPrint('[Signup] navigateTo: $route');
    Get.focusScope?.unfocus(); 
    syncStep(route);
    _saveDraft(); // Immediate save before navigation to ensure persistence
    Get.toNamed(route);
    Future.delayed(const Duration(milliseconds: 500), () => _navigating = false);
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
    if (_navigating) return;
    _navigating = true;
    Get.focusScope?.unfocus();
    
    final currentIdx = _routeToStep[Get.currentRoute] ?? currentStep.value;
    
    // Senior Persistence Layer: Save data to DB immediately at key checkpoints
    try {
      if (currentIdx == 6 || currentIdx == 8) {
        // Faith, Profession (NOT steps 3-4 — user has no auth token until OTP verification at step 5)
        await updateProfile();
      } else if (currentIdx == 9) {
        // Photos - immediate upload
        await uploadPhotos();
      } else if (currentIdx == 10) {
        // Selfie - immediate upload & verify
        await uploadSelfie();
      }
    } catch (e) {
      debugPrint('[Signup] Immediate persistence failed at step $currentIdx: $e');
      // We don't block navigation here unless it's a critical failure, 
      // but the user might see a snackbar from the called methods.
    }

    final nextIdx = currentIdx + 1;
    final nextRoute = nextIdx < totalSteps ? stepRoutes[nextIdx] : null;
    
    // Senior Validation Layer
    if (!validateStep(currentIdx)) {
      _navigating = false;
      return;
    }

    debugPrint('[Signup] goToNextStep: currentIdx=$currentIdx -> nextIdx=$nextIdx, target=$nextRoute');
    
    if (nextRoute != null) {
      currentStep.value = nextIdx;
      Get.toNamed(nextRoute);
    }
    
    Future.delayed(const Duration(milliseconds: 500), () => _navigating = false);
  }

  bool validateStep(int step) {
    switch (step) {
      case 0: // Username
        if (usernameController.text.trim().isEmpty) {
          _handleError(null, 'username_required'.tr);
          return false;
        }
        if (usernameController.text.trim().length < 3) {
          _handleError(null, 'username_min'.tr);
          return false;
        }
        if (checkingUsername.value) {
          _handleError(null, 'checking_username'.tr);
          return false;
        }
        if (!usernameAvailable.value) {
          _handleError(null, 'username_not_available'.tr);
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
        if (profileFormKey.currentState == null || !profileFormKey.currentState!.validate()) {
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
        if (selectedSect.value.isEmpty || selectedReligiousLevel.value.isEmpty) {
          _handleError(null, 'faith_details_required'.tr);
          return false;
        }
        if (selectedDietary.value.isEmpty || selectedAlcohol.value.isEmpty) {
          _handleError(null, 'diet_and_alcohol_required'.tr);
          return false;
        }
        if (selectedGender.value.toLowerCase() == 'female' && selectedHijab.value.isEmpty) {
          _handleError(null, 'hijab_status_required'.tr);
          return false;
        }
        return true;
      case 7: // Hobbies
        if (selectedHobbies.isEmpty) {
          _handleError(null, 'select_min_hobbies'.trParams({'count': '1'}));
          return false;
        }
        return true;
      case 8: // Profession
        if (jobTitleController.text.isEmpty || selectedEducation.value.isEmpty) {
          _handleError(null, 'profession_required'.tr);
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
    debugPrint('[Signup] registerAccount: email=${emailController.text.trim()}');
    try {
      final result = await _auth.register(
        email: emailController.text.trim(),
        password: passwordController.text,
        confirmPassword: confirmPasswordController.text,
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        username: usernameController.text.trim().isNotEmpty
            ? usernameController.text.trim()
            : null,
        phone: phoneController.text.trim().isNotEmpty
            ? phoneController.text.trim()
            : null,
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

  Future<void> updateProfile() async {
    isLoading.value = true;
    try {
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
        if (selectedGender.value.toLowerCase() == 'female' && selectedHijab.value.isNotEmpty)
          'hijabStatus': _toEnumValue(selectedHijab.value),
        'interests': selectedHobbies.toList(),
        if (selectedEducation.value.isNotEmpty)
          'education': _toEnumValue(selectedEducation.value),
        if (jobTitleController.text.isNotEmpty)
          'jobTitle': jobTitleController.text.trim(),
        if (companyController.text.isNotEmpty)
          'company': companyController.text.trim(),
        if (heightController.text.isNotEmpty)
          'height': int.tryParse(heightController.text),
        if (bioController.text.isNotEmpty)
          'bio': bioController.text.trim(),
        'country': selectedCountry.value,
        if (selectedCity.value.isNotEmpty)
          'city': selectedCity.value,
      };
      
      debugPrint('[SignupController] Updating profile with data: $profileData');
      await _api.post(ApiConstants.createOrUpdateProfile, data: profileData);
    } catch (e) {
      _handleError(e, 'profile_update_failed'.tr);
      rethrow; // Rethrow so completeSignup knows it failed
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> uploadPhotos() async {
    if (selectedPhotos.isEmpty) return;
    
    isProcessing.value = true;
    try {
      final uploadTasks = <Future>[];
      
      for (int i = 0; i < selectedPhotos.length; i++) {
        final file = selectedPhotos[i];
        final formData = FormData.fromMap({
          'photo': await MultipartFile.fromFile(
            file.path, 
            filename: 'photo_${DateTime.now().millisecondsSinceEpoch}_$i.jpg'
          ),
          'isMain': i == mainPhotoIndex.value,
        });
        
        uploadTasks.add(_api.upload(ApiConstants.uploadPhoto, formData));
      }
      
      // Parallelize uploads for senior-level performance
      await Future.wait(uploadTasks);
      debugPrint('[Signup] All photos uploaded successfully');
    } catch (e) {
      _handleError(e, 'photo_upload_failed'.tr);
      rethrow;
    } finally {
      isProcessing.value = false;
    }
  }

  void addPhoto(File file) {
    if (selectedPhotos.length < 6) {
      selectedPhotos.add(file);
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
      _triggerSave();
    }
  }

  void setMainPhoto(int index) {
    mainPhotoIndex.value = index;
    _triggerSave();
  }

  void setSelfie(File file) {
    selfiePhoto.value = file;
    _triggerSave();
  }

  Future<void> uploadSelfie() async {
    if (selfiePhoto.value == null) return;
    try {
      final formData = FormData.fromMap({
        'selfie': await MultipartFile.fromFile(
          selfiePhoto.value!.path,
          filename: 'selfie_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });
      await _api.upload(ApiConstants.selfieUpload, formData);
      
      // ─── SENIOR AUTOMATION: Trigger verification immediately after upload ───
      debugPrint('[Signup] Selfie uploaded, triggering verification...');
      await _api.post(ApiConstants.selfieVerify);
      
      debugPrint('[Signup] Selfie verification triggered successfully');
    } catch (e) {
      _handleError(e, 'selfie_upload_failed'.tr);
      rethrow;
    }
  }

  Future<void> completeSignup() async {
    if (isLoading.value) return;

    // final double-check validation
    if (selectedPhotos.length < 2) {
      Helpers.showSnackbar(message: 'min_photos_required'.trParams({'count': '2'}), isError: true);
      return;
    }
    if (selfiePhoto.value == null) {
      Helpers.showSnackbar(message: 'selfie_required'.tr, isError: true);
      return;
    }

    isLoading.value = true;
    try {
      debugPrint('[Signup] Starting final completion flow...');
      
      // Each step is wrapped individually so one failure doesn't block navigation
      try {
        await updateProfile();
      } catch (e) {
        debugPrint('[Signup] updateProfile failed (non-blocking): $e');
      }

      try {
        await uploadPhotos();
      } catch (e) {
        debugPrint('[Signup] uploadPhotos failed (non-blocking): $e');
      }

      try {
        await uploadSelfie();
      } catch (e) {
        debugPrint('[Signup] uploadSelfie failed (non-blocking): $e');
      }

      if (locationEnabled.value) {
        try {
          final locationService = Get.find<LocationService>();
          var position = locationService.currentPosition.value;
          if (position == null) {
            position = await locationService.getCurrentPosition();
          }

          if (position != null) {
            await _api.patch(ApiConstants.updateLocation, data: {
              'latitude': position.latitude,
              'longitude': position.longitude,
            });
          }
        } catch (e) {
          debugPrint('[Signup] location sync error: $e');
        }
      }
      
      try {
        debugPrint('[Signup] Refreshing user data...');
        await _auth.fetchMe();
      } catch (e) {
        debugPrint('[Signup] fetchMe failed (non-blocking): $e');
      }
      
      _clearDraft(); 
      Helpers.showSnackbar(message: 'welcome_to_methna'.tr);
      Get.offAllNamed(AppRoutes.main);
      
      Future.delayed(const Duration(seconds: 1), () {
        if (Get.isRegistered<SignupController>()) {
          Get.delete<SignupController>(force: true);
        }
      });
    } catch (e) {
      debugPrint('[Signup] completeSignup unexpected error: $e');
      // Even on unexpected error, navigate to home so user is never stuck
      _clearDraft();
      Get.offAllNamed(AppRoutes.main);
    } finally {
      isLoading.value = false;
    }
  }

  void toggleHobby(String hobby) {
    if (selectedHobbies.contains(hobby)) {
      selectedHobbies.remove(hobby);
    } else {
      selectedHobbies.add(hobby);
    }
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
      message: (extracted != null && extracted != 'something_went_wrong'.tr) ? extracted : defaultMessage, 
      isError: true
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
            child: Text('cancel'.tr, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back(); // Close dialog
              _isRedirectingToLogin = true;
              Get.offAllNamed(AppRoutes.login);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: Text('login'.tr),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  bool _isRedirectingToLogin = false;

  @override
  void onClose() {
    _usernameWorker?.dispose();
    _draftWorker?.dispose();
    
    final controllers = [
      usernameController, firstNameController, lastNameController,
      emailController, phoneController, passwordController,
      confirmPasswordController, otpController, jobTitleController,
      companyController, heightController, bioController
    ];
    
    for (var c in controllers) {
      c.dispose();
    }
    
    super.onClose();
  }
}
