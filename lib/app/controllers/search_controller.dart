import 'package:get/get.dart';
import 'package:methna_app/app/data/services/api_service.dart';
import 'package:methna_app/app/data/models/user_model.dart';
import 'package:methna_app/core/constants/api_constants.dart';

class SearchRadarController extends GetxController with GetTickerProviderStateMixin {
  final ApiService _api = Get.find<ApiService>();
  bool _searchInFlight = false;

  final RxList<UserModel> foundUsers = <UserModel>[].obs;
  final RxBool isSearching = true.obs;
  final RxDouble radarAngle = 0.0.obs;
  final RxInt usersFoundCount = 0.obs;

  // Filter state
  final RxDouble maxDistance = 50.0.obs;
  final RxString genderFilter = 'all'.obs;
  final RxInt minAge = 18.obs;
  final RxInt maxAge = 45.obs;
  final RxBool verifiedOnlyFilter = false.obs;

  @override
  void onInit() {
    super.onInit();
    startRadarSearch();
  }

  Future<void> startRadarSearch() async {
    if (_searchInFlight) return;
    _searchInFlight = true;
    isSearching.value = true;
    foundUsers.clear();
    usersFoundCount.value = 0;

    // Simulate radar sweep while fetching
    _animateRadar();

    try {
      final response = await _api.get(ApiConstants.nearbyUsers, queryParameters: {
        'limit': 30,
        'maxDistance': maxDistance.value.round(),
        'minAge': minAge.value,
        'maxAge': maxAge.value,
        if (genderFilter.value != 'all') 'gender': genderFilter.value,
        if (verifiedOnlyFilter.value) 'verifiedOnly': true,
      });
      final list = response.data is List ? response.data : response.data['users'] ?? [];
        final seenUserIds = <String>{};
        final users = (list as List)
          .whereType<Map<String, dynamic>>()
          .map((u) => UserModel.fromJson(u))
          .where((u) => u.id.isNotEmpty && seenUserIds.add(u.id))
          .toList();

      // Reveal users one by one with delay for radar effect
      for (final user in users) {
        await Future.delayed(const Duration(milliseconds: 300));
        foundUsers.add(user);
        usersFoundCount.value = foundUsers.length;
      }
    } catch (_) {
      // keep UI graceful in failure; search will complete with empty state
    } finally {
      await Future.delayed(const Duration(seconds: 1));
      isSearching.value = false;
      _searchInFlight = false;
    }
  }

  void _animateRadar() async {
    while (isSearching.value) {
      for (double i = 0; i <= 360; i += 3) {
        if (!isSearching.value) break;
        radarAngle.value = i;
        await Future.delayed(const Duration(milliseconds: 16));
      }
    }
  }

  void retry() => startRadarSearch();
}
