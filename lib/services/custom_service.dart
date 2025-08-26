import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:get/get.dart';

class CustomService extends GetxService {
  final count = 0.obs;

  void increment() => count.value++;

  @override
  void onInit() {
    super.onInit();
    Logger.info('CustomService initialized');
  }

  @override
  void onClose() {
    Logger.info('CustomService disposed');
    super.onClose();
  }
}

CustomService customService = Get.isRegistered<CustomService>()
    ? Get.find<CustomService>()
    : Get.put(CustomService());
