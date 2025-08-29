import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:bluebubbles/services/custom_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    Get.reset();
  });

  test('CustomService increments count via DI', () {
    Get.lazyPut<CustomService>(() => CustomService());
    final service = Get.find<CustomService>();
    expect(service.count.value, 0);
    service.increment();
    expect(service.count.value, 1);
  });
}
