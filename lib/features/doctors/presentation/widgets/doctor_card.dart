import 'package:flutter/material.dart';

import '../../../../core/entities/doctor.dart';
import 'doctor_photo.dart';

/// One row in the doctors browse list: avatar, name, specialty, rating,
/// and clinic address, tappable to open the profile.
class DoctorCard extends StatelessWidget {
  const DoctorCard({super.key, required this.doctor, this.onTap});

  final Doctor doctor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: DoctorPhoto(doctor: doctor),
        title: Text(doctor.name, style: theme.textTheme.titleMedium),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(doctor.specialty),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.star, size: 16, color: Colors.amber.shade700),
                  const SizedBox(width: 4),
                  Text(doctor.rating.toStringAsFixed(1)),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      doctor.clinicAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
