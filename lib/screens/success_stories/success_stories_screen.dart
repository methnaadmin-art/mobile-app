import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:methna_app/app/data/services/api_service.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/core/constants/api_constants.dart';
import 'package:methna_app/core/widgets/datify_shell.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SuccessStoriesScreen extends StatefulWidget {
  const SuccessStoriesScreen({super.key});

  @override
  State<SuccessStoriesScreen> createState() => _SuccessStoriesScreenState();
}

class _SuccessStoriesScreenState extends State<SuccessStoriesScreen> {
  final ApiService _api = Get.find<ApiService>();
  final RxList<Map<String, dynamic>> stories = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void initState() {
    super.initState();
    _fetchStories();
  }

  Future<void> _fetchStories() async {
    isLoading.value = true;
    try {
      final response = await _api.get(
        ApiConstants.successStories,
        options: Options(
          extra: {'disable_retry': true},
          validateStatus: (status) => status != null && status < 600,
        ),
      );
      if ((response.statusCode ?? 500) >= 500) {
        stories.clear();
        return;
      }
      final list = response.data is List
          ? response.data
          : response.data['stories'] ?? [];
      stories.value = (list as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {}
    isLoading.value = false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 76,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 6, bottom: 6),
          child: DatifyBackButton(onTap: () => Get.back()),
        ),
        title: Text(
          'success_stories'.tr,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: DatifyBackground(
        compact: true,
        child: Obx(() {
          if (isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (stories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.like.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.heart,
                      size: 40,
                      color: AppColors.like,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'no_stories_yet'.tr,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'be_first_success_story'.tr,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _fetchStories,
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: stories.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final story = stories[index];
                return _StoryCard(story: story, isDark: isDark);
              },
            ),
          );
        }),
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  final Map<String, dynamic> story;
  final bool isDark;

  const _StoryCard({required this.story, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final coupleNames =
        story['coupleNames'] ?? story['title'] ?? 'a_beautiful_story'.tr;
    final content = story['story'] ?? story['content'] ?? '';
    final imageUrl = story['imageUrl'] ?? story['photo'];
    final date = story['weddingDate'] ?? story['createdAt'];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          if (imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(
                  height: 200,
                  color: AppColors.primarySurface,
                  child: const Center(
                    child: Icon(
                      LucideIcons.heart,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title / couple names
                Row(
                  children: [
                    const Icon(
                      LucideIcons.heart,
                      size: 18,
                      color: AppColors.like,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        coupleNames,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                if (date != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Married ${_formatDate(date)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Story content
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // Methna badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.badgeCheck,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'met_on_methna'.tr,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    try {
      final d = DateTime.parse(date.toString());
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return date.toString();
    }
  }
}
