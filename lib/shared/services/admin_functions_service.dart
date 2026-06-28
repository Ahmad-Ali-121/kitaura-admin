import 'package:cloud_functions/cloud_functions.dart';

/// Single entry point for all admin Cloud Function calls.
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

  // ─── Claim management ──────────────────────────────────────────────────
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

  // ─── Read-only ─────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getDashboardKpis() async {
    final result = await _callable('adminGetDashboardKpis').call<Map>({});
    return Map<String, dynamic>.from(result.data);
  }

  static Future<Map<String, dynamic>> listUsers({
    int page = 0,
    int pageSize = 50,
    String search = '',
    String planFilter = 'all',
    String sortBy = 'signupDesc',
  }) async {
    final result = await _callable('adminListUsers').call<Map>({
      'page': page,
      'pageSize': pageSize,
      'search': search,
      'planFilter': planFilter,
      'sortBy': sortBy,
    });
    return Map<String, dynamic>.from(result.data);
  }

  static Future<Map<String, dynamic>> getUserOverview({
    required String targetUid,
  }) async {
    final result = await _callable('adminGetUserOverview').call<Map>({
      'targetUid': targetUid,
    });
    return Map<String, dynamic>.from(result.data);
  }

  // ─── Mutations ─────────────────────────────────────────────────────────
  /// Grant Pro (`plan: 'pro'`) or revoke (`plan: 'free'`).
  static Future<Map<String, dynamic>> setPlan({
    required String targetUid,
    required String plan,
    int cycleDays = 30,
  }) async {
    final result = await _callable('adminSetPlan').call<Map>({
      'targetUid': targetUid,
      'plan': plan,
      'cycleDays': cycleDays,
    });
    return Map<String, dynamic>.from(result.data);
  }

  static Future<Map<String, dynamic>> resetCounters({
    required String targetUid,
  }) async {
    final result = await _callable('adminResetCounters').call<Map>({
      'targetUid': targetUid,
    });
    return Map<String, dynamic>.from(result.data);
  }

  static Future<Map<String, dynamic>> resetHourlyBurst({
    required String targetUid,
  }) async {
    final result =
    await _callable('adminResetHourlyBurst').call<Map>({
      'targetUid': targetUid,
    });
    return Map<String, dynamic>.from(result.data);
  }

  static Future<Map<String, dynamic>> resetRefusalCount({
    required String targetUid,
  }) async {
    final result =
    await _callable('adminResetRefusalCount').call<Map>({
      'targetUid': targetUid,
    });
    return Map<String, dynamic>.from(result.data);
  }

  /// Extend (or start) a trial by N days. Rejected by backend for Pro users.
  static Future<Map<String, dynamic>> extendTrial({
    required String targetUid,
    int days = 7,
  }) async {
    final result = await _callable('adminExtendTrial').call<Map>({
      'targetUid': targetUid,
      'days': days,
    });
    return Map<String, dynamic>.from(result.data);
  }

  // ─── Config ────────────────────────────────────────────────────────────
  /// Update one of: 'limits' | 'pricing' | 'proTemplates' | 'featureFlags'
  static Future<Map<String, dynamic>> updateConfig({
    required String docId,
    required Map<String, dynamic> newData,
  }) async {
    final result = await _callable('adminUpdateConfig').call<Map>({
      'docId': docId,
      'newData': newData,
    });
    return Map<String, dynamic>.from(result.data);
  }

  // ─── Announcement ──────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> updateAnnouncement({
    required bool active,
    required String title,
    required String body,
    required String severity, // 'info' | 'warn' | 'critical'
    String? linkUrl,
    String? linkLabel,
  }) async {
    final result = await _callable('adminUpdateAnnouncement').call<Map>({
      'active': active,
      'title': title,
      'body': body,
      'severity': severity,
      'linkUrl': linkUrl,
      'linkLabel': linkLabel,
    });
    return Map<String, dynamic>.from(result.data);
  }

  // ─── AI Activity ───────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> listAiActivity({
    int limit = 50,
    String? cursor,
    String? startDate,
    String? statusFilter,    // ← add this
  }) async {
    final result = await _callable('adminListAiActivity').call<Map>({
      'limit': limit,
      if (cursor != null) 'cursor': cursor,
      if (startDate != null) 'startDate': startDate,
      if (statusFilter != null) 'statusFilter': statusFilter,
    });
    return Map<String, dynamic>.from(result.data);
  }
}