import 'package:flutter/material.dart';

import '../../../../core/entities/doctor.dart';

/// Doctor avatar: the seeded photo when available, otherwise initials on a
/// tinted circle. [photoUrl] is empty until Task 10's seed populates
/// Storage, and the network may fail offline — so the initials fallback is
/// not a corner case, it's the default look.
class DoctorPhoto extends StatelessWidget {
  const DoctorPhoto({super.key, required this.doctor, this.radius = 28});

  final Doctor doctor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // CircleAvatar asserts onForegroundImageError == null when the image is
    // null — so only attach the error handler when there IS an image.
    final image = doctor.photoUrl.isEmpty ? null : NetworkImage(doctor.photoUrl);
    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      foregroundImage: image,
      onForegroundImageError: image == null ? null : (_, _) {},
      child: Text(_initials(doctor.name)),
    );
  }

  static String _initials(String name) => name
      .split(' ')
      .where((w) => w.isNotEmpty)
      .take(2)
      .map((w) => w[0])
      .join()
      .toUpperCase();
}
