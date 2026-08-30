import 'dart:convert';
import 'dart:io' show HttpClient, Platform;

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

const _iosBundleId = 'com.tithika.tithika';

/// Checks whether a newer build is available in the store.
///
/// The two platforms differ fundamentally:
///
///  * **Android** — Play exposes a real in-app update API. A *flexible*
///    update downloads in the background while the user keeps using the app,
///    then Play prompts to restart. Deferring is part of that native flow, so
///    the app shows no dialog of its own.
///  * **iOS** — Apple provides no such API. The only option is querying the
///    public iTunes lookup endpoint, comparing versions, and (if newer) asking
///    the caller to show a dialog that links out to the App Store.
///
/// Every path is failure-tolerant: no network, an unpublished app, or a
/// store-side error must never block launch or surface an error to the user.
abstract final class UpdateService {
  /// Set once an update prompt has been shown or dismissed this launch, so
  /// the user is asked at most once per session.
  static bool _promptedThisLaunch = false;

  /// Runs the platform-appropriate update check.
  ///
  /// Returns details when iOS has a newer build available and the caller
  /// should show its own dialog; returns null in every other case (Android,
  /// already current, already prompted, or any failure).
  static Future<IosUpdate?> checkForUpdate() async {
    if (_promptedThisLaunch) return null;

    try {
      if (Platform.isAndroid) {
        await _checkAndroid();
        return null;
      }
      if (Platform.isIOS) {
        return await _checkIos();
      }
    } catch (e) {
      // Deliberately swallowed but logged — an update check must never break
      // app startup. Not an empty catch: silent failures previously hid a
      // notification bug for several debugging sessions.
      debugPrint('UpdateService.checkForUpdate failed: $e');
    }
    return null;
  }

  /// Marks the prompt as consumed for this launch.
  static void markPrompted() => _promptedThisLaunch = true;

  static Future<void> _checkAndroid() async {
    final info = await InAppUpdate.checkForUpdate();
    if (info.updateAvailability != UpdateAvailability.updateAvailable) return;
    _promptedThisLaunch = true;
    // Flexible: downloads in the background, user keeps using the app, and
    // Play handles the "restart to install" prompt and the defer affordance.
    await InAppUpdate.startFlexibleUpdate();
    await InAppUpdate.completeFlexibleUpdate();
  }

  /// Returns the App Store version and listing URL when newer than installed.
  static Future<IosUpdate?> _checkIos() async {
    final client = HttpClientHolder.client;
    final uri = Uri.https('itunes.apple.com', '/lookup', {
      'bundleId': _iosBundleId,
      // Cache-bust: the lookup endpoint is heavily cached and can otherwise
      // report a stale version for hours after a release.
      't': DateTime.now().millisecondsSinceEpoch.toString(),
    });

    final request = await client.getUrl(uri);
    final response = await request.close();
    if (response.statusCode != 200) return null;

    final body = await response.transform(utf8.decoder).join();
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final results = decoded['results'] as List<dynamic>?;
    // Empty when the app isn't published yet — not an error.
    if (results == null || results.isEmpty) return null;

    final entry = results.first as Map<String, dynamic>;
    final storeVersion = entry['version'];
    if (storeVersion is! String) return null;

    final installed = (await PackageInfo.fromPlatform()).version;
    if (!_isNewer(storeVersion, installed)) return null;

    // trackViewUrl is the canonical App Store listing for this app, so the
    // numeric store ID never has to be hardcoded or kept in sync.
    final url = entry['trackViewUrl'];
    return IosUpdate(
      version: storeVersion,
      storeUrl: url is String ? url : null,
    );
  }

  /// True when [candidate] is a higher version than [current].
  ///
  /// Compares numerically per dot-separated segment: a plain string compare
  /// would rank "1.9.0" above "1.10.0". Non-numeric segments (e.g. "1.2.0-rc")
  /// compare as 0, which is enough for store version strings.
  @visibleForTesting
  static bool isNewer(String candidate, String current) =>
      _isNewer(candidate, current);

  static bool _isNewer(String candidate, String current) {
    final a = candidate.split('.');
    final b = current.split('.');
    for (var i = 0; i < (a.length > b.length ? a.length : b.length); i++) {
      final x = i < a.length ? int.tryParse(a[i].trim()) ?? 0 : 0;
      final y = i < b.length ? int.tryParse(b[i].trim()) ?? 0 : 0;
      if (x != y) return x > y;
    }
    return false;
  }
}

/// An available App Store update: the version, and the listing to open.
class IosUpdate {
  final String version;

  /// App Store listing URL, straight from the lookup response. Null if the
  /// response omitted it, in which case the caller should skip the link.
  final String? storeUrl;

  const IosUpdate({required this.version, required this.storeUrl});
}

/// Indirection so tests can swap in a fake client.
abstract final class HttpClientHolder {
  static HttpClient client = HttpClient();
}
