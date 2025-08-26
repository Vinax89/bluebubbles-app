import 'package:get/get.dart';

class CustomService extends GetxService {
  final count = 0.obs;

  void increment() => count.value++;

  @override
  void onInit() {
    super.onInit();
    print('CustomService initialized');
  }

  @override
  void onClose() {
    print('CustomService disposed');
    super.onClose();
  }
}

CustomService customService = Get.isRegistered<CustomService>()
    ? Get.find<CustomService>()
    : Get.put(CustomService());
