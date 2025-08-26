import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/custom_service.dart';

class CustomServiceWidget extends StatelessWidget {
  CustomServiceWidget({super.key});

  final CustomService service = customService;

  @override
  Widget build(BuildContext context) {
    return Obx(() => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Count: ${service.count.value}'),
            ElevatedButton(
              onPressed: service.increment,
              child: const Text('Increment'),
            ),
          ],
        ));
  }
}
