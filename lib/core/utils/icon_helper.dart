import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

class IconHelper {
  static IconData getIcon(String? iconKey) {
    if (iconKey == null || iconKey.isEmpty) return LucideIcons.layers;

    switch (iconKey.toLowerCase()) {
      case 'heart': return LucideIcons.heart;
      case 'mosque': return LucideIcons.church; // Mosque icon substitute
      case 'star': return LucideIcons.star;
      case 'crown': return LucideIcons.crown;
      case 'zap': return LucideIcons.zap;
      case 'sparkles': return LucideIcons.sparkles;
      case 'shield': return LucideIcons.shield;
      case 'award': return LucideIcons.award;
      case 'compass': return LucideIcons.compass;
      case 'gift': return LucideIcons.gift;
      case 'coffee': return LucideIcons.coffee;
      case 'music': return LucideIcons.music;
      case 'camera': return LucideIcons.camera;
      case 'globe': return LucideIcons.globe;
      case 'activity': return LucideIcons.activity;
      case 'users': return LucideIcons.users;
      case 'flame': return LucideIcons.flame;
      case 'moon': return LucideIcons.moon;
      case 'sun': return LucideIcons.sun;
      case 'cloud': return LucideIcons.cloud;
      case 'briefcase': return LucideIcons.briefcase;
      case 'graduation-cap': return LucideIcons.graduationCap;
      case 'landmark': return LucideIcons.landmark;
      case 'palette': return LucideIcons.palette;
      case 'utensils': return LucideIcons.utensils;
      case 'plane': return LucideIcons.plane;
      case 'car': return LucideIcons.car;
      case 'bike': return LucideIcons.bike;
      case 'medal': return LucideIcons.medal;
      case 'trophy': return LucideIcons.trophy;
      case 'target': return LucideIcons.target;
      default: return LucideIcons.layers;
    }
  }
}
