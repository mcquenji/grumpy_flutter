import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:grumpy_flutter/grumpy_flutter.dart';
import 'package:meta/meta.dart';

// This is the base class for all route guards.
// ignore: guards_must_extend_guard
/// A Guard is a middleware that determines whether a route can be activated
/// based on custom logic, such as user authentication or permissions.
///
/// If the guard denies access, it can optionally specify a [redirectTo] path
/// to navigate to instead.
///
/// If access is denied and no [redirectTo] is provided, a [RouteNotAuthorizedError] is thrown.
abstract class Guard<AppConfig extends ResponsiveBreakpoints>
    extends Middleware<Widget, AppConfig>
    with TelemetryMixin {
  /// An optional path to redirect to if the guard denies access.
  final String? redirectTo;

  /// Creates a [Guard] with an optional [redirectTo] path.
  const Guard({this.redirectTo});

  /// Determines whether the route can be activated.
  /// Returns `true` if access is allowed, `false` otherwise.
  FutureOr<bool> canActivate(RouteContext context);

  @override
  String get group => '${super.group}.Guard';

  @nonVirtual
  @override
  Future<RouteContext> call(RouteContext context) async {
    log('Authorizing route: ${context.fullPath} ');
    final allowed = await trace<bool>(
      'Middleware.Guard.$runtimeType.canActivate',
      () async => await canActivate(context),
      attributes: {
        'route': context.toJson(),
        'redirectTo': redirectTo,
        'guard': logTag,
      },
    );

    if (allowed) {
      log('Route authorized: ${context.fullPath}');
      return context;
    }

    log('Route not authorized: ${context.fullPath}');
    if (redirectTo != null) {
      log('Redirecting to: $redirectTo');

      final app = GetIt.I<AppModule<AppConfig>>();

      app.goRouter.go(redirectTo!);
    }

    if (redirectTo == null) {
      log('No redirect specified, throwing RouteNotAuthorizedError');
    }
    throw RouteNotAuthorizedError(context);
  }

  @override
  String toString() => logTag;
}
