import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// One KPI tile. Label on top, big value below, optional sub-line.
class KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String? subline;
  final bool emphasis;

  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor = AppColors.magentaBloom,
    this.subline,
    this.emphasis = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: emphasis
              ? AppColors.magentaBloom.withValues(alpha: 0.4)
              : AppColors.almondSilk,
          width: emphasis ? 1.5 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slateGrey,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.prussianBlue,
              height: 1.1,
            ),
          ),
          if (subline != null) ...[
            const SizedBox(height: 4),
            Text(
              subline!,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.slateGrey,
              ),
            ),
          ],
        ],
      ),
    );
  }
}