import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/services/admin_functions_service.dart';
import '../model/admin_user_detail.dart';

/// Fetches one user's full overview. Family — keyed by target UID.
/// Refresh via `ref.invalidate(adminUserDetailProvider(uid))`.
final adminUserDetailProvider =
FutureProvider.family<AdminUserDetail, String>((ref, uid) async {
  final raw = await AdminFunctionsService.getUserOverview(targetUid: uid);
  return AdminUserDetail.fromMap(raw);
});