import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:grumpy_annotations/grumpy_annotations.dart';
import 'package:grumpy_flutter/grumpy_flutter.dart';
import 'package:logging/logging.dart';

import '../diagnostics/grumpy_diagnostics.dart';

enum _QueryDebugOutcome { loading, data, error }

final class _QueryDebugTracker {
  final activeInvocations = <int, Stopwatch>{};
  var executionCount = 0;
  var latestInvocationId = 0;
  Duration? latestDuration;
  DateTime? latestCompletedAt;
  _QueryDebugOutcome latestOutcome = _QueryDebugOutcome.loading;
}

/// Provides a set of hooks for querying data within a [QueryComponent].
class QueryHooks extends UseHooks {
  /// Provides a set of hooks for querying data within a [QueryComponent].
  const QueryHooks({
    required super.repo,
    required super.externalStream,
    required super.payloadStream,
  });

  /// Creates a [QueryHooks] instance from a [UseHooks] instance by passing through the relevant functions.
  factory QueryHooks.fromUseHooks(UseHooks useRepo) {
    return QueryHooks(
      repo: useRepo.repo,
      externalStream: useRepo.externalStream,
      payloadStream: useRepo.payloadStream,
    );
  }

  /// A hook that allows you to watch a [TextEditingController] and get its current text value reactively.
  ///
  /// [QueryComponent.query] will be re-executed whenever the text in the controller changes, allowing you to build reactive queries based on user input.
  String text(TextEditingController controller) => externalStream(
    controller,
    changeSignal: controller.stream,
    syncSnapshot: () => controller.text,
  );

  /// A hook that allows you to watch any [ValueListenable] and get its current value reactively.
  ///
  /// [QueryComponent.query] will be re-executed whenever the value changes, allowing you to build reactive queries based on any listenable value.
  T value<T>(ValueListenable<T> listenable) => externalStream(
    listenable,
    changeSignal: listenable.stream,
    syncSnapshot: () => listenable.value,
  );
}

/// A base class for components that perform data queries.
///
/// A [QueryComponent] is a [StatefulComponent] that executes a query to fetch
/// data of type [T] and builds its UI based on the query's state (loading,
/// error, or data).
/// It leverages [QueryHooks] to access repositories reactively.
///
/// In debug builds the Widget Inspector reports query timing, counters, safe
/// result shape, error type, and an expandable dependency snapshot. Result
/// values, errors, messages, controller text, and stack frames are omitted.
abstract class QueryComponent<T> extends StatefulComponent with LogMixin {
  /// Creates a [QueryComponent] with an optional [key].
  const QueryComponent({super.key});

  @override
  String get debugComponentKind => 'query';

  /// Executes a query and returns the result of type [T].
  ///
  /// It is crucial that the implementation of this method uses the provided [use]
  /// hook instead of [Repo.get] to access repositories, or else the component will not
  /// be reactive to changes in the repositories' states.
  ///
  /// Example usage:
  ///
  /// ```dart
  /// Future<List<User>> query(QueryHooks use) async {
  ///   final (users, usersRepo) = await use.repo<List<User>, UsersRepo>();
  ///   return await usersRepo.fetchUsers();
  /// }
  /// ```
  Future<T> query(QueryHooks use);

  /// Builds the loader widget to display while the query is loading.
  Widget buildLoader(BuildContext context);

  /// Builds the error widget to display if the query fails.
  Widget buildError(BuildContext context, Object error, StackTrace? stackTrace);

  /// Builds the content widget to display when the query succeeds.
  Widget buildContent(BuildContext context, T data);

  @override
  @nonVirtual
  State<QueryComponent<T>> createState() => _QueryComponentState<T>();
  @override
  String get group => 'QueryComponent';

  @override
  Level get logLevel => Level.FINEST;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Type>('query result type', T));
    properties.add(StringProperty('log tag', logTag, quoted: false));
    properties.add(StringProperty('log group', group, quoted: false));
    properties.add(StringProperty('log level', logLevel.name, quoted: false));
  }
}

/// The successful value retained by a query component between rebuilds.
final class _QueryData<T> {
  /// Creates a successful query state for [data].
  const _QueryData(this.data);

  /// The latest value returned by [QueryComponent.query].
  final T data;
}

/// The failure retained by a query component between rebuilds.
final class _QueryError {
  /// Creates a failed query state with its optional [stackTrace].
  const _QueryError(this.error, this.stackTrace);

  /// The error thrown while resolving the query.
  final Object error;

  /// The stack trace associated with [error], when available.
  final StackTrace? stackTrace;
}

/// The loading state retained by a query component between rebuilds.
enum _QueryLoading {
  /// Indicates that the query is waiting for its dependencies or result.
  waiting,
}

