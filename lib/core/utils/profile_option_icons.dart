import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

String _normalizedLabel(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
    .trim();

bool _hasAnyKeyword(String value, List<String> keywords) {
  for (final keyword in keywords) {
    if (value.contains(keyword)) {
      return true;
    }
  }
  return false;
}

IconData interestOptionIcon(String label) {
  final normalized = _normalizedLabel(label);

  if (_hasAnyKeyword(normalized, const ['travel', 'adventure'])) {
    return Icons.flight_takeoff_rounded;
  }
  if (_hasAnyKeyword(normalized, const ['cook', 'food', 'pottery'])) {
    return Icons.restaurant_menu_rounded;
  }
  if (_hasAnyKeyword(normalized, const ['hiking', 'nature', 'garden'])) {
    return Icons.terrain_rounded;
  }
  if (_hasAnyKeyword(normalized, const ['yoga', 'meditation'])) {
    return Icons.self_improvement_rounded;
  }
  if (_hasAnyKeyword(normalized, const ['gaming'])) {
    return Icons.sports_esports_rounded;
  }
  if (_hasAnyKeyword(normalized, const ['movie', 'film', 'comedy'])) {
    return Icons.movie_creation_outlined;
  }
  if (_hasAnyKeyword(normalized, const ['photo'])) {
    return Icons.photo_camera_outlined;
  }
  if (_hasAnyKeyword(normalized, const ['music', 'karaoke'])) {
    return Icons.music_note_rounded;
  }
  if (_hasAnyKeyword(normalized, const ['pet'])) {
    return Icons.pets_outlined;
  }
  if (_hasAnyKeyword(normalized, const ['paint', 'art', 'diy'])) {
    return Icons.palette_outlined;
  }
  if (_hasAnyKeyword(normalized, const ['dance'])) {
    return Icons.music_note_rounded;
  }
  if (_hasAnyKeyword(normalized, const ['fitness', 'sport'])) {
    return Icons.fitness_center_rounded;
  }
  if (_hasAnyKeyword(normalized, const ['read', 'write', 'poetry'])) {
    return Icons.menu_book_rounded;
  }
  if (_hasAnyKeyword(normalized, const ['technology', 'science', 'astronomy'])) {
    return Icons.memory_rounded;
  }
  if (_hasAnyKeyword(normalized, const ['fashion'])) {
    return Icons.checkroom_rounded;
  }
  if (_hasAnyKeyword(
    normalized,
    const ['motorcycling', 'motor racing', 'cycling'],
  )) {
    return Icons.two_wheeler_rounded;
  }

  return Icons.auto_awesome_rounded;
}

IconData faithOptionIcon(String key) {
  switch (_normalizedLabel(key)) {
    case 'sect':
      return Icons.shield_outlined;
    case 'religious level':
      return Icons.stars_rounded;
    case 'prayer frequency':
      return Icons.schedule_rounded;
    case 'dietary':
      return Icons.restaurant_menu_rounded;
    case 'alcohol':
      return Icons.no_drinks_rounded;
    case 'hijab':
      return Icons.checkroom_rounded;
    default:
      return Icons.auto_awesome_rounded;
  }
}

IconData identityFieldIcon(String key) {
  switch (_normalizedLabel(key)) {
    case 'nationality':
      return LucideIcons.globe;
    case 'ethnicity':
      return LucideIcons.users;
    case 'skin complexion':
      return LucideIcons.palette;
    case 'build':
      return LucideIcons.dumbbell;
    default:
      return LucideIcons.briefcase;
  }
}

IconData profilePreferenceSectionIcon(String key) {
  switch (_normalizedLabel(key)) {
    case 'education':
      return Icons.school_outlined;
    case 'family plans':
      return Icons.family_restroom_outlined;
    case 'vaccination status':
      return Icons.health_and_safety_outlined;
    case 'communication style':
      return Icons.chat_bubble_outline_rounded;
    case 'blood type':
      return Icons.water_drop_outlined;
    case 'location':
      return Icons.travel_explore_rounded;
    case 'pet preference':
      return Icons.pets_outlined;
    case 'alcohol':
      return Icons.no_drinks_rounded;
    case 'workout frequency':
      return Icons.fitness_center_rounded;
    case 'dietary':
      return Icons.restaurant_menu_rounded;
    case 'social media usage':
      return Icons.smartphone_outlined;
    case 'sleep schedule':
      return Icons.nights_stay_outlined;
    case 'skin complexion':
      return Icons.palette_outlined;
    case 'build':
      return Icons.accessibility_new_rounded;
    default:
      return Icons.tune_rounded;
  }
}
