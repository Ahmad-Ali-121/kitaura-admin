import 'package:cloud_functions/cloud_functions.dart';

/// Single entry point for all admin Cloud Function calls.
///
/// Every admin endpoint exposed in `functions/admin.js` should have a
/// matching method here. All calls go through us-central1 region and
/// use a 60-second timeout (override per-method if a function is slow).
class AdminFunctionsService {
  AdminFunctionsService._();

  static FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: 'us-central1');

  static HttpsCallable _callable(
    String name, {
    Duration timeout = const Duration(seconds: 60),
  }) =>
      _functions.httpsCallable(
        name,
        options: HttpsCallableOptions(timeout: timeout),
      );

  // ─── setAdminClaim ─────────────────────────────────────────────────────
  /// Grant or revoke admin custom claim on a target user.
  /// Caller must already be an admin. Self-revoke is rejected by backend.
  ///
  /// Returns `{ success, targetUid, email, isAdmin }`.
  static Future<Map<String, dynamic>> setAdminClaim({
    required String targetUid,
    required bool grant,
  }) async {
    final result = await _callable('setAdminClaim').call<Map>({
      'targetUid': targetUid,
      'grant': grant,
    });
    return Map<String, dynamic>.from(result.data);
  }
}
