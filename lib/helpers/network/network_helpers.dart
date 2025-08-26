import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mobile_networks/mobile_networks.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:universal_io/io.dart';

/// Take the passed [address] or serverAddress from Settings
/// and sanitize it, ensuring it includes an HTTP or HTTPS scheme.
/// HTTPS is used by default unless the user explicitly provides an HTTP scheme.
String? sanitizeServerAddress({String? address}) {
  String serverAddress = address ?? http.origin;

  String sanitized = serverAddress.replaceAll('"', "").trim();
  if (sanitized.isEmpty) return null;

  Uri? uri = Uri.tryParse(sanitized);
  if (uri?.scheme.isEmpty ?? false) {
    uri = Uri.tryParse("https://$sanitized");
  }

  return uri.toString();
}

Future<String> getDeviceName() async {
  String deviceName = "bluebubbles-client";

  try {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    List<String> items = [];

    // We need a unique identifier to be generated once per installation.
    // Device Info Plus doesn't provide us with an idempotent identifier,
    // so we'll have to generate one ourselves, and store it for future use.
    int uniqueId = ss.settings.firstFcmRegisterDate.value;
    if (uniqueId == 0) {
      uniqueId = (DateTime.now().millisecondsSinceEpoch / 1000).round();
      ss.settings.firstFcmRegisterDate.value = uniqueId;
      await ss.settings.saveOne('firstFcmRegisterDate');
    }

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      items.addAll([androidInfo.brand, androidInfo.model, uniqueId.toString()]);
    } else if (kIsWeb) {
      WebBrowserInfo webInfo = await deviceInfo.webBrowserInfo;
      items.addAll([webInfo.browserName.name, webInfo.platform!]);
    } else if (Platform.isWindows) {
      WindowsDeviceInfo windowsInfo = await deviceInfo.windowsInfo;
      items.addAll([windowsInfo.computerName]);
    } else if (Platform.isLinux) {
      LinuxDeviceInfo linuxInfo = await deviceInfo.linuxInfo;
      items.addAll([linuxInfo.prettyName]);
    }

    if (items.isNotEmpty) {
      deviceName = items.join("_").toLowerCase().replaceAll(' ', '_');
    }
  } catch (ex, stack) {
    Logger.error("Failed to get device name! Defaulting to 'bluebubbles-client'", error: ex, trace: stack);
  }

  return deviceName;
}

/// Determines if the current connection is considered high speed.
///
/// A high-speed connection is defined as either a Wi-Fi network with a
/// measurable link speed or a cellular connection of at least 4G/LTE.
/// If the check fails or the network type cannot be determined, `false`
/// is returned so the caller can fall back to compressed downloads.
Future<bool> isHighSpeedConnection() async {
  try {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.wifi) {
      try {
        final speed = await NetworkInfo().getWifiSpeed();
        if (speed == null) return true;
        return speed >= 30; // Mbps
      } catch (_) {
        // If we fail to fetch Wi-Fi speed, assume Wi-Fi is fast enough
        return true;
      }
    } else if (connectivity == ConnectivityResult.mobile) {
      try {
        final generation = await MobileNetworks().getMobileNetworkGeneration();
        return generation == MobileNetworkGeneration.fourG ||
            generation == MobileNetworkGeneration.fiveG ||
            generation == MobileNetworkGeneration.lte;
      } catch (_) {
        // Unknown generation, treat as not high speed
        return false;
      }
    }
  } catch (ex, stack) {
    Logger.error('Failed to determine connection type', error: ex, trace: stack);
  }

  return false;
}
