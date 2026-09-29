import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:grumpy/grumpy.dart';

import '../components/stateful_component.dart';
import '../diagnostics/grumpy_diagnostics.dart';
import 'screen.dart';

/// The concrete [State] type used by [StatefulScreenPreviewComponent].
typedef ScreenPreviewState = State<StatefulScreenPreviewComponent>;

/// Adds a stateful preview to a [Screen].
///
/// Use this mixin when a screen preview needs to own controllers, animations,
/// or other resources whose lifecycle should be managed by Flutter. Implement
/// [createPreviewState] instead of [Screen.buildPreview]. The current
/// [RouteContext] is available to the state through `widget.route`.
///
/// Preview state is independent from state created by `StatefulScreenContent`.
/// By default, it is preserved when the route context changes. Override
/// [createPreviewKey] when a route change should create a fresh state.
///
/// **Example**
///
/// ```dart
/// class ReportScreen extends Screen with StatefulScreenPreview {
///   @override
///   Widget buildContent(BuildContext context, RouteContext route) {
///     return const Text('Report');
///   }
///
///   @override
///   ScreenPreviewState createPreviewState() => _ReportPreviewState();
/// }
///
/// class _ReportPreviewState extends ScreenPreviewState {
///   @override
///   Widget build(BuildContext context) {
///     return Text('Loading ${widget.route.fullPath}');
///   }
/// }
/// ```
///
/// See also:
///
/// - `StatefulScreenContent`, for stateful final content.
mixin StatefulScreenPreview on Screen {
  @override
  Widget buildPreview(BuildContext context, RouteContext route) {
    return StatefulScreenPreviewComponent(
      createPreviewState,
      route: route,
      key: createPreviewKey(route),
    );
  }

  /// Creates the [State] that renders the screen preview.
  ///
  /// Flutter calls this when the preview wrapper is first mounted or when its
  /// identity changes.
  ScreenPreviewState createPreviewState();

  /// Provides the key used to preserve or replace the preview state.
  ///
  /// The default `null` key preserves the state while the wrapper remains at
  /// the same location in the widget tree. Return a route-derived key when a
  /// route change should reset the preview state.
  Key? createPreviewKey(RouteContext route) => null;
}

/// Forwards screen preview data into a state created by
/// [StatefulScreenPreview].
///
/// Prefer applying [StatefulScreenPreview] to a [Screen] instead of
/// constructing this component directly.
class StatefulScreenPreviewComponent extends StatefulComponent {
  /// Creates a wrapper for a stateful screen preview.
  const StatefulScreenPreviewComponent(
    this._createState, {
    required this.route,
    super.key,
  });

  /// The latest route context supplied by the screen renderer.
  final RouteContext route;

  final ScreenPreviewState Function() _createState;

  @override
  // This method only forwards to the state factory supplied by the screen.
  // ignore: no_logic_in_create_state
  ScreenPreviewState createState() => _createState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      StringProperty(
        'grumpy wrapper',
        'stateful screen preview',
        quoted: false,
      ),
    );
    debugFillRouteContextProperties(properties, route);
  }
}
