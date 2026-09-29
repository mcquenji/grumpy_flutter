import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:grumpy/grumpy.dart';

import '../components/stateful_component.dart';
import '../diagnostics/grumpy_diagnostics.dart';
import 'screen.dart';

/// The concrete [State] type used by [StatefulScreenContentComponent].
typedef ScreenContentState = State<StatefulScreenContentComponent>;

/// Adds stateful content to a [Screen].
///
/// Use this mixin when a screen's final content needs to own controllers or
/// other resources whose lifecycle should be managed by Flutter. Implement
/// [createContentState] instead of [Screen.buildContent]. The current
/// [RouteContext] is available to the state through
/// `widget.route`.
///
/// By default, the state is preserved when the route context changes. Override
/// [createContentKey] when a route change should create a fresh state.
///
/// **Example**
///
/// ```dart
/// class EditorScreen extends Screen with StatefulScreenContent {
///   @override
///   ScreenContentState createContentState() => _EditorScreenState();
///
///   @override
///   Widget buildPreview(BuildContext context, RouteContext route) {
///     return const Text('Loading editor');
///   }
/// }
///
/// class _EditorScreenState extends ScreenContentState {
///   late final TextEditingController controller;
///
///   @override
///   void initState() {
///     super.initState();
///     controller = TextEditingController();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return TextField(controller: controller);
///   }
///
///   @override
///   void dispose() {
///     controller.dispose();
///     super.dispose();
///   }
/// }
/// ```
///
/// See also:
///
/// - `StatefulScreenPreview`, for stateful preview content.
mixin StatefulScreenContent on Screen {
  @override
  Widget buildContent(BuildContext context, RouteContext route) {
    return StatefulScreenContentComponent(
      createContentState,
      route: route,
      key: createContentKey(route),
    );
  }

  /// Creates the [State] that renders the screen content.
  ///
  /// Flutter calls this when the content wrapper is first mounted or when its
  /// identity changes.
  ScreenContentState createContentState();

  /// Provides the key used to preserve or replace the content state.
  ///
  /// The default `null` key preserves the state while the wrapper remains at
  /// the same location in the widget tree. Return a route-derived key when a
  /// route change should reset the content state.
  Key? createContentKey(RouteContext route) => null;
}

/// Forwards screen content data into a state created by
/// [StatefulScreenContent].
///
/// Prefer applying [StatefulScreenContent] to a [Screen] instead of
/// constructing this component directly.
class StatefulScreenContentComponent extends StatefulComponent {
  /// Creates a wrapper for stateful screen content.
  const StatefulScreenContentComponent(
    this._createState, {
    required this.route,
    super.key,
  });

  /// The latest route context supplied by the screen renderer.
  final RouteContext route;

  final ScreenContentState Function() _createState;

  @override
  // This method only forwards to the state factory supplied by the screen.
  // ignore: no_logic_in_create_state
  ScreenContentState createState() => _createState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      StringProperty(
        'grumpy wrapper',
        'stateful screen content',
        quoted: false,
      ),
    );
    debugFillRouteContextProperties(properties, route);
  }
}
