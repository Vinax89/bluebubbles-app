import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';

/// Retrieve the [AuthController] instance.
AuthController ac() =>
    Get.isRegistered<AuthController>() ? Get.find<AuthController>() : Get.put(AuthController());

/// Controller responsible for managing authentication state.
class AuthController extends GetxController {
  /// Whether an authentication dialog is currently being shown.
  final RxBool isAuthing = false.obs;

  /// Trigger local authentication if not already in progress.
  ///
  /// Returns `true` if authentication succeeds. If another authentication is
  /// already running, this returns `false` immediately without calling
  /// [LocalAuthentication.authenticate].
  Future<bool> authenticate({LocalAuthentication? localAuth, String? reason}) async {
    if (isAuthing.value) return false;
    isAuthing.value = true;
    localAuth ??= LocalAuthentication();
    try {
      return await localAuth.authenticate(
        localizedReason: reason ?? 'Please authenticate to unlock BlueBubbles',
        options: const AuthenticationOptions(stickyAuth: true),
      );
    } finally {
      isAuthing.value = false;
    }
  }
}

