import 'package:cached_network_image/cached_network_image.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:methna_app/app/controllers/profile_controller.dart';
import 'package:methna_app/app/controllers/signup_data.dart';
import 'package:methna_app/app/data/models/user_model.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/core/utils/cloudinary_url.dart';
import 'package:methna_app/core/utils/google_fonts_stub.dart';
import 'package:methna_app/core/utils/helpers.dart';
import 'package:methna_app/core/utils/profile_option_icons.dart';

class BeautifulEditProfileScreen extends StatefulWidget {
  const BeautifulEditProfileScreen({super.key});

  @override
  State<BeautifulEditProfileScreen> createState() =>
      _BeautifulEditProfileScreenState();
}

class _BeautifulEditProfileScreenState
    extends State<BeautifulEditProfileScreen> {
  final ProfileController controller = Get.find<ProfileController>();

  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _jobTitleCtrl;
  late final TextEditingController _companyCtrl;
  late final TextEditingController _idealSpouseCtrl;

  String? _country;
  String? _nationality;
  String? _city;
  String? _gender;
  String? _maritalStatus;
  String? _education;
  String? _skinComplexion;
  String? _bodyBuild;
  String? _sect;
  String? _religiousLevel;
  String? _prayerFrequency;
  String? _dietary;
  String? _alcohol;
  String? _relationshipGoal;
  String? _marriageIntention;
  String? _familyPlans;
  String? _communicationStyle;
  bool? _vaccinationStatus;
  String? _bloodType;
  String? _workoutFrequency;
  String? _sleepSchedule;
  String? _socialMediaUsage;
  bool? _hasPets;
  String? _petPreference;
  bool? _willingToRelocate;
  DateTime? _dateOfBirth;
  List<String> _selectedInterests = [];
  List<String> _selectedLanguages = [];
  bool _isSaving = false;

  static const List<String> _interestOptions = [
    'Travel',
    'Cooking',
    'Hiking',
    'Yoga',
    'Gaming',
    'Movies',
    'Photography',
    'Music',
    'Pets',
    'Painting',
    'Art',
    'Fitness',
    'Reading',
    'Dancing',
    'Sports',
    'Board Games',
    'Technology',
    'Fashion',
    'Motorcycling',
    'Science',
    'History',
    'Nature',
    'Adventure',
    'Gardening',
    'Foodie',
    'Writing',
    'Poetry',
    'Astronomy',
    'Sustainable Living',
    'Film Production',
    'Meditation',
    'Comedy',
    'Volunteering',
    'DIY Projects',
    'Art History',
    'Philosophy',
    'Snowboarding',
    'Collectibles',
    'Sailing',
    'Karaoke',
    'Surfing',
    'Scuba Diving',
    'Skydiving',
    'Pottery',
    'Wildlife Conservation',
    'Ghost Hunting',
    'Geocaching',
    'Stand-up Comedy',
    'Motor Racing',
  ];

  static const List<String> _languageOptions = [
    'English',
    'Chinese',
    'Hindi',
    'Arabic',
    'Bengali',
    'Spanish',
    'Portuguese',
    'Russian',
    'Punjabi',
    'Japanese',
    'French',
    'German',
    'Malay',
    'Telugu',
    'Urdu',
    'Turkish',
    'Marathi',
    'Tamil',
    'Korean',
    'Vietnamese',
    'Italian',
    'Thai',
    'Filipino (Tagalog)',
    'Swahili',
    'Dutch',
    'Polish',
    'Ukrainian',
    'Romanian',
    'Greek',
    'Nepali',
    'Hungarian',
    'Czech',
    'Danish',
    'Hebrew',
    'Swedish',
    'Finnish',
    'Norwegian',
    'Slovak',
    'Bulgarian',
  ];

  static const List<String> _religionOptions = [
    'Sunni',
    'Shia',
    'Sufi',
    'Other',
    'Prefer not to say',
  ];

  static const List<_ChoiceOption> _maritalStatusOptions = [
    _ChoiceOption(label: 'Never Married', value: 'never_married'),
    _ChoiceOption(label: 'Divorced', value: 'divorced'),
    _ChoiceOption(label: 'Widowed', value: 'widowed'),
    _ChoiceOption(label: 'Married', value: 'married'),
  ];

  static const List<_ChoiceOption> _religiousLevelOptions = [
    _ChoiceOption(label: 'Very Practicing', value: 'very_practicing'),
    _ChoiceOption(label: 'Practicing', value: 'practicing'),
    _ChoiceOption(label: 'Moderate', value: 'moderate'),
    _ChoiceOption(label: 'Liberal', value: 'liberal'),
  ];

  static const List<_ChoiceOption> _prayerFrequencyOptions = [
    _ChoiceOption(label: 'Actively Practicing', value: 'actively_practicing'),
    _ChoiceOption(label: 'Occasionally', value: 'occasionally'),
    _ChoiceOption(label: 'Not Practicing', value: 'not_practicing'),
  ];

  static const List<_GoalOption> _relationshipGoals = [
    _GoalOption(
      label: 'Marriage Soon',
      value: 'serious_marriage:within_months',
      intentMode: 'serious_marriage',
      marriageIntention: 'within_months',
      description:
          'Ready to involve family and move toward marriage in the near future.',
    ),
    _GoalOption(
      label: 'Serious Marriage',
      value: 'serious_marriage:within_year',
      intentMode: 'serious_marriage',
      marriageIntention: 'within_year',
      description:
          'Looking for a sincere match with a serious intention toward marriage.',
    ),
    _GoalOption(
      label: 'Family Introduction',
      value: 'family_introduction:within_months',
      intentMode: 'family_introduction',
      marriageIntention: 'within_months',
      description:
          'Prefer a respectful path that involves families from the beginning.',
    ),
    _GoalOption(
      label: 'Getting to Know',
      value: 'exploring:one_to_two_years',
      intentMode: 'exploring',
      marriageIntention: 'one_to_two_years',
      description:
          'Open to a thoughtful period of getting to know someone for marriage.',
    ),
    _GoalOption(
      label: 'Not Sure Yet',
      value: 'exploring:not_sure',
      intentMode: 'exploring',
      marriageIntention: 'not_sure',
      description:
          'Still learning what feels right, but only open to respectful intentions.',
    ),
  ];

  static const List<_ChoiceOption> _familyPlansOptions = [
    _ChoiceOption(label: 'Want Kids', value: 'wants_children'),
    _ChoiceOption(label: 'Do not Want Kids', value: 'doesnt_want'),
    _ChoiceOption(label: 'Not Sure Yet', value: 'open_to_it'),
    _ChoiceOption(label: 'Have Kids & Want More', value: 'has_and_wants_more'),
    _ChoiceOption(label: 'Have Kids & Done', value: 'has_and_done'),
  ];

  static const List<_ChoiceOption> _vaccinationOptions = [
    _ChoiceOption(label: 'Vaccinated', value: true),
    _ChoiceOption(label: 'Unvaccinated', value: false),
    _ChoiceOption(label: 'Prefer Not to Say', value: null),
  ];

  static const List<_ChoiceOption> _communicationOptions = [
    _ChoiceOption(label: 'Chatty Cathy', value: 'chatty_cathy'),
    _ChoiceOption(label: 'Listener', value: 'listener'),
    _ChoiceOption(label: 'Joker', value: 'joker'),
    _ChoiceOption(label: 'Deep Thinker', value: 'deep_thinker'),
    _ChoiceOption(label: 'Sarcastic Wit', value: 'sarcastic_wit'),
    _ChoiceOption(label: 'Easygoing', value: 'easygoing'),
    _ChoiceOption(label: 'Straight Shooter', value: 'straight_shooter'),
    _ChoiceOption(label: 'Storyteller', value: 'storyteller'),
  ];

  static const List<_ChoiceOption> _willingToRelocateOptions = [
    _ChoiceOption(label: 'Yes', value: true),
    _ChoiceOption(label: 'No', value: false),
  ];

  static const List<_ChoiceOption> _bloodTypeOptions = [
    _ChoiceOption(label: 'A+', value: 'A+'),
    _ChoiceOption(label: 'A-', value: 'A-'),
    _ChoiceOption(label: 'AB+', value: 'AB+'),
    _ChoiceOption(label: 'AB-', value: 'AB-'),
    _ChoiceOption(label: 'B+', value: 'B+'),
    _ChoiceOption(label: 'B-', value: 'B-'),
    _ChoiceOption(label: 'O+', value: 'O+'),
    _ChoiceOption(label: 'O-', value: 'O-'),
  ];

  static const List<_ChoiceOption> _petsOptions = [
    _ChoiceOption(label: 'None', value: 'none'),
    _ChoiceOption(label: 'Dog', value: 'dog'),
    _ChoiceOption(label: 'Cat', value: 'cat'),
    _ChoiceOption(label: 'Fish', value: 'fish'),
    _ChoiceOption(label: 'Bird', value: 'bird'),
    _ChoiceOption(label: 'Rabbit', value: 'rabbit'),
    _ChoiceOption(label: 'Hamster', value: 'hamster'),
    _ChoiceOption(label: 'Reptile', value: 'reptile'),
    _ChoiceOption(label: 'Exotic Pet', value: 'exotic_pet'),
    _ChoiceOption(label: 'Other', value: 'other'),
  ];

  static const List<_ChoiceOption> _drinkingOptions = [
    _ChoiceOption(label: 'Does not drink', value: 'doesnt_drink'),
    _ChoiceOption(label: 'Occasionally', value: 'drinks'),
  ];

  static const List<_ChoiceOption> _workoutOptions = [
    _ChoiceOption(label: 'Everyday', value: 'daily'),
    _ChoiceOption(label: 'Often', value: 'several_times_week'),
    _ChoiceOption(label: 'Sometimes', value: 'once_a_week'),
    _ChoiceOption(label: 'Never', value: 'never'),
  ];

  static const List<_ChoiceOption> _dietaryOptions = [
    _ChoiceOption(label: 'Halal', value: 'halal'),
    _ChoiceOption(label: 'No special preference', value: 'non_strict'),
  ];

  static const List<_ChoiceOption> _socialMediaOptions = [
    _ChoiceOption(label: 'Active on All', value: 'very_active'),
    _ChoiceOption(label: 'Active on Some', value: 'moderate'),
    _ChoiceOption(label: 'Minimal Social Media Presence', value: 'minimal'),
    _ChoiceOption(label: 'Social Media Influencer', value: 'influencer'),
  ];

  static const List<_ChoiceOption> _sleepOptions = [
    _ChoiceOption(label: 'Early Bird', value: 'early_bird'),
    _ChoiceOption(label: 'Night Owl', value: 'night_owl'),
    _ChoiceOption(label: 'Regular Sleeper', value: 'flexible'),
    _ChoiceOption(label: 'Insomniac', value: 'insomniac'),
  ];

  static const List<_ChoiceOption> _skinComplexionOptions = [
    _ChoiceOption(label: 'Very Fair', value: 'very_fair'),
    _ChoiceOption(label: 'Fair', value: 'fair'),
    _ChoiceOption(label: 'Medium', value: 'medium'),
    _ChoiceOption(label: 'Olive', value: 'olive'),
    _ChoiceOption(label: 'Dark', value: 'dark'),
    _ChoiceOption(label: 'Prefer not to say', value: 'prefer_not_to_say'),
  ];

  static const List<_ChoiceOption> _bodyBuildOptions = [
    _ChoiceOption(label: 'Slim', value: 'slim'),
    _ChoiceOption(label: 'Average', value: 'average'),
    _ChoiceOption(label: 'Athletic', value: 'athletic'),
    _ChoiceOption(label: 'Curvy', value: 'curvy'),
    _ChoiceOption(label: 'Prefer not to say', value: 'prefer_not_to_say'),
  ];

  @override
  void initState() {
    super.initState();
    _initializeFormData();
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
    _weightCtrl = TextEditingController(
      text: profile?.weight?.toString() ?? '',
    );
    _jobTitleCtrl = TextEditingController(text: profile?.jobTitle ?? '');
    _companyCtrl = TextEditingController(text: profile?.company ?? '');
    _idealSpouseCtrl = TextEditingController(
      text: profile?.aboutPartner ?? '',
    );

    _country = profile?.country;
    _nationality = profile?.nationality;
    _city = profile?.city;
    _gender = profile?.gender;
    _maritalStatus = profile?.maritalStatus;
    _education = profile?.education;
    _skinComplexion = profile?.skinComplexion;
    _bodyBuild = profile?.bodyBuild;
    _sect = profile?.sect;
    _religiousLevel = profile?.religiousLevel;
    _prayerFrequency = profile?.prayerFrequency;
    _dietary = profile?.dietary;
    _alcohol = profile?.alcohol;
    _familyPlans = profile?.familyPlans;
    _communicationStyle = _normalizeCommunicationStyle(profile?.communicationStyle);
    _vaccinationStatus = profile?.vaccinationStatus;
    _bloodType = profile?.bloodType;
    _workoutFrequency = profile?.workoutFrequency;
    _sleepSchedule = _normalizeSleepSchedule(profile?.sleepSchedule);
    _socialMediaUsage = _normalizeSocialMediaUsage(profile?.socialMediaUsage);
    _hasPets = profile?.hasPets;
    _petPreference = profile?.petPreference;
    _willingToRelocate = profile?.willingToRelocate;
    _dateOfBirth = profile?.dateOfBirth;
    _selectedInterests = List<String>.from(profile?.interests ?? const []);
    _selectedLanguages = List<String>.from(profile?.languages ?? const []);
    _marriageIntention = profile?.marriageIntention?.trim();
    _relationshipGoal = _composeGoalValue(
      profile?.intentMode?.trim(),
      profile?.marriageIntention?.trim(),
    );
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _jobTitleCtrl.dispose();
    _companyCtrl.dispose();
    _idealSpouseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = controller.user.value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0D14)
          : AppColors.smoothBeige,
      body: SafeArea(
        child: user == null
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : Column(
                children: [
                  _EditProfileTopBar(
                    isSaving: _isSaving,
                    onClose: () => Get.back(),
                    onSave: _isSaving ? null : _saveProfile,
                  ),
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
                      children: [
                        const _SectionHeader(label: 'Your profile'),
                        const SizedBox(height: 10),
                        _PhotoStrip(
                          user: user,
                          onTap: controller.openEditPhotos,
                        ),
                        const SizedBox(height: 12),
                        _EditFieldTile(
                          label: 'About Me',
                          large: true,
                          child: TextField(
                            controller: _bioCtrl,
                            maxLines: 5,
                            style: _fieldValueStyle(),
                            decoration: _inputDecoration(
                              hint: 'Tell people about yourself',
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _EditFieldTile(
                                label: 'First Name',
                                child: TextField(
                                  controller: _firstNameCtrl,
                                  style: _fieldValueStyle(),
                                  decoration: _inputDecoration(
                                    hint: 'First name',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _EditFieldTile(
                                label: 'Last Name',
                                child: TextField(
                                  controller: _lastNameCtrl,
                                  style: _fieldValueStyle(),
                                  decoration: _inputDecoration(
                                    hint: 'Last name',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _SelectFieldTile(
                                label: 'Birthday',
                                value: _dateOfBirth == null
                                    ? 'Select'
                                    : Helpers.formatDate(_dateOfBirth!),
                                onTap: _pickDate,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SelectFieldTile(
                                label: 'Gender',
                                value: _displayOrPlaceholder(
                                  _gender,
                                  placeholder: 'Select',
                                ),
                                onTap: () => _showSimpleOptions(
                                  title: 'Gender',
                                  options: const ['male', 'female'],
                                  current: _gender,
                                  onSelected: (value) {
                                    setState(() => _gender = value);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _SelectFieldTile(
                                label: 'Country',
                                value: _countryDisplayValue(
                                  _country,
                                  placeholder: 'Select',
                                ),
                                onTap: () => _pickCountry(
                                  onSelect: (country) {
                                    setState(() {
                                      final selected = _normalizeCountryAlias(
                                        country.name,
                                      );
                                      if (_country != selected) {
                                        _city = null;
                                      }
                                      _country = selected;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SelectFieldTile(
                                label: 'City',
                                value: _displayOrPlaceholder(
                                  _city,
                                  placeholder: 'Select',
                                ),
                                enabled: _country != null,
                                onTap: _country == null
                                    ? null
                                    : _pickCity,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _SelectFieldTile(
                          label: 'Nationality',
                          value: _countryDisplayValue(
                            _nationality,
                            placeholder: 'Select',
                          ),
                          onTap: () => _pickCountry(
                            onSelect: (country) {
                              setState(
                                () => _nationality = _normalizeCountryAlias(
                                  country.name,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _EditFieldTile(
                                label: 'Height',
                                child: TextField(
                                  controller: _heightCtrl,
                                  keyboardType: TextInputType.number,
                                  style: _fieldValueStyle(),
                                  decoration: _inputDecoration(hint: 'Height'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _EditFieldTile(
                                label: 'Weight',
                                child: TextField(
                                  controller: _weightCtrl,
                                  keyboardType: TextInputType.number,
                                  style: _fieldValueStyle(),
                                  decoration: _inputDecoration(hint: 'Weight'),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _EditFieldTile(
                                label: 'Job Title',
                                child: TextField(
                                  controller: _jobTitleCtrl,
                                  style: _fieldValueStyle(),
                                  decoration: _inputDecoration(
                                    hint: 'Job title',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _EditFieldTile(
                          label: 'Company',
                          child: TextField(
                            controller: _companyCtrl,
                            style: _fieldValueStyle(),
                            decoration: _inputDecoration(hint: 'Company'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _EditFieldTile(
                          label: 'Phone',
                          child: TextField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            style: _fieldValueStyle(),
                            decoration: _inputDecoration(hint: 'Phone'),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _SectionRowHeader(
                          title: 'Interests',
                          actionLabel: 'See all',
                          onTap: _openInterestsPicker,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _interestPreview().map((interest) {
                            return _PreviewChip(
                              label: interest,
                              icon: interestOptionIcon(interest),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),
                        _EditFieldTile(
                          label: 'Describe ideal spouse',
                          large: true,
                          child: TextField(
                            controller: _idealSpouseCtrl,
                            maxLines: 4,
                            style: _fieldValueStyle(),
                            decoration: _inputDecoration(
                              hint: 'What are you looking for in a spouse?',
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const _SectionRowHeader(
                          title: 'Details',
                          actionLabel: '',
                          onTap: null,
                        ),
                        const SizedBox(height: 10),
                        _SettingsGroup(
                          children: [
                            _SettingsRow(
                              title: 'Languages I Know',
                              value: _countSummary(_selectedLanguages),
                              onTap: _openLanguagesPicker,
                            ),
                            _SettingsRow(
                              title: 'Relationship Goals',
                              value: _relationshipGoalLabel(_relationshipGoal),
                              onTap: _openRelationshipGoalsPicker,
                            ),
                            _SettingsRow(
                              title: 'Religion',
                              value: _displayOrPlaceholder(
                                _sect,
                                placeholder: 'Select religion',
                              ),
                              onTap: _openReligionPicker,
                            ),
                            _SettingsRow(
                              title: 'Skin Complexion',
                              value: _displayOptionValue(
                                _skinComplexionOptions,
                                _skinComplexion,
                                placeholder: 'Select',
                              ),
                              onTap: () => _showSimpleOptions(
                                title: 'Skin Complexion',
                                options: _skinComplexionOptions
                                    .map((option) => option.label)
                                    .toList(),
                                current: _displayOptionValue(
                                  _skinComplexionOptions,
                                  _skinComplexion,
                                  placeholder: '',
                                ),
                                onSelected: (value) {
                                  final selected = _skinComplexionOptions
                                      .firstWhereOrNull(
                                        (option) => option.label == value,
                                      );
                                  if (selected == null) return;
                                  setState(
                                    () => _skinComplexion =
                                        selected.value as String,
                                  );
                                },
                              ),
                            ),
                            _SettingsRow(
                              title: 'Build',
                              value: _displayOptionValue(
                                _bodyBuildOptions,
                                _bodyBuild,
                                placeholder: 'Select',
                              ),
                              onTap: () => _showSimpleOptions(
                                title: 'Build',
                                options: _bodyBuildOptions
                                    .map((option) => option.label)
                                    .toList(),
                                current: _displayOptionValue(
                                  _bodyBuildOptions,
                                  _bodyBuild,
                                  placeholder: '',
                                ),
                                onSelected: (value) {
                                  final selected = _bodyBuildOptions
                                      .firstWhereOrNull(
                                        (option) => option.label == value,
                                      );
                                  if (selected == null) return;
                                  setState(
                                    () => _bodyBuild =
                                        selected.value as String,
                                  );
                                },
                              ),
                            ),
                            _SettingsRow(
                              title: 'Basics',
                              value: _basicsSummary(),
                              onTap: _openBasicsPage,
                            ),
                            _SettingsRow(
                              title: 'Lifestyle',
                              value: _lifestyleSummary(),
                              onTap: _openLifestylePage,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const _SectionRowHeader(
                          title: 'More details',
                          actionLabel: '',
                          onTap: null,
                        ),
                        const SizedBox(height: 10),
                        _SettingsGroup(
                          children: [
                            _SettingsRow(
                              title: 'Religious Level',
                              value: _displayOptionValue(
                                _religiousLevelOptions,
                                _religiousLevel,
                                placeholder: 'Select',
                              ),
                              onTap: () => _showSimpleOptions(
                                title: 'Religious Level',
                                options: _religiousLevelOptions
                                    .map((option) => option.label)
                                    .toList(),
                                current: _displayOptionValue(
                                  _religiousLevelOptions,
                                  _religiousLevel,
                                  placeholder: '',
                                ),
                                onSelected: (value) {
                                  final selected = _religiousLevelOptions
                                      .firstWhereOrNull(
                                        (option) => option.label == value,
                                      );
                                  if (selected == null) return;
                                  setState(
                                    () => _religiousLevel =
                                        selected.value as String,
                                  );
                                },
                              ),
                            ),
                            _SettingsRow(
                              title: 'Prayer Frequency',
                              value: _displayOptionValue(
                                _prayerFrequencyOptions,
                                _prayerFrequency,
                                placeholder: 'Select',
                              ),
                              onTap: () => _showSimpleOptions(
                                title: 'Prayer Frequency',
                                options: _prayerFrequencyOptions
                                    .map((option) => option.label)
                                    .toList(),
                                current: _displayOptionValue(
                                  _prayerFrequencyOptions,
                                  _prayerFrequency,
                                  placeholder: '',
                                ),
                                onSelected: (value) {
                                  final selected = _prayerFrequencyOptions
                                      .firstWhereOrNull(
                                        (option) => option.label == value,
                                      );
                                  if (selected == null) return;
                                  setState(
                                    () => _prayerFrequency =
                                        selected.value as String,
                                  );
                                },
                              ),
                            ),
                            _SettingsRow(
                              title: 'Marital Status',
                              value: _displayOptionValue(
                                _maritalStatusOptions,
                                _maritalStatus,
                                placeholder: 'Select',
                              ),
                              onTap: () => _showSimpleOptions(
                                title: 'Marital Status',
                                options: _maritalStatusOptions
                                    .map((option) => option.label)
                                    .toList(),
                                current: _displayOptionValue(
                                  _maritalStatusOptions,
                                  _maritalStatus,
                                  placeholder: '',
                                ),
                                onSelected: (value) {
                                  final selected = _maritalStatusOptions
                                      .firstWhereOrNull(
                                        (option) => option.label == value,
                                      );
                                  if (selected == null) return;
                                  setState(
                                    () => _maritalStatus =
                                        selected.value as String,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _BottomSaveBar(
                    isSaving: _isSaving,
                    onSave: _isSaving ? null : _saveProfile,
                  ),
                ],
              ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        color: isDark ? const Color(0xFF827B91) : const Color(0xFFA7A0B2),
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF16121E) : const Color(0xFFF4F0FF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF2B2437) : const Color(0xFFEAE2F2),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF2B2437) : const Color(0xFFEAE2F2),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.3),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  TextStyle _fieldValueStyle() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: isDark ? Colors.white : const Color(0xFF232129),
    );
  }

  String _displayOrPlaceholder(String? value, {required String placeholder}) {
    if (value == null || value.trim().isEmpty) {
      return placeholder;
    }
    return _prettyLabel(value);
  }

  String _normalizeCountryAlias(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';

    final normalized = trimmed.toLowerCase();
    switch (normalized) {
      case 'uae':
        return 'United Arab Emirates';
      case 'uk':
        return 'United Kingdom';
      case 'usa':
        return 'United States';
      default:
        return trimmed;
    }
  }

  String _countryDisplayValue(String? value, {required String placeholder}) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return placeholder;

    final normalized = _normalizeCountryAlias(raw);
    final country = Country.tryParse(normalized);
    if (country == null) {
      return _prettyLabel(normalized);
    }

    return '${country.flagEmoji} ${country.name}';
  }

  String _prettyLabel(String value) {
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  List<String> _interestPreview() {
    if (_selectedInterests.isEmpty) {
      return const ['Travel', 'Movies', 'Art', 'Technology'];
    }
    return _selectedInterests.take(6).map(_prettyLabel).toList();
  }

  String _countSummary(List<String> items) {
    if (items.isEmpty) return 'Select';
    if (items.length == 1) return _prettyLabel(items.first);
    return '${items.length} selected';
  }

  String _displayOptionValue(
    List<_ChoiceOption> options,
    String? value, {
    required String placeholder,
  }) {
    if (value == null || value.trim().isEmpty) {
      return placeholder;
    }
    final option = options.firstWhereOrNull((item) => item.value == value);
    if (option != null) {
      return option.label;
    }
    return _prettyLabel(value);
  }

  String _relationshipGoalLabel(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Select';
    }
    final option = _goalOptionForValue(value);
    if (option != null) {
      return option.label;
    }
    return 'Select';
  }

  String _basicsSummary() {
    var count = 0;
    if (_education != null && _education!.isNotEmpty) count++;
    if (_familyPlans != null && _familyPlans!.isNotEmpty) count++;
    if (_vaccinationStatus != null) count++;
    if (_communicationStyle != null && _communicationStyle!.isNotEmpty) count++;
    if (_bloodType != null && _bloodType!.isNotEmpty) count++;
    if (_willingToRelocate != null) count++;
    return '$count/6';
  }

  String _lifestyleSummary() {
    var count = 0;
    if (_hasPets != null || (_petPreference?.isNotEmpty ?? false)) count++;
    if (_alcohol != null && _alcohol!.isNotEmpty) count++;
    if (_workoutFrequency != null && _workoutFrequency!.isNotEmpty) count++;
    if (_dietary != null && _dietary!.isNotEmpty) count++;
    if (_socialMediaUsage != null && _socialMediaUsage!.isNotEmpty) count++;
    if (_sleepSchedule != null && _sleepSchedule!.isNotEmpty) count++;
    return '$count/6';
  }

  _GoalOption? _goalOptionForValue(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return _relationshipGoals.firstWhereOrNull((item) => item.value == value);
  }

  String? _composeGoalValue(String? intentMode, String? marriageIntention) {
    for (final option in _relationshipGoals) {
      if (option.intentMode == intentMode &&
          option.marriageIntention == marriageIntention) {
        return option.value;
      }
    }
    for (final option in _relationshipGoals) {
      if (option.intentMode == intentMode) {
        return option.value;
      }
    }
    for (final option in _relationshipGoals) {
      if (option.marriageIntention == marriageIntention) {
        return option.value;
      }
    }
    return null;
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate:
          _dateOfBirth ??
          DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 80)),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
    );

    if (selected != null) {
      setState(() => _dateOfBirth = selected);
    }
  }

  Future<void> _pickCountry({required ValueChanged<Country> onSelect}) async {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      countryListTheme: CountryListThemeData(
        borderRadius: BorderRadius.circular(16),
      ),
      onSelect: onSelect,
    );
  }

  Future<void> _pickCity() async {
    final selectedCountry = _country?.trim() ?? '';
    if (selectedCountry.isEmpty) return;

    final options =
        SignupData.countryCities[_normalizeCountryAlias(selectedCountry)] ??
        SignupData.countryCities[selectedCountry] ??
        const <String>[];

    if (options.isNotEmpty) {
      await _showSimpleOptions(
        title: 'City',
        options: options,
        current: _city,
        onSelected: (value) {
          setState(() => _city = value);
        },
      );
      return;
    }

    final cityController = TextEditingController(text: _city ?? '');
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('City'),
        content: TextField(
          controller: cityController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Enter city',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(cityController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    cityController.dispose();

    if (value != null) {
      setState(() => _city = value.trim());
    }
  }

  Future<void> _showSimpleOptions({
    required String title,
    required List<String> options,
    required String? current,
    required ValueChanged<String> onSelected,
  }) async {
    final selected = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) =>
            _SimpleOptionPage(title: title, options: options, current: current),
      ),
    );

    if (selected != null) {
      onSelected(selected);
    }
  }

  Future<void> _openInterestsPicker() async {
    final selected = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => _ChipPickerPage(
          title: 'Interests',
          searchHint: 'Search interest',
          options: _interestOptions,
          selected: _selectedInterests,
          maxSelection: 5,
          showSearch: true,
          iconForLabel: _chipIconForInterest,
        ),
      ),
    );

    if (selected != null) {
      setState(() => _selectedInterests = selected);
    }
  }

  Future<void> _openLanguagesPicker() async {
    final selected = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => _ChipPickerPage(
          title: 'Languages I Know',
          searchHint: 'Search language',
          options: _languageOptions,
          selected: _selectedLanguages,
          maxSelection: 5,
          showSearch: true,
          iconForLabel: (_) => LucideIcons.languages,
        ),
      ),
    );

    if (selected != null) {
      setState(() => _selectedLanguages = selected);
    }
  }

  Future<void> _openReligionPicker() async {
    final selected = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => _ChipPickerPage(
          title: 'Sect',
          options: _religionOptions,
          selected: _sect == null || _sect!.isEmpty
              ? const []
              : [_sectChoiceFromValue(_sect!)],
          maxSelection: 1,
          showSearch: false,
          iconForLabel: (_) => faithOptionIcon('sect'),
          confirmLabel: 'OK',
        ),
      ),
    );

    if (selected != null) {
      setState(
        () => _sect = selected.isEmpty
            ? null
            : _sectValueFromChoice(selected.first),
      );
    }
  }

  Future<void> _openRelationshipGoalsPicker() async {
    final selected = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => _GoalPickerPage(
          title: 'Relationship Goals',
          options: _relationshipGoals,
          current: _relationshipGoal,
        ),
      ),
    );

    if (selected != null) {
      final option = _goalOptionForValue(selected);
      setState(() {
        _relationshipGoal = selected;
        _marriageIntention = option?.marriageIntention;
      });
    }
  }

  Future<void> _openBasicsPage() async {
    final selected = await Navigator.of(context).push<Map<String, Object?>>(
      MaterialPageRoute(
        builder: (_) => _PreferenceSectionsPage(
          title: 'Basics',
          sections: [
            _PreferenceSectionConfig(
              key: 'education',
              title: 'Education',
              icon: profilePreferenceSectionIcon('education'),
              options: const [
                _ChoiceOption(label: 'High School', value: 'high_school'),
                _ChoiceOption(label: 'Bachelors', value: 'bachelors'),
                _ChoiceOption(label: 'Masters', value: 'masters'),
                _ChoiceOption(label: 'PhD', value: 'doctorate'),
                _ChoiceOption(label: 'Trade School', value: 'other'),
                _ChoiceOption(label: 'Other', value: 'other'),
              ],
            ),
            _PreferenceSectionConfig(
              key: 'familyPlans',
              title: 'Family Plans',
              icon: profilePreferenceSectionIcon('family plans'),
              options: _familyPlansOptions,
            ),
            _PreferenceSectionConfig(
              key: 'vaccinationStatus',
              title: 'COVID Vaccine',
              icon: profilePreferenceSectionIcon('vaccination status'),
              options: _vaccinationOptions,
            ),
            _PreferenceSectionConfig(
              key: 'communicationStyle',
              title: 'Communication Style',
              icon: profilePreferenceSectionIcon('communication style'),
              options: _communicationOptions,
            ),
            _PreferenceSectionConfig(
              key: 'bloodType',
              title: 'Blood Type',
              icon: profilePreferenceSectionIcon('blood type'),
              options: _bloodTypeOptions,
            ),
            _PreferenceSectionConfig(
              key: 'willingToRelocate',
              title: 'Willing to Relocate',
              icon: profilePreferenceSectionIcon('location'),
              options: _willingToRelocateOptions,
            ),
          ],
          initialValues: {
            'education': _education,
            'familyPlans': _familyPlans,
            'vaccinationStatus': _vaccinationStatus,
            'communicationStyle': _communicationStyle,
            'bloodType': _bloodType,
            'willingToRelocate': _willingToRelocate,
          },
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        _education = selected['education'] as String?;
        _familyPlans = selected['familyPlans'] as String?;
        _vaccinationStatus = selected['vaccinationStatus'] as bool?;
        _communicationStyle = selected['communicationStyle'] as String?;
        _bloodType = selected['bloodType'] as String?;
        _willingToRelocate = selected['willingToRelocate'] as bool?;
      });
    }
  }

  Future<void> _openLifestylePage() async {
    final selected = await Navigator.of(context).push<Map<String, Object?>>(
      MaterialPageRoute(
        builder: (_) => _PreferenceSectionsPage(
          title: 'Lifestyle',
          sections: [
            _PreferenceSectionConfig(
              key: 'petPreference',
              title: 'Pets',
              icon: profilePreferenceSectionIcon('pet preference'),
              options: _petsOptions,
            ),
            _PreferenceSectionConfig(
              key: 'alcohol',
              title: 'Alcohol Preference',
              icon: profilePreferenceSectionIcon('alcohol'),
              options: _drinkingOptions,
            ),
            _PreferenceSectionConfig(
              key: 'workoutFrequency',
              title: 'Workout',
              icon: profilePreferenceSectionIcon('workout frequency'),
              options: _workoutOptions,
            ),
            _PreferenceSectionConfig(
              key: 'dietary',
              title: 'Dietary Preferences',
              icon: profilePreferenceSectionIcon('dietary'),
              options: _dietaryOptions,
            ),
            _PreferenceSectionConfig(
              key: 'socialMediaUsage',
              title: 'Social Media Presence',
              icon: profilePreferenceSectionIcon('social media usage'),
              options: _socialMediaOptions,
            ),
            _PreferenceSectionConfig(
              key: 'sleepSchedule',
              title: 'Sleeping Habits',
              icon: profilePreferenceSectionIcon('sleep schedule'),
              options: _sleepOptions,
            ),
          ],
          initialValues: {
            'petPreference': _hasPets == false ? 'none' : _petPreference,
            'alcohol': _alcohol,
            'workoutFrequency': _workoutFrequency,
            'dietary': _dietary,
            'socialMediaUsage': _socialMediaUsage,
            'sleepSchedule': _sleepSchedule,
          },
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        final petSelection = selected['petPreference'] as String?;
        _hasPets = petSelection == null ? _hasPets : petSelection != 'none';
        _petPreference = petSelection == null || petSelection == 'none'
            ? null
            : petSelection;
        _alcohol = selected['alcohol'] as String?;
        _workoutFrequency = selected['workoutFrequency'] as String?;
        _dietary = selected['dietary'] as String?;
        _socialMediaUsage = selected['socialMediaUsage'] as String?;
        _sleepSchedule = selected['sleepSchedule'] as String?;
      });
    }
  }

  IconData _chipIconForInterest(String label) {
    return interestOptionIcon(label);
  }

  String? _normalizeCommunicationStyle(String? value) {
    final normalized = (value ?? '').trim();
    switch (normalized) {
      case '':
        return null;
      case 'expressive':
        return 'chatty_cathy';
      case 'reserved':
        return 'listener';
      case 'humorous':
        return 'joker';
      case 'gentle':
        return 'easygoing';
      case 'direct':
        return 'straight_shooter';
      default:
        return normalized;
    }
  }

  String? _normalizeSleepSchedule(String? value) {
    switch ((value ?? '').trim()) {
      case 'insomniac':
        return 'night_owl';
      default:
        return value;
    }
  }

  String? _normalizeSocialMediaUsage(String? value) {
    switch ((value ?? '').trim()) {
      case 'influencer':
        return 'very_active';
      default:
        return value;
    }
  }

  String? _communicationStyleToBackend(String? value) {
    final normalized = (value ?? '').trim();
    switch (normalized) {
      case '':
        return null;
      case 'chatty_cathy':
      case 'storyteller':
      case 'expressive':
        return 'expressive';
      case 'listener':
      case 'deep_thinker':
      case 'reserved':
        return 'reserved';
      case 'joker':
      case 'sarcastic_wit':
      case 'humorous':
        return 'humorous';
      case 'easygoing':
      case 'gentle':
        return 'gentle';
      case 'straight_shooter':
      case 'direct':
        return 'direct';
      default:
        return normalized;
    }
  }

  String _sectChoiceFromValue(String value) {
    switch (value.trim().toLowerCase()) {
      case 'sunni':
        return 'Sunni';
      case 'shia':
        return 'Shia';
      case 'sufi':
        return 'Sufi';
      case 'prefer_not_to_say':
        return 'Prefer not to say';
      default:
        return _prettyLabel(value);
    }
  }

  String _sectValueFromChoice(String choice) {
    switch (choice.trim().toLowerCase()) {
      case 'prefer not to say':
        return 'prefer_not_to_say';
      default:
        return choice.trim().toLowerCase().replaceAll(' ', '_');
    }
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final selectedGoal = _goalOptionForValue(_relationshipGoal);
      final communicationStyle = _communicationStyleToBackend(
        _communicationStyle,
      );
      final profileData = {
        'bio': _bioCtrl.text.trim(),
        'gender': _gender?.trim().toLowerCase(),
        'dateOfBirth': _dateOfBirth?.toIso8601String().split('T').first,
        'maritalStatus': _maritalStatus,
        'education': _education,
        'jobTitle': _jobTitleCtrl.text.trim(),
        'company': _companyCtrl.text.trim(),
        'city': _city,
        'country': _country,
        'nationality': _nationality,
        'height': int.tryParse(_heightCtrl.text),
        'weight': int.tryParse(_weightCtrl.text),
        'skinComplexion': _skinComplexion,
        'build': _bodyBuild,
        'religiousLevel': _religiousLevel,
        'prayerFrequency': _prayerFrequency,
        'sect': _sect,
        'dietary': _dietary,
        'alcohol': _alcohol,
        'familyPlans': _familyPlans,
        'communicationStyle': communicationStyle,
        'vaccinationStatus': _vaccinationStatus,
        'bloodType': _bloodType,
        'workoutFrequency': _workoutFrequency,
        'sleepSchedule': _normalizeSleepSchedule(_sleepSchedule),
        'socialMediaUsage': _normalizeSocialMediaUsage(_socialMediaUsage),
        'hasPets': _hasPets,
        'petPreference': _petPreference,
        'willingToRelocate': _willingToRelocate,
        'interests': _selectedInterests,
        'languages': _selectedLanguages,
        'aboutPartner': _idealSpouseCtrl.text.trim(),
        if (selectedGoal != null) 'intentMode': selectedGoal.intentMode,
        if ((selectedGoal?.marriageIntention ?? _marriageIntention) != null)
          'marriageIntention':
              selectedGoal?.marriageIntention ?? _marriageIntention,
      };

      final userData = {
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      };

      final success = await controller.updateProfile({
        ...userData,
        ...profileData,
      });

      if (!mounted) return;

      if (success) {
        await controller.refreshProfile();
        // Dismiss the edit screen and reveal the underlying profile screen.
        // Do NOT wipe the stack (offAllNamed) or force-switch tabs.
        if (mounted && Get.key.currentState?.canPop() == true) {
          Get.back(result: true);
        }
      }
    } catch (e) {
      Helpers.showSnackbar(
        message: 'Failed to save profile: ${e.toString()}',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _EditProfileTopBar extends StatelessWidget {
  const _EditProfileTopBar({
    required this.isSaving,
    required this.onClose,
    required this.onSave,
  });

  final bool isSaving;
  final VoidCallback onClose;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      child: SizedBox(
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: onClose,
                icon: Icon(
                  LucideIcons.x,
                  size: 18,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : const Color(0xFF232129),
                ),
              ),
            ),
            Text(
              'Edit Profile',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : const Color(0xFF232129),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onSave,
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : Text(
                        'Save',
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textPrimaryDark : const Color(0xFF232129),
      ),
    );
  }
}

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({required this.user, required this.onTap});

  final UserModel user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final photos = user.photos ?? const <PhotoModel>[];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(6, (index) {
          final hasPhoto = index < photos.length;
          return Padding(
            padding: EdgeInsets.only(right: index == 5 ? 0 : 8),
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                width: 52,
                height: 74,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : const Color(0xFFE7E4EC),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: hasPhoto
                      ? CachedNetworkImage(
                          imageUrl: CloudinaryUrl.medium(photos[index].url),
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) =>
                              _PhotoPlaceholder(isDark: isDark),
                        )
                      : _PhotoPlaceholder(add: true, isDark: isDark),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({this.add = false, this.isDark = false});

  final bool add;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? AppColors.surfaceDark : const Color(0xFFF4F3F7),
      alignment: Alignment.center,
      child: Icon(
        add ? LucideIcons.plus : LucideIcons.image,
        size: add ? 18 : 16,
        color: isDark ? AppColors.textHintDark : const Color(0xFFB5AFBF),
      ),
    );
  }
}

class _EditFieldTile extends StatelessWidget {
  const _EditFieldTile({
    required this.label,
    required this.child,
    this.large = false,
  });

  final String label;
  final Widget child;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(14, 14, 14, large ? 16 : 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14111B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF292432) : const Color(0xFFE8E1F1),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: const Color(0xFFC4B5FD).withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: isDark ? const Color(0xFF8F869F) : const Color(0xFF8F869F),
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _SelectFieldTile extends StatelessWidget {
  const _SelectFieldTile({
    required this.label,
    required this.value,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = value == 'Select' || value == 'Select religion';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF14111B) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? const Color(0xFF292432) : const Color(0xFFE8E1F1),
            ),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: const Color(0xFFC4B5FD).withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isDark
                      ? const Color(0xFF8F869F)
                      : const Color(0xFF8F869F),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF16121E)
                      : const Color(0xFFF4F0FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2B2437)
                        : const Color(0xFFEAE2F2),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: enabled
                              ? (isPlaceholder
                                    ? (isDark
                                          ? const Color(0xFF827B91)
                                          : const Color(0xFFA7A0B2))
                                    : (isDark
                                          ? Colors.white
                                          : const Color(0xFF232129)))
                              : const Color(0xFFC3BFCA),
                        ),
                      ),
                    ),
                    Icon(
                      LucideIcons.chevronDown,
                      size: 15,
                      color: enabled
                          ? const Color(0xFF9C97A6)
                          : const Color(0xFFC7C3CC),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionRowHeader extends StatelessWidget {
  const _SectionRowHeader({
    required this.title,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF232129),
          ),
        ),
        const Spacer(),
        if (actionLabel.isNotEmpty)
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(40, 20),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }
}

class _PreviewChip extends StatelessWidget {
  const _PreviewChip({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE6E3ED),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : const Color(0xFF4A4556),
            ),
          ),
          if (icon != null) ...[
            const SizedBox(width: 4),
            Icon(
              icon,
              size: 11,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : const Color(0xFF9C97A6),
            ),
          ],
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE7E4EC),
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.title,
    required this.value,
    required this.onTap,
  });

  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : const Color(0xFF232129),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : const Color(0xFF9A94A3),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                LucideIcons.chevronRight,
                size: 15,
                color: isDark
                    ? AppColors.textHintDark
                    : const Color(0xFFB3ADBC),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomSaveBar extends StatelessWidget {
  const _BottomSaveBar({required this.isSaving, required this.onSave});

  final bool isSaving;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        color: isDark ? AppColors.backgroundDark : const Color(0xFFF7F7FA),
        child: SizedBox(
          height: 44,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFF6E3DFB), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onSave,
                borderRadius: BorderRadius.circular(999),
                child: Center(
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Save',
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipPickerPage extends StatefulWidget {
  const _ChipPickerPage({
    required this.title,
    required this.options,
    required this.selected,
    required this.maxSelection,
    required this.iconForLabel,
    this.searchHint = '',
    this.showSearch = true,
    this.confirmLabel,
  });

  final String title;
  final List<String> options;
  final List<String> selected;
  final int maxSelection;
  final IconData Function(String label) iconForLabel;
  final String searchHint;
  final bool showSearch;
  final String? confirmLabel;

  @override
  State<_ChipPickerPage> createState() => _ChipPickerPageState();
}

class _ChipPickerPageState extends State<_ChipPickerPage> {
  late final TextEditingController _searchController;
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selected = List<String>.from(widget.selected);
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggle(String option) {
    setState(() {
      if (widget.maxSelection == 1) {
        _selected = _selected.contains(option) ? <String>[] : <String>[option];
        return;
      }

      if (_selected.contains(option)) {
        _selected.remove(option);
        return;
      }

      if (_selected.length < widget.maxSelection) {
        _selected.add(option);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? widget.options
        : widget.options
              .where((option) => option.toLowerCase().contains(query))
              .toList();
    final confirmText =
        widget.confirmLabel ??
        (widget.maxSelection > 1
            ? 'OK (${_selected.length}/${widget.maxSelection})'
            : 'OK');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.smoothBeige,
      body: SafeArea(
        child: Column(
          children: [
            _PickerTopBar(title: widget.title),
            if (widget.showSearch)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceDark
                        : const Color(0xFFF7F6FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : const Color(0xFFECE7F6),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : const Color(0xFF232129),
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      prefixIcon: Icon(
                        LucideIcons.search,
                        size: 16,
                        color: isDark
                            ? AppColors.textHintDark
                            : const Color(0xFFBCB6C8),
                      ),
                      hintText: widget.searchHint,
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: isDark
                            ? AppColors.textHintDark
                            : const Color(0xFFB1ABBC),
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  widget.showSearch ? 16 : 14,
                  16,
                  20,
                ),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: filtered
                        .map(
                          (option) => _PickerChip(
                            label: option,
                            icon: widget.iconForLabel(option),
                            selected: _selected.contains(option),
                            onTap: () => _toggle(option),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xFF6E3DFB), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(_selected),
                        borderRadius: BorderRadius.circular(999),
                        child: Center(
                          child: Text(
                            confirmText,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalPickerPage extends StatefulWidget {
  const _GoalPickerPage({
    required this.title,
    required this.options,
    required this.current,
  });

  final String title;
  final List<_GoalOption> options;
  final String? current;

  @override
  State<_GoalPickerPage> createState() => _GoalPickerPageState();
}

class _GoalPickerPageState extends State<_GoalPickerPage> {
  String? _selectedValue;
  String? _selectedLabel;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.current;
    _GoalOption? currentOption;
    for (final option in widget.options) {
      if (option.value == widget.current) {
        currentOption = option;
        break;
      }
    }
    _selectedLabel = currentOption?.label;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.smoothBeige,
      body: SafeArea(
        child: Column(
          children: [
            _PickerTopBar(title: widget.title),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                itemCount: widget.options.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final option = widget.options[index];
                  final selected = _selectedLabel == option.label;
                  return _GoalCard(
                    option: option,
                    selected: selected,
                    onTap: () => setState(() {
                      _selectedValue = option.value;
                      _selectedLabel = option.label;
                    }),
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xFF6E3DFB), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(_selectedValue),
                        borderRadius: BorderRadius.circular(999),
                        child: Center(
                          child: Text(
                            'OK',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleOptionPage extends StatelessWidget {
  const _SimpleOptionPage({
    required this.title,
    required this.options,
    required this.current,
  });

  final String title;
  final List<String> options;
  final String? current;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.smoothBeige,
      body: SafeArea(
        child: Column(
          children: [
            _PickerTopBar(title: title),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                itemCount: options.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final option = options[index];
                  final selected = option == current;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(
                        context,
                      ).pop(selected ? null : option),
                      borderRadius: BorderRadius.circular(14),
                      child: Ink(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : (isDark
                                      ? AppColors.borderDark
                                      : const Color(0xFFE8E4EF)),
                            width: selected ? 1.4 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                option,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : const Color(0xFF232129),
                                ),
                              ),
                            ),
                            Icon(
                              selected
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              size: 18,
                              color: selected
                                  ? AppColors.primary
                                  : (isDark
                                        ? AppColors.textHintDark
                                        : const Color(0xFFC3BDCE)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerTopBar extends StatelessWidget {
  const _PickerTopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 6,
            child: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: Icon(
                LucideIcons.x,
                size: 18,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : const Color(0xFF232129),
              ),
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : const Color(0xFF19171F),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerChip extends StatelessWidget {
  const _PickerChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : (isDark ? AppColors.surfaceDark : Colors.white),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : (isDark ? AppColors.borderDark : const Color(0xFFE8E4EF)),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: selected
                      ? Colors.white
                      : (isDark
                            ? AppColors.textPrimaryDark
                            : const Color(0xFF26232C)),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 15,
                height: 15,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.18)
                      : (isDark
                            ? AppColors.surfaceMutedDark
                            : const Color(0xFFF5F3F8)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 9.5,
                  color: selected
                      ? Colors.white
                      : (isDark
                            ? AppColors.textHintDark
                            : const Color(0xFFA29CAF)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _GoalOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : (isDark ? AppColors.borderDark : const Color(0xFFE7E4EC)),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                option.label,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : const Color(0xFF232129),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                option.description,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : const Color(0xFF9B95A6),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreferenceSectionsPage extends StatefulWidget {
  const _PreferenceSectionsPage({
    required this.title,
    required this.sections,
    required this.initialValues,
  });

  final String title;
  final List<_PreferenceSectionConfig> sections;
  final Map<String, Object?> initialValues;

  @override
  State<_PreferenceSectionsPage> createState() =>
      _PreferenceSectionsPageState();
}

class _PreferenceSectionsPageState extends State<_PreferenceSectionsPage> {
  late final Map<String, Object?> _selectedValues;

  @override
  void initState() {
    super.initState();
    _selectedValues = Map<String, Object?>.from(widget.initialValues);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.smoothBeige,
      body: SafeArea(
        child: Column(
          children: [
            _PickerTopBar(title: widget.title),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                itemCount: widget.sections.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final section = widget.sections[index];
                  return _PreferenceSection(
                    section: section,
                    selectedValue: _selectedValues[section.key],
                    onSelected: (value) {
                      setState(() {
                        _selectedValues[section.key] = value;
                      });
                    },
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xFF6E3DFB), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(_selectedValues),
                        borderRadius: BorderRadius.circular(999),
                        child: Center(
                          child: Text(
                            'OK',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferenceSection extends StatelessWidget {
  const _PreferenceSection({
    required this.section,
    required this.selectedValue,
    required this.onSelected,
  });

  final _PreferenceSectionConfig section;
  final Object? selectedValue;
  final ValueChanged<Object?> onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              section.icon,
              size: 15,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : const Color(0xFF232129),
            ),
            const SizedBox(width: 6),
            Text(
              section.title,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : const Color(0xFF232129),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: section.options.map((option) {
            final selected = selectedValue == option.value;
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onSelected(option.value),
                borderRadius: BorderRadius.circular(999),
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary
                        : (isDark ? AppColors.surfaceDark : Colors.white),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : (isDark
                                ? AppColors.borderDark
                                : const Color(0xFFE7E4EC)),
                    ),
                  ),
                  child: Text(
                    option.label,
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: selected
                          ? Colors.white
                          : (isDark
                                ? AppColors.textPrimaryDark
                                : const Color(0xFF403B4A)),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _PreferenceSectionConfig {
  const _PreferenceSectionConfig({
    required this.key,
    required this.title,
    required this.icon,
    required this.options,
  });

  final String key;
  final String title;
  final IconData icon;
  final List<_ChoiceOption> options;
}

class _ChoiceOption {
  const _ChoiceOption({required this.label, required this.value});

  final String label;
  final Object? value;
}

class _GoalOption {
  const _GoalOption({
    required this.label,
    required this.value,
    required this.intentMode,
    required this.marriageIntention,
    required this.description,
  });

  final String label;
  final String value;
  final String intentMode;
  final String marriageIntention;
  final String description;
}
