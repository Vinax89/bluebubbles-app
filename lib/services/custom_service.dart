import 'package:get/get.dart';
import 'package:bluebubbles/utils/logger/logger.dart';

class CustomService extends GetxService {
  final count = 0.obs;

  void increment() => count.value++;

  @override
  void onInit() {
    super.onInit();
    Logger.debug('CustomService initialized');
  }

  @override
  void onClose() {
    Logger.debug('CustomService disposed');
    super.onClose();
  }
}

CustomService customService = Get.isRegistered<CustomService>()
    ? Get.find<CustomService>()
    : Get.put(CustomService());
