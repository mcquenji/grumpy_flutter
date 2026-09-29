import 'package:flutter/foundation.dart';
import 'package:grumpy/grumpy.dart';

/// Returns a metadata-only description of [value].
///
/// Collection and string values expose their type and size. Other values expose
/// only their runtime type, so diagnostics never invoke application `toString`
/// implementations or serialize payloads.
String grumpyDebugValueShape(Object? value) {
  if (value == null) return 'null';
  if (value is String) return 'String (${value.length} characters)';
  if (value is List) return '${value.runtimeType} (${value.length} items)';
  if (value is Set) return '${value.runtimeType} (${value.length} items)';
  if (value is Map) return '${value.runtimeType} (${value.length} entries)';
  return value.runtimeType.toString();
}

/// Adds metadata-only route-context properties to [properties].
///
/// Only segment counts, parameter names, and fragment presence are included.
/// Resolved path, query, and fragment values are deliberately omitted.
void debugFillRouteContextProperties(
  DiagnosticPropertiesBuilder properties,
  RouteContext route,
) {
  properties.add(IntProperty('path segments', route.uri.pathSegments.length));
  properties.add(
    IterableProperty<String>(
      'path parameter names',
      route.pathParams.keys.toList()..sort(),
      ifEmpty: 'none',
    ),
  );
  properties.add(
    IterableProperty<String>(
      'query parameter names',
      route.queryParamsAll.keys.toList()..sort(),
      ifEmpty: 'none',
    ),
  );
  properties.add(
    FlagProperty(
      'fragment',
      value: route.fragment.isNotEmpty,
      ifTrue: 'present',
      ifFalse: 'absent',
    ),
  );
}

/// Expandable Flutter diagnostics for a Grumpy dependency snapshot.
final class UseRepoSnapshotDiagnostics with Diagnosticable {
  /// Creates diagnostics for [snapshot].
  const UseRepoSnapshotDiagnostics(this.snapshot);

  /// The framework-neutral dependency snapshot being rendered.
  final UseRepoDebugSnapshot snapshot;

  @override
  String toStringShort() => 'dependency graph';

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<UseRepoDebugState>('state', snapshot.state));
    properties.add(
      EnumProperty<UseRepoDebugTriggerKind>(
        'latest trigger',
        snapshot.latestTrigger?.kind,
        defaultValue: null,
      ),
    );
    properties.add(
      DiagnosticsProperty<Type>(
        'trigger source type',
        snapshot.latestTrigger?.sourceType,
        defaultValue: null,
      ),
    );
    properties.add(IntProperty('subscriptions', snapshot.subscriptionCount));
    properties.add(IntProperty('generation', snapshot.stateChangeVersion));
    properties.add(IntProperty('active rebuilds', snapshot.activeRebuildCount));
    properties.add(IntProperty('total rebuilds', snapshot.totalRebuildCount));
    properties.add(
      IntProperty(
        'superseded rebuilds',
        snapshot.supersededRebuildCount,
        defaultValue: 0,
      ),
    );
    properties.add(
      IterableProperty<Type>(
        'pending repository types',
        snapshot.pendingRepoTypes,
        ifEmpty: 'none',
      ),
    );
    for (var i = 0; i < snapshot.dependencies.length; i++) {
      final dependency = snapshot.dependencies[i];
      properties.add(
        DiagnosticsProperty<UseRepoDependencyDiagnostics>(
          'dependency ${i + 1}',
          UseRepoDependencyDiagnostics(dependency),
          expandableValue: true,
        ),
      );
    }
  }
}

/// Expandable Flutter diagnostics for one Grumpy dependency.
final class UseRepoDependencyDiagnostics with Diagnosticable {
  /// Creates diagnostics for [dependency].
  const UseRepoDependencyDiagnostics(this.dependency);

  /// The dependency metadata being rendered.
  final UseRepoDependencyDebugInfo dependency;

  @override
  String toStringShort() => switch (dependency) {
    UseRepoRepoDependencyDebugInfo(:final repoType) => 'repo $repoType',
    UseRepoExternalDependencyDebugInfo(:final streamType) =>
      'external stream $streamType',
    UseRepoPayloadDependencyDebugInfo(:final sourceKeyType) =>
      'payload stream source $sourceKeyType',
  };

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      EnumProperty<UseRepoDependencyDebugState>('state', dependency.state),
    );
    properties.add(
      DiagnosticsProperty<Type>(
        'error type',
        dependency.errorType,
        defaultValue: null,
      ),
    );
    switch (dependency) {
      case UseRepoRepoDependencyDebugInfo(:final repoType):
        properties.add(DiagnosticsProperty<Type>('repository type', repoType));
      case UseRepoExternalDependencyDebugInfo(
        :final keyType,
        :final valueType,
        :final streamType,
      ):
        properties.add(DiagnosticsProperty<Type>('key type', keyType));
        properties.add(DiagnosticsProperty<Type>('value type', valueType));
        properties.add(DiagnosticsProperty<Type>('stream type', streamType));
      case UseRepoPayloadDependencyDebugInfo(
        :final keyType,
        :final sourceKeyType,
        :final payloadType,
        :final streamType,
      ):
        properties.add(DiagnosticsProperty<Type>('key type', keyType));
        properties.add(
          DiagnosticsProperty<Type>('source key type', sourceKeyType),
        );
        properties.add(DiagnosticsProperty<Type>('payload type', payloadType));
        properties.add(DiagnosticsProperty<Type>('stream type', streamType));
    }
  }
}

