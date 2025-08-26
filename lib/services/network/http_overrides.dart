import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:universal_io/io.dart';

bool get hasBadCert =>
    (HttpOverrides.global as BadCertOverride?)?.hasBadCert ?? false;

class BadCertOverride extends HttpOverrides {
  bool _hasBadCert = false;

  bool get hasBadCert => _hasBadCert;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      // If there is a bad certificate callback, override it if the host is part of
      // your server URL
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        String serverUrl = sanitizeServerAddress() ?? "";
        if (host.startsWith("*")) {
          final regex = RegExp(
              "^((\\*|[\\w\\d]+(-[\\w\\d]+)*)\\.)*(${host.split(".").reversed.take(2).toList().reversed.join(".")})\$");
          _hasBadCert = regex.hasMatch(serverUrl);
        } else {
          _hasBadCert = serverUrl.endsWith(host);
        }

        if (_hasBadCert && !ss.settings.trustSelfSignedCerts.value) {
          Logger.error("Untrusted certificate for $host", tag: "BadCertOverride");
          showSnackbar("Certificate Error", "The certificate presented by $host is not trusted.");
        }

        return _hasBadCert && ss.settings.trustSelfSignedCerts.value;
      };
  }
}
