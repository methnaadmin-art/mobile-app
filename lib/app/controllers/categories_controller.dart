import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/data/models/category_model.dart';
import 'package:methna_app/app/data/models/user_model.dart';
import 'package:methna_app/app/data/services/api_service.dart';
import 'package:methna_app/core/constants/api_constants.dart';
import 'package:methna_app/core/utils/helpers.dart';

class CategoriesController extends GetxController {
  final ApiService _api = Get.find<ApiService>();

  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;

  // Users for a selected category
  final RxList<UserModel> categoryUsers = <UserModel>[].obs;
  final RxBool isLoadingUsers = false.obs;
  final Rx<CategoryModel?> selectedCategory = Rx<CategoryModel?>(null);
  final RxInt currentPage = 1.obs;
  final RxInt totalUsers = 0.obs;
  final RxBool hasMore = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    isLoading.value = true;
    hasError.value = false;
    try {
      final response = await _api.get(
        ApiConstants.categories,
        options: Options(extra: {'disable_retry': true}),
      );
      final data = response.data;
      final list = (data is Map && data.containsKey('data')) ? data['data'] : (data is List ? data : []);
      
      categories.assignAll((list as List)
          .map((c) => CategoryModel.fromJson(c))
          .toList());
      debugPrint('[Categories] Fetched ${categories.length} categories');
    } catch (e) {
      debugPrint('[Categories] fetchCategories error: $e');
      hasError.value = true;
      if (categories.isEmpty) {
        Helpers.showSnackbar(message: 'Failed to load categories', isError: true);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> selectCategory(CategoryModel category) async {
    selectedCategory.value = category;
    categoryUsers.clear();
    currentPage.value = 1;
    hasMore.value = true;
    totalUsers.value = category.userCount;
    await fetchCategoryUsers(category.id);
  }

  Future<void> fetchCategoryUsers(String categoryId, {bool loadMore = false}) async {
    if (isLoadingUsers.value) return;
    if (loadMore && !hasMore.value) return;

    isLoadingUsers.value = true;
    try {
      final page = loadMore ? currentPage.value + 1 : 1;
      final response = await _api.get(
        ApiConstants.categoryUsers(categoryId),
        queryParameters: {'page': page, 'limit': 20},
      );

      final data = response.data;
      final list = (data is Map && data.containsKey('users')) ? data['users'] : (data is List ? data : []);
      final users = (list as List).map((u) => UserModel.fromJson(u)).toList();

      if (loadMore) {
        categoryUsers.addAll(users);
      } else {
        categoryUsers.assignAll(users);
      }

      currentPage.value = page;
      if (data is Map) {
        totalUsers.value = data['total'] ?? totalUsers.value;
      }
      hasMore.value = users.length >= 20;
    } catch (e) {
      debugPrint('[Categories] fetchCategoryUsers error: $e');
      Helpers.showSnackbar(message: 'Failed to load users', isError: true);
    } finally {
      isLoadingUsers.value = false;
    }
  }

  void loadMore() {
    if (selectedCategory.value != null) {
      fetchCategoryUsers(selectedCategory.value!.id, loadMore: true);
    }
  }
}
