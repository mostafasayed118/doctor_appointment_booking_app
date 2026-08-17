import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../dev/component_gallery.dart';
import '../../di/locator.dart';
import '../../features/auth/presentation/auth_cubit.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/signup_page.dart';
import '../../features/booking/presentation/slot_selection_cubit.dart';
import '../../features/booking/presentation/slot_selection_page.dart';
import '../../features/doctors/presentation/doctor_profile_cubit.dart';
import '../../features/doctors/presentation/doctor_profile_page.dart';
import '../../features/doctors/presentation/doctors_list_cubit.dart';
import '../../features/doctors/presentation/doctors_list_page.dart';
import '../../core/entities/doctor.dart';
import '../../shared/components/empty_state.dart';
import 'auth_guard.dart';

/// Builds the app's [GoRouter] with the auth guard wired to [authCubit].
///
/// [authCubit] doubles as `refreshListenable`: every state change re-runs
/// the redirect, so sign-in/sign-out navigate automatically — no manual
/// `context.go` after auth actions.
GoRouter buildAppRouter(
  AuthCubit authCubit, {
  String initialLocation = '/',
}) {
  // Location a signed-out user was trying to reach before being sent to
  // /login; restored once they authenticate. Owned by the redirect closure
  // so it can't leak between routers.
  String? pendingLocation;

  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: authCubit,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final target = authRedirect(
        authCubit.state,
        location,
        pendingLocation: pendingLocation,
      );

      // Remember the protected location being redirected away from — but
      // never the root or the login screen itself.
      if (target == '/login' && location != '/login' && location != '/') {
        pendingLocation = location;
      }
      // The deep link was resumed (or dropped) — forget it.
      if (target != null && target != '/login') {
        pendingLocation = null;
      }
      return target;
    },
    routes: [
      // Every screen reads the auth state from [authCubit] via context —
      // the router is what puts it in the tree. Pages never reach for the
      // locator singleton, which is what lets tests inject a fake cubit.
      GoRoute(
        path: '/login',
        builder: (context, state) => BlocProvider.value(
          value: authCubit,
          child: const LoginPage(),
        ),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => BlocProvider.value(
          value: authCubit,
          child: const SignupPage(),
        ),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => BlocProvider.value(
          value: authCubit,
          child: const ComponentGallery(),
        ),
      ),
      // Screen-scoped cubits: created fresh per navigation via the locator
      // factory and closed by BlocProvider when the route is disposed.
      GoRoute(
        path: '/doctors',
        builder: (context, state) => BlocProvider(
          create: (_) => sl<DoctorsListCubit>()..load(),
          child: const DoctorsListPage(),
        ),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => BlocProvider(
              create: (_) => sl<DoctorProfileCubit>()
                ..load(state.pathParameters['id']!),
              child: const DoctorProfilePage(),
            ),
            routes: [
              GoRoute(
                path: 'book',
                builder: (context, state) => BlocProvider(
                  create: (_) => sl<SlotSelectionCubit>()
                    ..load(state.pathParameters['id']!),
                  // The profile page passes the Doctor via `extra` so the
                  // booking AppBar can name them; deep-link restores fall
                  // back to the generic localized title.
                  child: SlotSelectionPage(
                    doctorName: (state.extra as Doctor?)?.name,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => const Scaffold(
      body: EmptyState(
        icon: Icons.map_outlined,
        title: 'Route not found',
        subtitle: 'The page you were looking for does not exist.',
      ),
    ),
  );
}
