import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/services/admin_functions_service.dart';
import '../model/admin_kpi_model.dart';

/// Fetches dashboard KPIs from the Cloud Function. Refresh by calling
/// `ref.invalidate(adminDashboardProvider)` from the View.
final adminDashboardProvider = FutureProvider<AdminKpis>((ref) async {
  final raw = await AdminFunctionsService.getDashboardKpis();
  return AdminKpis.fromMap(raw);
});