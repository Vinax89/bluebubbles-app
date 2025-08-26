import 'package:bluebubbles/services/ui/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';

class _FakeLocalAuth extends LocalAuthentication {
  int calls = 0;

  @override
  Future<bool> authenticate({
    required String localizedReason,
    AuthenticationOptions options = const AuthenticationOptions(),
  }) async {
    calls++;
    // Simulate some delay like a real auth dialog would have.
    await Future.delayed(const Duration(milliseconds: 100));
    return true;
  }
}

void main() {
  test('concurrent auth attempts trigger only one dialog', () async {
    final controller = AuthController();
    final fake = _FakeLocalAuth();

    final futures = [
      controller.authenticate(localAuth: fake, reason: 'test'),
      controller.authenticate(localAuth: fake, reason: 'test'),
      controller.authenticate(localAuth: fake, reason: 'test'),
    ];

    await Future.wait(futures);

    expect(fake.calls, 1);
    expect(controller.isAuthing.value, isFalse);
  });
}

