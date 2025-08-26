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
    bool? chaosMode,
    bool? stressMode,
    List<String> saveAdditionalSettings = const [],
    Duration? delay,
  }
) async {
  if (ss.settings.simulateServerDelay.value || delay != null) {
    await Future.delayed(delay ?? const Duration(seconds: 2));
  }

  String sanitized = sanitizeServerAddress(address: newServerUrl)!;
  bool addressChanged = sanitized != ss.settings.serverAddress.value;
  bool flagsChanged = false;
  List<String> saveKeys = ["serverAddress", ...saveAdditionalSettings];

  if (chaosMode != null && chaosMode != ss.settings.chaosMode.value) {
    ss.settings.chaosMode.value = chaosMode;
    saveKeys.add("chaosMode");
    flagsChanged = true;
  }

  if (stressMode != null && stressMode != ss.settings.stressMode.value) {
    ss.settings.stressMode.value = stressMode;
    saveKeys.add("stressMode");
    flagsChanged = true;
  }

  if (force || addressChanged || flagsChanged) {
    ss.settings.serverAddress.value = sanitized;

    await ss.settings.saveMany(saveKeys);

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
    List<String> saveAdditionalSettings = const [],
    Duration? delay,
  }
) async {
  if (ss.settings.simulateServerDelay.value || delay != null) {
    await Future.delayed(delay ?? const Duration(seconds: 2));
  }
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

  // If battery optimizations are already disabled, return true
  if (isDisabled == true) return true;

  // If optimizations are not disabled, prompt the user to disable them
  isDisabled = await DisableBatteryOptimization.showDisableBatteryOptimizationSettings();
  return isDisabled ?? false;
}