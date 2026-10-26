import 'package:flutter/material.dart';

import '../models/course.dart';
import '../models/extra_request.dart';
import '../models/student.dart';
import '../utils/app_theme.dart';

/// Small rounded label with a coloured background.
class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, required this.color, this.icon, this.solid = false});

  final String label;
  final Color color;
  final IconData? icon;

  /// Filled background with white text instead of a soft tint.
  final bool solid;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: solid ? color : color.withAlpha(28),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: solid ? Colors.white : color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: solid ? Colors.white : color,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color clearanceColor(ClearanceStatus status) => switch (status) {
      ClearanceStatus.cleared => AppColors.success,
      ClearanceStatus.special => AppColors.warning,
      ClearanceStatus.notCleared => AppColors.danger,
    };

IconData clearanceIcon(ClearanceStatus status) => switch (status) {
      ClearanceStatus.cleared => Icons.verified,
      ClearanceStatus.special => Icons.workspace_premium_outlined,
      ClearanceStatus.notCleared => Icons.block,
    };

class ClearanceBadge extends StatelessWidget {
  const ClearanceBadge(this.status, {super.key, this.solid = false});

  final ClearanceStatus status;
  final bool solid;

  @override
  Widget build(BuildContext context) => StatusPill(
        status.label,
        color: clearanceColor(status),
        icon: clearanceIcon(status),
        solid: solid,
      );
}

/// FULL (red), "X left" (gold) at 5 or fewer seats, otherwise OPEN (green).
class SeatBadge extends StatelessWidget {
  const SeatBadge(this.section, {super.key, this.showCount = true});

  final CourseSection section;
  final bool showCount;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (section.seatLevel) {
      SeatLevel.full => ('FULL', AppColors.danger),
      SeatLevel.low => ('${section.seatsLeft} LEFT', AppColors.warning),
      SeatLevel.open => ('OPEN', AppColors.success),
    };
    // Wrap, not Row: on a narrow phone or with a large font the pill drops to
    // the next line instead of overflowing.
    return Wrap(
      spacing: 6,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (showCount)
          Text(
            '${section.enrolled}/${section.capacity}',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600),
          ),
        StatusPill(label, color: color),
      ],
    );
  }
}

Color requestColor(RequestStatus status) => switch (status) {
      RequestStatus.pending => AppColors.warning,
      RequestStatus.approved || RequestStatus.enrolled => AppColors.success,
      RequestStatus.rejected => AppColors.danger,
      RequestStatus.withdrawn => AppColors.textMuted,
    };

class RequestStatusPill extends StatelessWidget {
  const RequestStatusPill(this.status, {super.key});

  final RequestStatus status;

  @override
  Widget build(BuildContext context) => StatusPill(status.label, color: requestColor(status));
}