class _QueryComponentState<T> extends State<QueryComponent<T>>
    with
        LifecycleMixin,
        LogMixin,
        LifecycleHooksMixin,
        UseRepoMixin<_QueryData<T>, _QueryError, _QueryLoading> {
  _QueryDebugTracker? _queryDebugTracker;

  bool _initializeQueryDebugTracker() {
    _queryDebugTracker = _QueryDebugTracker();
    return true;
  }

  int _startQueryDebugInvocation() {
    final tracker = _queryDebugTracker;
    if (tracker == null) return 0;
    final id = ++tracker.latestInvocationId;
    tracker.executionCount++;
    tracker.activeInvocations[id] = Stopwatch()..start();
    return id;
  }

  bool _finishQueryDebugInvocation(int id, _QueryDebugOutcome outcome) {
    final tracker = _queryDebugTracker;
    final stopwatch = tracker?.activeInvocations.remove(id);
    if (tracker == null || stopwatch == null) return true;
    stopwatch.stop();
    if (id == tracker.latestInvocationId) {
      tracker
        ..latestDuration = stopwatch.elapsed
        ..latestCompletedAt = DateTime.now()
        ..latestOutcome = outcome;
    }
    return true;
  }

  bool _setQueryDebugOutcome(_QueryDebugOutcome outcome) {
    final tracker = _queryDebugTracker;
    if (tracker != null) tracker.latestOutcome = outcome;
    return true;
  }

  @initializer
  @override
  void initState() {
    log('Initializing QueryComponent state');
    super.initState();

    assert(_initializeQueryDebugTracker());

    installUseRepoHooks();

    initialize();
  }

  @override
  void log(Object message, [Object? error, StackTrace? stackTrace]) {
    widget.log(message, error, stackTrace);
  }

  @override
  void logAtLevel(
    Level level,
    Object message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    // this is a pass-through to [QueryComponent].
    // ignore: invalid_use_of_internal_member
    widget.logAtLevel(level, message, error, stackTrace);
  }

  @override
  Widget build(BuildContext context) {
    return when(
      data: (data) {
        log('Rendering data state');
        return widget.buildContent(context, data.data);
      },
      error: (error) {
        log('Rendering error state');
        return widget.buildError(context, error.error, error.stackTrace);
      },
      loading: (loading) {
        log('Rendering loading state');
        return widget.buildLoader(context);
      },
    );
  }

  @override
  FutureOr<_QueryData<T>> onDependenciesReady(use) async {
    var invocationId = 0;
    assert(() {
      invocationId = _startQueryDebugInvocation();
      return true;
    }());
    try {
      final data = await widget.query(QueryHooks.fromUseHooks(use));
      assert(
        _finishQueryDebugInvocation(invocationId, _QueryDebugOutcome.data),
      );
      return _QueryData(data);
    } catch (_) {
      assert(
        _finishQueryDebugInvocation(invocationId, _QueryDebugOutcome.error),
      );
      rethrow;
    }
  }

  @override
  FutureOr<void> dependenciesChanged() {
    log('QueryComponent detected dependency change, rebuilding UI...');
    if (mounted) setState(() {});
  }

  @override
  FutureOr<_QueryError> onDependencyError(
    Object error,
    StackTrace? stackTrace,
  ) {
    assert(_setQueryDebugOutcome(_QueryDebugOutcome.error));
    return _QueryError(error, stackTrace);
  }

  @override
  _QueryLoading onDependenciesLoading() {
    assert(_setQueryDebugOutcome(_QueryDebugOutcome.loading));
    return _QueryLoading.waiting;
  }

  @override
  void reassemble() {
    super.reassemble();
    unawaited(refreshDependencies());
  }

  @override
  void dispose() {
    destroy();
    super.dispose();
  }

  @override
  String get logTag => '_QueryComponentState';

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);

    when(
      data: (data) {
        properties.add(
          EnumProperty<_QueryDebugOutcome>(
            'query state',
            _QueryDebugOutcome.data,
          ),
        );
        properties.add(
          StringProperty(
            'result shape',
            grumpyDebugValueShape(data.data),
            quoted: false,
          ),
        );
      },
      error: (error) {
        properties.add(
          EnumProperty<_QueryDebugOutcome>(
            'query state',
            _QueryDebugOutcome.error,
          ),
        );
        properties.add(
          DiagnosticsProperty<Type>('error type', error.error.runtimeType),
        );
        properties.add(
          FlagProperty(
            'stack trace',
            value: error.stackTrace != null,
            ifTrue: 'available',
            ifFalse: 'unavailable',
          ),
        );
      },
      loading: (_) {
        properties.add(
          EnumProperty<_QueryDebugOutcome>(
            'query state',
            _QueryDebugOutcome.loading,
          ),
        );
      },
    );

    final tracker = _queryDebugTracker;
    if (tracker != null) {
      properties.add(IntProperty('query executions', tracker.executionCount));
      properties.add(
        IntProperty('active queries', tracker.activeInvocations.length),
      );
      properties.add(
        EnumProperty<_QueryDebugOutcome>(
          'latest query outcome',
          tracker.latestOutcome,
        ),
      );
      properties.add(
        IntProperty(
          'latest query duration',
          tracker.latestDuration?.inMicroseconds,
          unit: 'µs',
          defaultValue: null,
        ),
      );
      properties.add(
        DiagnosticsProperty<DateTime>(
          'latest query completion',
          tracker.latestCompletedAt,
          defaultValue: null,
        ),
      );
    }

    final dependencySnapshot = useRepoDebugSnapshot;
    if (dependencySnapshot != null) {
      properties.add(
        DiagnosticsProperty<UseRepoSnapshotDiagnostics>(
          'dependencies',
          UseRepoSnapshotDiagnostics(dependencySnapshot),
          expandableValue: true,
        ),
      );
    }
  }
}
