import 'package:flutter/foundation.dart';
import 'package:grumpy_flutter/grumpy_flutter.dart';
import 'package:flutter/widgets.dart';

import '../diagnostics/grumpy_diagnostics.dart';

/// The concrete [State] type used by [StatefulQueryContentComponent].
typedef QueryComponentContentState<T> = State<StatefulQueryContentComponent<T>>;

/// Adds a stateful content builder to a [QueryComponent].
///
/// Instead of rendering content directly, this mixin wraps the content in a
/// [StatefulQueryContentComponent], allowing the content to keep local state
/// while still receiving the latest query [data].
///
/// Use this mixin and implement [createContentState] (and optionally
/// [createContentKey]) instead.
///
/// **Example**
///
/// ```dart
/// class UserQuery extends QueryComponent<User> with StatefulQueryContent {
///   @override
///   QueryComponentContentState<User> createContentState() => _UserState();
/// }
///
/// class _UserState extends State<StatefulQueryContentComponent<User>> {
///   var expanded = false;
///
///   @override
///   Widget build(BuildContext context) {
///     final user = widget.data;
///     return Column(
///       children: [
///         Text(user.name),
///         if (expanded) Text(user.email),
///         GestureDetector(
///           onTap: () => setState(() => expanded = !expanded),
///           child: Text(expanded ? 'less' : 'more'),
///         ),
///       ],
///     );
///   }
/// }
/// ```
///
/// **Keying by data**
///
/// If your state should reset when some identity changes, override
/// [createContentKey] to control state preservation:
///
/// ```dart
/// class UserQuery extends QueryComponent<User> with StatefulQueryContent {
///   @override
///   QueryComponentContentState<User> createContentState() => _UserState();
///
///   @override
///   Key? createContentKey(User data) => ValueKey(data.id);
/// }
/// ```
///
/// **See also:**
/// - [StatefulQueryLoader] for stateful loading indicators.
/// - [StatefulQueryError] for stateful error displays.
mixin StatefulQueryContent<T> on QueryComponent<T> {
  @override
  Widget buildContent(BuildContext context, T data) {
    return StatefulQueryContentComponent<T>(
      createContentState,
      data: data,
      key: createContentKey(data),
    );
  }

  /// Creates the [State] instance for the content component.
  ///
  /// This is called by Flutter when the content widget is mounted.
  QueryComponentContentState<T> createContentState();

  /// Optionally provides a key for the content component.
  ///
  /// Override this to control when the content state is preserved vs. reset
  /// when [data] changes.
  Key? createContentKey(T data) => null;
}

/// A small [StatefulComponent] wrapper that forwards [data] into a stateful
/// content [State].
///
/// This type is an implementation detail of [StatefulQueryContent].
/// You should not instantiate it directly.
class StatefulQueryContentComponent<T> extends StatefulComponent {
  /// Factory for creating the backing [State].
  final QueryComponentContentState<T> Function() _createState;

  /// The latest query result passed to the content.
  final T data;

  /// Creates a stateful wrapper around query content.
  ///
  /// Prefer using [StatefulQueryContent] instead of constructing this widget
  /// manually.
  const StatefulQueryContentComponent(
    this._createState, {
    required this.data,
    super.key,
  });

  @override
  // This is just a forwarding method, ignore the lint.
  // ignore: no_logic_in_create_state
  QueryComponentContentState<T> createState() => _createState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      StringProperty('grumpy wrapper', 'stateful query content', quoted: false),
    );
    properties.add(DiagnosticsProperty<Type>('data type', T));
    properties.add(
      StringProperty('data shape', grumpyDebugValueShape(data), quoted: false),
    );
  }
}