/// Expandable Flutter diagnostics for a Grumpy routing snapshot.
final class RoutingSnapshotDiagnostics with Diagnosticable {
  /// Creates diagnostics for [snapshot].
  const RoutingSnapshotDiagnostics(this.snapshot);

  /// The framework-neutral routing snapshot being rendered.
  final RoutingDebugSnapshot snapshot;

  @override
  String toStringShort() => 'routing ${snapshot.phase.name}';

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<RoutingDebugPhase>('phase', snapshot.phase));
    properties.add(
      StringProperty(
        'route pattern',
        snapshot.routePattern,
        defaultValue: null,
      ),
    );
    properties.add(IntProperty('path segments', snapshot.pathSegmentCount));
    properties.add(
      IterableProperty<String>(
        'path parameter names',
        snapshot.pathParameterNames,
        ifEmpty: 'none',
      ),
    );
    properties.add(
      IterableProperty<String>(
        'query parameter names',
        snapshot.queryParameterNames,
        ifEmpty: 'none',
      ),
    );
    properties.add(
      FlagProperty(
        'fragment',
        value: snapshot.hasFragment,
        ifTrue: 'present',
        ifFalse: 'absent',
      ),
    );
    properties.add(
      IntProperty('elapsed', snapshot.elapsed.inMicroseconds, unit: 'µs'),
    );
    properties.add(
      IntProperty(
        'coalesced callers',
        snapshot.coalescedNavigationCount,
        defaultValue: 0,
      ),
    );
    properties.add(
      DiagnosticsProperty<Type>(
        'failure type',
        snapshot.failureType,
        defaultValue: null,
      ),
    );
    properties.add(
      IterableProperty<Type>(
        'module types',
        snapshot.moduleTypes,
        ifEmpty: 'none',
      ),
    );
    for (var i = 0; i < snapshot.lineage.length; i++) {
      properties.add(
        DiagnosticsProperty<RouteSnapshotDiagnostics>(
          'route ${i + 1}',
          RouteSnapshotDiagnostics(snapshot.lineage[i]),
          expandableValue: true,
        ),
      );
    }
    for (var i = 0; i < snapshot.middleware.length; i++) {
      properties.add(
        DiagnosticsProperty<MiddlewareSnapshotDiagnostics>(
          'middleware ${i + 1}',
          MiddlewareSnapshotDiagnostics(snapshot.middleware[i]),
          expandableValue: true,
        ),
      );
    }
  }
}

/// Expandable Flutter diagnostics for one route-lineage entry.
final class RouteSnapshotDiagnostics with Diagnosticable {
  /// Creates diagnostics for [route].
  const RouteSnapshotDiagnostics(this.route);

  /// The route metadata being rendered.
  final RouteDebugInfo route;

  @override
  String toStringShort() => '${route.routeType} ${route.declaredPath}';

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Type>('route type', route.routeType));
    properties.add(
      StringProperty('declared path', route.declaredPath, quoted: false),
    );
    properties.add(
      DiagnosticsProperty<Type>(
        'module type',
        route.moduleType,
        defaultValue: null,
      ),
    );
    properties.add(
      DiagnosticsProperty<Type>(
        'leaf type',
        route.leafType,
        defaultValue: null,
      ),
    );
    properties.add(
      IterableProperty<Type>(
        'middleware types',
        route.middlewareTypes,
        ifEmpty: 'none',
      ),
    );
  }
}

/// Expandable Flutter diagnostics for one middleware execution entry.
final class MiddlewareSnapshotDiagnostics with Diagnosticable {
  /// Creates diagnostics for [middleware].
  const MiddlewareSnapshotDiagnostics(this.middleware);

  /// The middleware metadata being rendered.
  final RoutingMiddlewareDebugInfo middleware;

  @override
  String toStringShort() => middleware.middlewareType.toString();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<Type>('type', middleware.middlewareType),
    );
    properties.add(
      EnumProperty<RoutingDebugStepState>('state', middleware.state),
    );
  }
}
