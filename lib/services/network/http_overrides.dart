import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:universal_io/io.dart';

bool hasBadCert = false;

class BadCertOverride extends HttpOverrides {
  @override
  createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      // If there is a bad certificate callback, override it if the host is part of
      // your server URL
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        String serverUrl = sanitizeServerAddress() ?? "";
        if (host.startsWith("*")) {
          final regex = RegExp(
              "^((\\*|[\\w\\d]+(-[\\w\\d]+)*)\\.)*(${host.split(".").reversed.take(2).toList().reversed.join(".")})\$");
          hasBadCert = regex.hasMatch(serverUrl);
        } else {
          hasBadCert = serverUrl.endsWith(host);
        }

        if (hasBadCert && !ss.settings.trustSelfSignedCerts.value) {
          Logger.error("Untrusted certificate for $host", tag: "BadCertOverride");
          showSnackbar("Certificate Error", "The certificate presented by $host is not trusted.");
        }

        return hasBadCert && ss.settings.trustSelfSignedCerts.value;
      };
  }
}
