import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:grumpy_annotations/grumpy_annotations.dart';
import 'package:grumpy/grumpy.dart';

import '../diagnostics/grumpy_diagnostics.dart';

enum _ScreenViewPhase { preview, content }

final class _ScreenHost extends StatelessWidget {
  const _ScreenHost({
    required this.screen,
    required this.route,
    required this.phase,
  });

  final Screen screen;
  final RouteContext route;
  final _ScreenViewPhase phase;

  @override
  Widget build(BuildContext context) => switch (phase) {
    _ScreenViewPhase.preview => screen.buildPreview(context, route),
    _ScreenViewPhase.content => screen.buildContent(context, route),
  };

  @override
  String toStringShort() => '${screen.runtimeType} (${phase.name})';

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<Type>('screen type', screen.runtimeType),
    );
    properties.add(EnumProperty<_ScreenViewPhase>('screen phase', phase));
    debugFillRouteContextProperties(properties, route);
    screen.debugFillProperties(properties);
  }
}

/// A base class for all screens in the application.
///
/// A Screen is a leaf node in the module tree that represents a distinct
/// UI screen or page.
@BaseClass(
  allowedLayers: {.presentation},
  typeDirectory: 'screens',
  allowPrivateClasses: true,
)
abstract class Screen implements Leaf<Widget> {
  /// A base class for all screens in the application.
  ///
  /// A Screen is a leaf node in the module tree that represents a distinct
  /// UI screen or page.
  const Screen();

  /// Builds the main content of the screen.
  Widget buildContent(BuildContext context, RouteContext route);

  /// Builds a preview representation of the screen.
  Widget buildPreview(BuildContext context, RouteContext route);

  /// Adds metadata-only properties for Flutter diagnostics tools.
  ///
  /// Subclasses may override this to expose safe configuration metadata such
  /// as booleans, enums, and counts. Do not add user data, route values,
  /// credentials, controller text, errors, or stack traces. Always call the
  /// superclass implementation first.
  @protected
  @mustCallSuper
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {}

  @override
  @nonVirtual
  FutureOr<Widget> content(RouteContext context) {
    return _ScreenHost(
      screen: this,
      route: context,
      phase: _ScreenViewPhase.content,
    );
  }

  @override
  @nonVirtual
  Widget preview(RouteContext context) {
    return _ScreenHost(
      screen: this,
      route: context,
      phase: _ScreenViewPhase.preview,
    );
  }
}
