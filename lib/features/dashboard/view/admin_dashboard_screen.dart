import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.almondSilk),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.dashboard_outlined,
                size: 48,
                color: AppColors.magentaBloom,
              ),
              SizedBox(height: 16),
              Text(
                'Admin panel ready',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: AppColors.prussianBlue,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Phase A1 complete. KPI cards, user list, and AI '
                    'activity views will land in upcoming steps.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.slateGrey,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}