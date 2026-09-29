import 'package:flutter/foundation.dart';
import 'package:grumpy_flutter/grumpy_flutter.dart';
import 'package:flutter/widgets.dart';

/// The concrete [State] type used by [StatefulQueryLoaderComponent].
typedef QueryComponentLoaderState = State<StatefulQueryLoaderComponent>;

/// Adds a stateful loader builder to a [QueryComponent].
///
/// Instead of rendering the loader directly, this mixin wraps the loader UI in a
/// [StatefulQueryLoaderComponent], allowing the loader view to keep local state
/// (e.g. animation controllers, elapsed timers, playful messages) across rebuilds.
///
/// You should never instantiate [StatefulQueryLoaderComponent] directly.
/// Use this mixin and implement [createLoaderState] (and optionally
/// [createLoaderKey]) instead.
///
/// **Example**
///
/// ```dart
/// class UserQuery extends QueryComponent<User> with StatefulQueryLoader {
///   @override
///   QueryComponentLoaderState createLoaderState() => _LoaderState();
/// }
///
/// class _LoaderState extends State<StatefulQueryLoaderComponent> {
///   var dots = 0;
///
///   @override
///   void initState() {
///     super.initState();
///     // Example: a tiny local state tick.
///     Future.doWhile(() async {
///       await Future<void>.delayed(const Duration(milliseconds: 400));
///       if (!mounted) return false;
///       setState(() => dots = (dots + 1) % 4);
///       return true;
///     });
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Text('Loading${'.' * dots}');
///   }
/// }
/// ```
///
/// **Keying the loader**
///
/// If your loader state should reset based on external conditions (rare),
/// override [createLoaderKey]:
///
/// ```dart
/// class UserQuery extends QueryComponent<User> with StatefulQueryLoader {
///   @override
///   QueryComponentLoaderState createLoaderState() => _LoaderState();
///
///   @override
///   Key? createLoaderKey() => const ValueKey('user-loader');
/// }
/// ```
///
/// **See also:**
/// - [StatefulQueryContent] for stateful content displays.
/// - [StatefulQueryError] for stateful error displays.
mixin StatefulQueryLoader on QueryComponent {
  @override
  Widget buildLoader(BuildContext context) {
    return StatefulQueryLoaderComponent(
      createLoaderState,
      key: createLoaderKey(),
    );
  }

  /// Creates the [State] instance for the loader component.
  ///
  /// This is called by Flutter when the loader widget is mounted.
  QueryComponentLoaderState createLoaderState();

  /// Optionally provides a key for the loader component.
  ///
  /// Override this to control when the loader state is preserved vs. reset.
  Key? createLoaderKey() => null;
}

/// A small [StatefulComponent] wrapper used to build a stateful loader view.
///
/// This type is an implementation detail of [StatefulQueryLoader].
/// You should not instantiate it directly.
class StatefulQueryLoaderComponent extends StatefulComponent {
  /// Factory for creating the backing [State].
  final QueryComponentLoaderState Function() _createState;

  /// Creates a stateful wrapper around query loader UI.
  ///
  /// Prefer using [StatefulQueryLoader] instead of constructing this widget
  /// manually.
  const StatefulQueryLoaderComponent(this._createState, {super.key});

  @override
  // This is just a forwarding method, ignore the lint.
  // ignore: no_logic_in_create_state
  QueryComponentLoaderState createState() => _createState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      StringProperty('grumpy wrapper', 'stateful query loader', quoted: false),
    );
  }
}
