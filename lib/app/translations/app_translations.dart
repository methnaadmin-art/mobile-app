import 'package:get/get.dart';
import 'en_us.dart';
import 'ar_dz.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': Map<String, String>.from(enUS),
        'ar_DZ': {
          ...enUS,
          ...arDZ,
        },
      };
}
