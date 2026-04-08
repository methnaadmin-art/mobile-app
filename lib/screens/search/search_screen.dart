import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:methna_app/app/controllers/users_controller.dart';
import 'package:methna_app/app/data/services/api_service.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/app/theme/app_text_styles.dart';
import 'package:methna_app/core/constants/api_constants.dart';
import 'package:methna_app/core/utils/helpers.dart';
import 'package:methna_app/core/widgets/app_card.dart';
import 'package:methna_app/core/widgets/custom_button.dart';
import 'package:methna_app/core/widgets/datify_shell.dart';
import 'package:methna_app/core/widgets/discovery_flow.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ApiService _api = Get.find<ApiService>();
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _debounce;
  final RxList<_SearchResult> results = <_SearchResult>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasSearched = false.obs;
  final RxString query = ''.obs;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final text = _searchCtrl.text.trim();
    query.value = text;
    _debounce?.cancel();
    if (text.isEmpty) {
      results.clear();
      hasSearched.value = false;
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(text);
    });
  }

  int _calcAge(String dob) {
    try {
      final birth = DateTime.parse(dob);
      final now = DateTime.now();
      int age = now.year - birth.year;
      if (now.month < birth.month ||
          (now.month == birth.month && now.day < birth.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _performSearch(String q) async {
    isLoading.value = true;
    hasSearched.value = true;
    try {
      final response = await _api.get(
        ApiConstants.search,
        queryParameters: {'name': q, 'q': q, 'limit': 20},
      );
      final data = response.data;
      final list = data is Map
          ? (data['users'] ?? data['results'] ?? [])
          : (data is List ? data : []);
      results.value = (list as List)
          .map((item) {
            if (item is Map<String, dynamic>) {
              String? photoUrl = item['photo'];
              if (photoUrl == null &&
                  item['photos'] is List &&
                  (item['photos'] as List).isNotEmpty) {
                final mainPhoto = (item['photos'] as List).firstWhere(
                  (p) => p['isMain'] == true,
                  orElse: () => (item['photos'] as List).first,
                );
                photoUrl = mainPhoto['url'];
              }
              final profile = item['profile'] is Map
                  ? item['profile'] as Map<String, dynamic>
                  : null;
              return _SearchResult(
                userId: item['id'] ?? item['userId'] ?? '',
                firstName: item['firstName'] ?? '',
                lastName: item['lastName'] ?? '',
                age:
                    item['age'] ??
                    (profile?['dateOfBirth'] != null
                        ? _calcAge(profile!['dateOfBirth'])
                        : 0),
                city: profile?['city'] ?? item['city'] ?? '',
                country: profile?['country'] ?? item['country'] ?? '',
                photo: photoUrl,
                bio: profile?['bio'] ?? item['bio'],
                interests: (profile?['interests'] ?? item['interests']) != null
                    ? List<String>.from(
                        profile?['interests'] ?? item['interests'],
                      )
                    : [],
              );
            }
            return null;
          })
          .whereType<_SearchResult>()
          .toList();
    } catch (e) {
      debugPrint('[Search] _performSearch error: $e');
      results.clear();
      Helpers.showSnackbar(
        message: 'search_failed'.tr,
        isError: true,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final secondaryColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: DatifyBackground(
        compact: true,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  0,
                ),
                child: Row(
                  children: [
                    DiscoveryIconButton(
                      icon: LucideIcons.chevronLeft,
                      onTap: () => Get.back(),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Obx(
                        () => DiscoverySearchField(
                          controller: _searchCtrl,
                          focusNode: _focusNode,
                          hintText: 'search_hint'.tr,
                          autofocus: true,
                          onClear: _searchCtrl.clear,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: Obx(() {
                  if (isLoading.value) {
                    return _buildSkeletonList(isDark);
                  }

                  if (!hasSearched.value) {
                    return _buildInitialState();
                  }

                  if (results.isEmpty) {
                    return ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        40,
                      ),
                      children: [
                        DiscoveryEmptyCard(
                          icon: LucideIcons.searchX,
                          title: 'no_results_found'.tr,
                          subtitle:
                              'no_results_found_desc'.tr,
                          action: CustomButton(
                            text: 'clear_search'.tr,
                            variant: CustomButtonVariant.secondary,
                            onPressed: () {
                              _searchCtrl.clear();
                              _focusNode.requestFocus();
                            },
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      32,
                    ),
                    children: [
                      DiscoverySectionHeader(
                        title: 'search_results'.tr,
                        subtitle:
                            '${results.length} ${'profiles_matched'.tr}',
                      ),
                      ...results.map(
                        (result) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _SearchResultTile(
                            result: result,
                            textColor: textColor,
                            secondaryColor: secondaryColor,
                            onTap: () {
                              final usersController =
                                  Get.isRegistered<UsersController>()
                                  ? Get.find<UsersController>()
                                  : null;

                              if (usersController != null) {
                                usersController.openUserDetailById(result.userId);
                                return;
                              }

                              Get.toNamed(
                                AppRoutes.userDetail,
                                arguments: {'userId': result.userId},
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final subtitleColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        40,
      ),
      children: [
        DiscoveryHeroHeader(
          eyebrow: 'search_eyebrow'.tr,
          title: 'find_someone_meaningful'.tr,
          subtitle:
              'find_someone_meaningful_desc'.tr,
        ),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0x338E2CFF),
                      const Color(0x1A171821),
                    ]
                  : [
                      const Color(0x22A020F9),
                      const Color(0xFFFDF9FF),
                    ],
            ),
            border: Border.all(
              color: isDark
                  ? AppColors.borderDark
                  : AppColors.primary.withValues(alpha: 0.14),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'best_ways_to_search'.tr,
                style: AppTextStyles.headlineSmall.copyWith(
                  color: titleColor,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'best_ways_to_search_desc'.tr,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: subtitleColor,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  DiscoveryInfoPill(
                    icon: LucideIcons.user,
                    label: 'first_name'.tr,
                    color: AppColors.primary,
                  ),
                  DiscoveryInfoPill(
                    icon: LucideIcons.mapPin,
                    label: 'city'.tr,
                    color: AppColors.gold,
                  ),
                  DiscoveryInfoPill(
                    icon: LucideIcons.sparkles,
                    label: 'interests'.tr,
                    color: AppColors.like,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonList(bool isDark) {
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        32,
      ),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: cardColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmerBox(isDark, double.infinity, 16),
                      const SizedBox(height: AppSpacing.xs),
                      _shimmerBox(isDark, 140, 12),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: List.generate(
                          3,
                          (i) => Padding(
                            padding: EdgeInsets.only(
                              right: i == 2 ? 0 : AppSpacing.xs,
                            ),
                            child: _shimmerBox(isDark, 56, 22),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _shimmerBox(bool isDark, double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class _SearchResult {
  final String userId;
  final String firstName;
  final String lastName;
  final int age;
  final String city;
  final String country;
  final String? photo;
  final String? bio;
  final List<String> interests;

  _SearchResult({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.age,
    required this.city,
    required this.country,
    this.photo,
    this.bio,
    required this.interests,
  });

  String get fullName => '$firstName $lastName'.trim();
  String get location => [city, country].where((s) => s.isNotEmpty).join(', ');
}

class _SearchResultTile extends StatelessWidget {
  final _SearchResult result;
  final Color textColor;
  final Color secondaryColor;
  final VoidCallback onTap;

  const _SearchResultTile({
    required this.result,
    required this.textColor,
    required this.secondaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SearchAvatar(result: result),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${result.fullName}${result.age > 0 ? ', ${result.age}' : ''}',
                        style: AppTextStyles.titleLarge.copyWith(
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 18,
                      color: secondaryColor,
                    ),
                  ],
                ),
                if (result.location.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Row(
                    children: [
                      Icon(LucideIcons.mapPin, size: 13, color: secondaryColor),
                      const SizedBox(width: AppSpacing.xxs),
                      Expanded(
                        child: Text(
                          result.location,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: secondaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (result.bio != null && result.bio!.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    result.bio!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: secondaryColor,
                    ),
                  ),
                ],
                if (result.interests.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: result.interests.take(3).map((interest) {
                      return DiscoveryInfoPill(
                        icon: LucideIcons.sparkles,
                        label: interest,
                        color: AppColors.gold,
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchAvatar extends StatelessWidget {
  final _SearchResult result;

  const _SearchAvatar({required this.result});

  @override
  Widget build(BuildContext context) {
    final initials = Helpers.getInitials(result.firstName, result.lastName);
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(2),
      child: ClipOval(
        child: result.photo != null && result.photo!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: result.photo!,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => _FallbackAvatar(initials: initials),
              )
            : _FallbackAvatar(initials: initials),
      ),
    );
  }
}

class _FallbackAvatar extends StatelessWidget {
  final String initials;

  const _FallbackAvatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primarySurface,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppTextStyles.titleLarge.copyWith(color: AppColors.primary),
      ),
    );
  }
}
