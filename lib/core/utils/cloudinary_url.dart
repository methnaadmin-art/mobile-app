/// Cloudinary URL transformation helper for optimized image delivery.
///
/// Inserts Cloudinary transformations into existing URLs to serve
/// appropriately sized images for different UI contexts, saving bandwidth.
class CloudinaryUrl {
  CloudinaryUrl._();

  /// Thumbnail: compact square for avatars/chips.
  /// Use for: avatars, small list tiles, online user indicators.
  static String thumbnail(String? url) =>
      _transform(url, 'w_220,h_220,c_fill,g_auto,f_auto,dpr_auto,q_auto:good');

  /// Medium: primary card/list delivery with face-friendly quality.
  /// Use for: grid cards, user cards, category user tiles.
  static String medium(String? url) => _transform(
    url,
    'w_1080,h_1440,c_fill,g_auto,f_auto,dpr_auto,q_auto:best',
  );

  /// Large: profile-detail quality.
  /// Use for: profile detail hero and larger in-app views.
  static String large(String? url) =>
      _transform(url, 'w_1800,h_2400,c_limit,f_auto,dpr_auto,q_auto:best');

  /// Full: fullscreen/zoom delivery.
  /// Use for: photo viewer, zoom.
  static String full(String? url) =>
      _transform(url, 'f_auto,dpr_auto,q_auto:best');

  /// Custom resize: specific width.
  static String getResizedUrl(String? url, {int width = 800}) =>
      _transform(url, 'w_$width,c_limit,f_auto,q_auto:good');

  /// Insert transformation into a Cloudinary URL.
  /// If the URL is null, empty, or not a Cloudinary URL, returns it as-is.
  static String _transform(String? url, String transform) {
    if (url == null || url.isEmpty) return url ?? '';
    if (!url.contains('/upload/')) return url;

    final parsed = Uri.tryParse(url);
    final host = (parsed?.host ?? '').toLowerCase();
    final isCloudinaryHost =
        host.contains('cloudinary.com') ||
        url.toLowerCase().contains('cloudinary.com/');

    // Do not transform generic backend upload endpoints.
    if (!isCloudinaryHost) return url;

    // If the URL already has Cloudinary transformations, replace them so we
    // do not chain lower-quality presets (for example, medium -> large).
    final withResetTransform = url.replaceFirst(
      RegExp(r'/upload/(?:[^/]+/)*(?=v\d+/)'),
      '/upload/$transform/',
    );

    if (withResetTransform != url) {
      return withResetTransform;
    }

    return url.replaceFirst('/upload/', '/upload/$transform/');
  }
}
