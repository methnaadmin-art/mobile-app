import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/profile_controller.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/core/utils/helpers.dart';
import 'package:methna_app/core/widgets/datify_shell.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

/// Modern Edit Profile Screen with Enhanced UX
/// Features: Section-based editing, real-time validation, modern UI
class ModernEditProfileScreen extends StatefulWidget {
  const ModernEditProfileScreen({super.key});

  @override
  State<ModernEditProfileScreen> createState() =>
      _ModernEditProfileScreenState();
}

class _ModernEditProfileScreenState extends State<ModernEditProfileScreen>
    with TickerProviderStateMixin {
  final ProfileController controller = Get.find<ProfileController>();
  late TabController _tabController;

  // Form controllers
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _jobTitleCtrl;
  late final TextEditingController _companyCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _countryCtrl;

  // Form state
  String? _gender;
  String? _maritalStatus;
  String? _education;
  String? _sect;
  String? _religiousLevel;
  String? _prayerFrequency;
  String? _dietary;
  String? _alcohol;
  DateTime? _dateOfBirth;
  List<String> _selectedInterests = [];
  bool _isSaving = false;
  int _completionPercentage = 0;

  final List<String> _interests = [
    'Reading',
    'Travel',
    'Cooking',
    'Sports',
    'Music',
    'Art',
    'Gaming',
    'Fitness',
    'Nature',
    'Photography',
    'Writing',
    'Movies',
    'Technology',
    'Fashion',
    'Volunteering',
    'Dancing',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeFormData();
    _calculateCompletion();
  }

  void _initializeFormData() {
    final user = controller.user.value;
    final profile = user?.profile;

    _firstNameCtrl = TextEditingController(text: user?.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: user?.lastName ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _bioCtrl = TextEditingController(text: profile?.bio ?? '');
    _heightCtrl = TextEditingController(
      text: profile?.height?.toString() ?? '',
    );
    _jobTitleCtrl = TextEditingController(text: profile?.jobTitle ?? '');
    _companyCtrl = TextEditingController(text: profile?.company ?? '');
    _cityCtrl = TextEditingController(text: profile?.city ?? '');
    _countryCtrl = TextEditingController(text: profile?.country ?? '');

    _gender = profile?.gender;
    _maritalStatus = profile?.maritalStatus;
    _education = profile?.education;
    _sect = profile?.sect;
    _religiousLevel = profile?.religiousLevel;
    _prayerFrequency = profile?.prayerFrequency;
    _dietary = profile?.dietary;
    _alcohol = profile?.alcohol;
    _dateOfBirth = profile?.dateOfBirth;
    _selectedInterests = List.from(profile?.interests ?? []);
  }

  void _calculateCompletion() {
    int filled = 0;
    int total = 15; // Total number of important fields

    if (_firstNameCtrl.text.isNotEmpty) filled++;
    if (_lastNameCtrl.text.isNotEmpty) filled++;
    if (_bioCtrl.text.isNotEmpty) filled++;
    if (_gender != null) filled++;
    if (_dateOfBirth != null) filled++;
    if (_maritalStatus != null) filled++;
    if (_education != null) filled++;
    if (_jobTitleCtrl.text.isNotEmpty) filled++;
    if (_heightCtrl.text.isNotEmpty) filled++;
    if (_cityCtrl.text.isNotEmpty) filled++;
    if (_religiousLevel != null) filled++;
    if (_prayerFrequency != null) filled++;
    if (_sect != null) filled++;
    if (_dietary != null) filled++;
    if (_selectedInterests.isNotEmpty) filled++;

    setState(() {
      _completionPercentage = ((filled / total) * 100).round();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    _heightCtrl.dispose();
    _jobTitleCtrl.dispose();
    _companyCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final textColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final cardBg = isDark ? AppColors.cardDark : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(textColor),
      body: DatifyBackground(
        child: Column(
          children: [
            // Progress indicator
            _buildProgressIndicator(textColor, cardBg),

            // Tab bar
            _buildTabBar(textColor),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBasicInfoTab(textColor, cardBg),
                  _buildLifestyleTab(textColor, cardBg),
                  _buildFaithTab(textColor, cardBg),
                ],
              ),
            ),

            // Save button
            _buildSaveButton(textColor),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Color textColor) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Get.back(),
        icon: Icon(LucideIcons.chevronLeft, color: textColor),
      ),
      title: Text(
        'Edit Profile',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : _saveProfile,
          child: _isSaving
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : Text(
                  'Save',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(Color textColor, Color cardBg) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profile Completion',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              Text(
                '$_completionPercentage%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _completionPercentage / 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(Color textColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: textColor.withValues(alpha: 0.7),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: 'Basic Info'),
          Tab(text: 'Lifestyle'),
          Tab(text: 'Faith'),
        ],
      ),
    );
  }

  Widget _buildBasicInfoTab(Color textColor, Color cardBg) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _SectionCard(
            title: 'Personal Information',
            icon: LucideIcons.user,
            children: [
              _buildTextField(
                controller: _firstNameCtrl,
                label: 'First Name',
                hint: 'Enter your first name',
                onChanged: _calculateCompletion,
              ),
              _buildTextField(
                controller: _lastNameCtrl,
                label: 'Last Name',
                hint: 'Enter your last name',
                onChanged: _calculateCompletion,
              ),
              _buildDateField(),
              _buildDropdownField(
                value: _gender,
                label: 'Gender',
                hint: 'Select gender',
                items: ['male', 'female'],
                onChanged: (value) {
                  setState(() => _gender = value);
                  _calculateCompletion();
                },
              ),
              _buildTextField(
                controller: _phoneCtrl,
                label: 'Phone',
                hint: 'Enter phone number',
                keyboardType: TextInputType.phone,
              ),
            ],
          ),

          const SizedBox(height: 20),

          _SectionCard(
            title: 'About You',
            icon: LucideIcons.fileText,
            children: [
              _buildTextAreaField(
                controller: _bioCtrl,
                label: 'Bio',
                hint: 'Tell us about yourself...',
                maxLines: 4,
                onChanged: _calculateCompletion,
              ),
              _buildInterestSelector(),
            ],
          ),

          const SizedBox(height: 20),

          _SectionCard(
            title: 'Professional',
            icon: LucideIcons.briefcase,
            children: [
              _buildTextField(
                controller: _jobTitleCtrl,
                label: 'Job Title',
                hint: 'Enter your job title',
                onChanged: _calculateCompletion,
              ),
              _buildTextField(
                controller: _companyCtrl,
                label: 'Company',
                hint: 'Enter company name',
              ),
              _buildDropdownField(
                value: _education,
                label: 'Education',
                hint: 'Select education level',
                items: ['high_school', 'bachelors', 'masters', 'phd'],
                onChanged: (value) {
                  setState(() => _education = value);
                  _calculateCompletion();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLifestyleTab(Color textColor, Color cardBg) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _SectionCard(
            title: 'Location',
            icon: LucideIcons.mapPin,
            children: [
              _buildTextField(
                controller: _cityCtrl,
                label: 'City',
                hint: 'Enter your city',
                onChanged: _calculateCompletion,
              ),
              _buildTextField(
                controller: _countryCtrl,
                label: 'Country',
                hint: 'Enter your country',
              ),
            ],
          ),

          const SizedBox(height: 20),

          _SectionCard(
            title: 'Physical',
            icon: LucideIcons.user,
            children: [
              _buildTextField(
                controller: _heightCtrl,
                label: 'Height (cm)',
                hint: 'Enter height',
                keyboardType: TextInputType.number,
                onChanged: _calculateCompletion,
              ),
              _buildDropdownField(
                value: _maritalStatus,
                label: 'Marital Status',
                hint: 'Select marital status',
                items: ['never_married', 'divorced', 'widowed', 'married'],
                onChanged: (value) {
                  setState(() => _maritalStatus = value);
                  _calculateCompletion();
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          _SectionCard(
            title: 'Habits',
            icon: LucideIcons.heart,
            children: [
              _buildDropdownField(
                value: _dietary,
                label: 'Dietary Preferences',
                hint: 'Select dietary preference',
                items: [
                  'halal',
                  'mostly_halal',
                  'sometimes_halal',
                  'non_halal',
                ],
                onChanged: (value) {
                  setState(() => _dietary = value);
                  _calculateCompletion();
                },
              ),
              _buildDropdownField(
                value: _alcohol,
                label: 'Alcohol',
                hint: 'Select alcohol preference',
                items: ['never', 'rarely', 'occasionally', 'frequently'],
                onChanged: (value) {
                  setState(() => _alcohol = value);
                  _calculateCompletion();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFaithTab(Color textColor, Color cardBg) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _SectionCard(
            title: 'Religious Information',
            icon: LucideIcons.moon,
            children: [
              _buildDropdownField(
                value: _religiousLevel,
                label: 'Religious Level',
                hint: 'How religious are you?',
                items: ['very_practicing', 'practicing', 'moderate', 'liberal'],
                onChanged: (value) {
                  setState(() => _religiousLevel = value);
                  _calculateCompletion();
                },
              ),
              _buildDropdownField(
                value: _prayerFrequency,
                label: 'Prayer Frequency',
                hint: 'How often do you pray?',
                items: [
                  'actively_practicing',
                  'occasionally',
                  'not_practicing',
                ],
                onChanged: (value) {
                  setState(() => _prayerFrequency = value);
                  _calculateCompletion();
                },
              ),
              _buildDropdownField(
                value: _sect,
                label: 'Sect',
                hint: 'Select your sect',
                items: ['sunni', 'shia', 'other'],
                onChanged: (value) {
                  setState(() => _sect = value);
                  _calculateCompletion();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(Color textColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSaving
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('saving'.tr),
                ],
              )
            : Text(
                'save_profile'.tr,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final profileData = {
        'bio': _bioCtrl.text.trim(),
        'gender': _gender,
        'dateOfBirth': _dateOfBirth?.toIso8601String(),
        'maritalStatus': _maritalStatus,
        'education': _education,
        'jobTitle': _jobTitleCtrl.text.trim(),
        'company': _companyCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'country': _countryCtrl.text.trim(),
        'height': int.tryParse(_heightCtrl.text),
        'religiousLevel': _religiousLevel,
        'prayerFrequency': _prayerFrequency,
        'sect': _sect,
        'dietary': _dietary,
        'alcohol': _alcohol,
        'interests': _selectedInterests,
      };

      final userData = {
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      };

      final success = await controller.updateProfile({...userData, ...profileData});

      if (!mounted || !success) return;

      await controller.refreshProfile();
      // Dismiss the edit screen and reveal the underlying profile screen.
      if (mounted && Get.key.currentState?.canPop() == true) {
        Get.back(result: true);
      }
    } catch (e) {
      debugPrint('[EditProfile] Error saving: $e');
      Helpers.showSnackbar(message: 'failed_to_save_profile'.tr, isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // Helper widgets
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    VoidCallback? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            onChanged: (_) => onChanged?.call(),
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              filled: true,
              fillColor: Theme.of(context).inputDecorationTheme.fillColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextAreaField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required int maxLines,
    VoidCallback? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            onChanged: (_) => onChanged?.call(),
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              filled: true,
              fillColor: Theme.of(context).inputDecorationTheme.fillColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String label,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: (value != null && items.contains(value)) ? value : null,
            hint: Text(hint),
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(
                  StringExtension(item.replaceAll('_', ' ')).capitalizeFirst,
                ),
              );
            }).toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              filled: true,
              fillColor: Theme.of(context).inputDecorationTheme.fillColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Date of Birth',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).inputDecorationTheme.fillColor,
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.calendar,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _dateOfBirth != null
                        ? Helpers.formatDate(_dateOfBirth!)
                        : 'Select date of birth',
                    style: TextStyle(
                      color: _dateOfBirth != null
                          ? Theme.of(context).textTheme.bodyMedium?.color
                          : Theme.of(context).hintColor,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    LucideIcons.chevronDown,
                    color: Theme.of(context).iconTheme.color,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Interests',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.titleMedium?.color,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _interests.map((interest) {
            final isSelected = _selectedInterests.contains(interest);
            return FilterChip(
              label: Text(interest),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedInterests.add(interest);
                  } else {
                    _selectedInterests.remove(interest);
                  }
                  _calculateCompletion();
                });
              },
              backgroundColor: Theme.of(context).chipTheme.backgroundColor,
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected
                    ? AppColors.primary
                    : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          _dateOfBirth ??
          DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 80)),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
    );

    if (date != null) {
      setState(() {
        _dateOfBirth = date;
        _calculateCompletion();
      });
    }
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : Colors.white;
    final textColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String get capitalizeFirst {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}

