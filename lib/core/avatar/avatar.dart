// ignore_for_file: dangling_library_doc_comments

/// Avatar System - Complete 3D/Animated Avatar for Methna App
///
/// A lightweight, premium avatar system that reacts to user actions
/// and provides emotional feedback.
///
/// ## Usage
///
/// ### 1. Basic Setup
/// ```dart
/// import 'package:methna_app/core/avatar/avatar.dart';
///
/// // Put controller in your main.dart or binding
/// Get.put(AvatarController(), permanent: true);
/// ```
///
/// ### 2. Display Avatar
/// ```dart
/// AvatarWidget(
///   size: 120,
///   showGlow: true,
///   onTap: () => avatar.wave(),
/// )
/// ```
///
/// ### 3. Trigger Reactions
/// ```dart
/// final avatar = Get.find<AvatarController>();
///
/// avatar.onLogin();    // Wave animation
/// avatar.onLike();     // Happy animation
/// avatar.onSwipe();    // Look animation
/// avatar.onError();    // Sad animation
/// avatar.idle();       // Return to idle
/// ```
///
/// ### 4. Integration in Controllers
/// ```dart
/// class MyController extends GetxController with AvatarIntegrationMixin {
///   void doSomething() {
///     // Your logic
///     avatarHappy();  // Trigger happy animation
///   }
/// }
/// ```
///
/// ## Avatar States
/// - `idle` - Breathing/subtle movement (default)
/// - `wave` - Greeting/waving animation
/// - `happy` - Smiling/celebrating
/// - `sad` - Disappointed expression
/// - `look` - Head following movement
/// - `thinking` - Processing/loading state
/// - `welcome` - First-time greeting
/// - `success` - Achievement celebration
/// - `loading` - Activity indicator
/// - `sleeping` - Inactivity state
///
/// ## Animation Files
/// Place Lottie JSON files in `assets/animations/avatar/`:
/// - idle.json
/// - wave.json
/// - happy.json
/// - sad.json
/// - look.json
/// - thinking.json
/// - welcome.json
/// - success.json
/// - loading.json
/// - sleeping.json
///
/// ## Design
/// - Style: Minimal, elegant, Islamic-friendly
/// - Colors: Green + Gold accents
/// - Performance: 60 FPS, lightweight
/// - Fallback: Animated gradients if Lottie fails
///
/// ## Performance Tips
/// - Use `const AvatarWidget()` where possible
/// - Set `repeat: false` for one-shot animations
/// - Use `AvatarCompact` for small spaces
/// - Avatar auto-returns to idle after 3 seconds

export 'avatar_controller.dart';
export 'avatar_widget.dart';
export 'avatar_integration.dart';
