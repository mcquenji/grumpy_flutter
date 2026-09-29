import 'package:flutter/foundation.dart';
import 'package:grumpy_flutter/grumpy_flutter.dart';
import 'package:flutter/widgets.dart';

/// The concrete [State] type used by [StatefulQueryErrorComponent].
typedef QueryComponentErrorState = State<StatefulQueryErrorComponent>;

/// Adds a stateful error builder to a [QueryComponent].
///
/// Instead of rendering the error directly, this mixin wraps the error UI in a
/// [StatefulQueryErrorComponent], allowing the error view to keep local state
/// (e.g. expanded details, retry animations) while still receiving the latest
/// [error] and [stackTrace].
///
/// Use this mixin and implement [createErrorState] (and optionally
/// [createErrorKey]) instead.
///
/// **Example**
///
/// ```dart
/// class UserQuery extends QueryComponent<User> with StatefulQueryError {
///   @override
///   QueryComponentErrorState createErrorState() => _ErrorState();
/// }
///
/// class _ErrorState extends State<StatefulQueryErrorComponent> {
///   var showDetails = false;
///
///   @override
///   Widget build(BuildContext context) {
///     final err = widget.error;
///     final st = widget.stackTrace;
///
///     return Column(
///       children: [
///         Text('Something went wrong: $err'),
///         GestureDetector(
///           onTap: () => setState(() => showDetails = !showDetails),
///           child: Text(showDetails ? 'hide details' : 'show details'),
///         ),
///         if (showDetails && st != null) Text(st.toString()),
///       ],
///     );
///   }
/// }
/// ```
///
/// **Keying by error**
///
/// If your error state should reset when the error changes, override
/// [createErrorKey]:
///
/// ```dart
/// class UserQuery extends QueryComponent<User> with StatefulQueryError {
///   @override
///   QueryComponentErrorState createErrorState() => _ErrorState();
///
///   @override
///   Key? createErrorKey(Object error, StackTrace? stackTrace) => ValueKey(error);
/// }
/// ```
///
/// **See also:**
/// - [StatefulQueryLoader] for stateful loading indicators.
/// - [StatefulQueryContent] for stateful content displays.
mixin StatefulQueryError on QueryComponent {
  @override
  Widget buildError(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return StatefulQueryErrorComponent(
      createErrorState,
      error: error,
      stackTrace: stackTrace,
      key: createErrorKey(error, stackTrace),
    );
  }

  /// Creates the [State] instance for the error component.
  ///
  /// This is called by Flutter when the error widget is mounted.
  QueryComponentErrorState createErrorState();

  /// Optionally provides a key for the error component.
  ///
  /// Override this to control when the error state is preserved vs. reset when
  /// [error] or [stackTrace] changes.
  Key? createErrorKey(Object error, StackTrace? stackTrace) => null;
}

/// A small [StatefulComponent] wrapper that forwards [error] and [stackTrace]
/// into a stateful error [State].
///
/// This type is an implementation detail of [StatefulQueryError].
/// You should not instantiate it directly.
class StatefulQueryErrorComponent extends StatefulComponent {
  /// Factory for creating the backing [State].
  final QueryComponentErrorState Function() _createState;

  /// The current error passed to the error view.
  final Object error;

  /// The current stack trace passed to the error view, if available.
  final StackTrace? stackTrace;

  /// Creates a stateful wrapper around query error UI.
  ///
  /// Prefer using [StatefulQueryError] instead of constructing this widget
  /// manually.
  const StatefulQueryErrorComponent(
    this._createState, {
    required this.error,
    this.stackTrace,
    super.key,
  });

  @override
  // This is just a forwarding method, ignore the lint.
  // ignore: no_logic_in_create_state
  QueryComponentErrorState createState() => _createState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      StringProperty('grumpy wrapper', 'stateful query error', quoted: false),
    );
    properties.add(DiagnosticsProperty<Type>('error type', error.runtimeType));
    properties.add(
      FlagProperty(
        'stack trace',
        value: stackTrace != null,
        ifTrue: 'available',
        ifFalse: 'unavailable',
      ),
    );
  }
}
