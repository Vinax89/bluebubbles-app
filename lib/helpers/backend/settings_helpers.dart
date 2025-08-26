import 'package:bluebubbles/helpers/backend/foreground_service_helpers.dart';
import 'package:bluebubbles/helpers/network/network_helpers.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';

Future<bool> saveNewServerUrl(
  String newServerUrl,
  {
    bool tryRestartForegroundService = true,
    bool restartSocket = true,
    bool force = false,
    List<String> saveAdditionalSettings = const [],
    bool? chaosMode,
    bool? stressMode,
  }
) async {
  String sanitized = sanitizeServerAddress(address: newServerUrl)!;

  bool didChange = force || sanitized != ss.settings.serverAddress.value;
  bool flagsChanged = false;

  if (chaosMode != null && chaosMode != ss.settings.chaosMode.value) {
    ss.settings.chaosMode.value = chaosMode;
    flagsChanged = true;
  }

  if (stressMode != null && stressMode != ss.settings.stressMode.value) {
    ss.settings.stressMode.value = stressMode;
    flagsChanged = true;
  }

  if (didChange) {
    ss.settings.serverAddress.value = sanitized;
  }

  if (didChange || flagsChanged) {
    await ss.settings.saveMany([
      if (didChange) "serverAddress",
      if (chaosMode != null) "chaosMode",
      if (stressMode != null) "stressMode",
      ...saveAdditionalSettings,
    ]);

    // Don't await because we don't care about the result
    if (tryRestartForegroundService) {
      restartForegroundService();
    }

    try {
      if (restartSocket) {
        socket.restartSocket();
      }
    } catch (e, stack) {
      Logger.error("Failed to restart socket!", error: e, trace: stack);
    }

    return true;
  }

  return false;
}

Future<void> clearServerUrl(
  {
    bool tryRestartForegroundService = true,
    List<String> saveAdditionalSettings = const []
  }
) async {
  ss.settings.serverAddress.value = "";
  await ss.settings.saveMany(["serverAddress", ...saveAdditionalSettings]);

  // Don't await because we don't care about the result
  if (tryRestartForegroundService) {
    restartForegroundService();
  }
}

/// Prompts the user to disable battery optimizations for the app
/// 
/// Returns true if the user has disabled battery optimizations
Future<bool> disableBatteryOptimizations() async {
  bool? isDisabled = await DisableBatteryOptimization.isAllBatteryOptimizationDisabled;

  // If battery optomizations are already disabled, return true
  if (isDisabled == true) return true;

  // If optimizations are not disabled, prompt the user to disable them
  isDisabled = await DisableBatteryOptimization.showDisableBatteryOptimizationSettings();
  return isDisabled ?? false;
}