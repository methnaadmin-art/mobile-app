import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:methna_app/core/theme/premium_theme.dart';
import 'package:methna_app/core/utils/cloudinary_url.dart';

/// Ad data model for feed ads
class AdCardData {
  final String id;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? link;
  final String? buttonText;
  final bool isAd;

  const AdCardData({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    this.link,
    this.buttonText,
    this.isAd = true,
  });

  factory AdCardData.fromJson(Map<String, dynamic> json) {
    return AdCardData(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      imageUrl: json['imageUrl'],
      link: json['link'] ?? json['buttonLink'],
      buttonText: json['buttonText'],
    );
  }
}

/// Ad card that visually matches the _SwipeCard style.
/// Full-screen image with title, description overlay, and optional CTA button.
class AdCard extends StatelessWidget {
  final AdCardData ad;
  final Future<void> Function()? onTrackClick;

  const AdCard({
    super.key,
    required this.ad,
    this.onTrackClick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            if (ad.imageUrl != null && ad.imageUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: CloudinaryUrl.large(ad.imageUrl),
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppTheme.surface,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.gold,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppTheme.surface,
                  child: Center(
                    child: Icon(
                      LucideIcons.megaphone,
                      size: 80,
                      color: AppTheme.white30,
                    ),
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.6),
                      AppTheme.surface,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    LucideIcons.megaphone,
                    size: 80,
                    color: AppTheme.white30,
                  ),
                ),
              ),

            // Gradient Overlay (same as user card)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                    Colors.black.withValues(alpha: 0.9),
                  ],
                  stops: const [0.0, 0.4, 0.7, 1.0],
                ),
              ),
            ),

            // "Sponsored" badge (top left)
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: const Text(
                  'Sponsored',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            // Content overlay (bottom)
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title (in place of user name)
                  Text(
                    ad.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Description (in place of hobbies/bio)
                  if (ad.description != null && ad.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      ad.description!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // CTA Button
                  if (ad.buttonText != null &&
                      ad.buttonText!.isNotEmpty &&
                      ad.link != null &&
                      ad.link!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () => _openLink(ad.link!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppTheme.goldGradient,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.gold.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          ad.buttonText!,
                          style: const TextStyle(
                            color: AppTheme.background,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openLink(String url) async {
    if (onTrackClick != null) {
      try {
        await onTrackClick!.call();
      } catch (_) {}
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
