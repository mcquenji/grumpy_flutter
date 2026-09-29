import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:grumpy_flutter/grumpy_flutter.dart';
import 'package:logging/logging.dart';

import '../diagnostics/grumpy_diagnostics.dart';

enum _ScreenNavigationDebugState {
  idle,
  navigating,
  preview,
  content,
  completed,
  rejected,
  failed,
}

final class _ScreenNavigationDebugTracker {
  final stopwatch = Stopwatch();
  var state = _ScreenNavigationDebugState.idle;
  Type? renderedViewType;
  Type? failureType;
  var previewRendered = false;
  var contentRendered = false;
  Duration? duration;
  DateTime? completedAt;
  RoutingDebugSnapshot? routingSnapshot;
}

/// A widget that renders the current screen by listening to
/// [RoutingService.onViewChanged].
///
/// Debug builds expose metadata-only navigation timing, rendered-view type,
/// failure type, and routing lineage to the Widget Inspector. URI and parameter
/// values, errors, and stack traces are never retained for diagnostics.
class ScreenRenderer<AppConfig extends ResponsiveBreakpoints> extends StatefulWidget {
  /// Creates a ScreenRenderer.
  const ScreenRenderer({super.key, required this.uri});

  /// The URI to navigate to and render.
  final Uri uri;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Type>('app config type', AppConfig));
    properties.add(IntProperty('path segments', uri.pathSegments.length));
    properties.add(
      IterableProperty<String>(
        'query parameter names',
        uri.queryParametersAll.keys.toList()..sort(),
        ifEmpty: 'none',
      ),
    );
    properties.add(
      FlagProperty(
        'fragment',
        value: uri.fragment.isNotEmpty,
        ifTrue: 'present',
        ifFalse: 'absent',
      ),
    );
  }

  @override
  State<ScreenRenderer> createState() => _ScreenRendererState<AppConfig>();
}

class _ScreenRendererState<AppConfig extends ResponsiveBreakpoints>
    extends State<ScreenRenderer<AppConfig>>
    with LogMixin {
  final router = RoutingService<Widget, AppConfig>();
  StreamSubscription? _viewChangedSubscription;

  bool navigated = false;

  _ScreenNavigationDebugTracker? _navigationDebugTracker;

  bool _initializeNavigationDebug() {
    _navigationDebugTracker = _ScreenNavigationDebugTracker();
    return true;
  }

  bool _startNavigationDebug() {
    final tracker = _navigationDebugTracker;
    if (tracker != null) {
      tracker
        ..state = _ScreenNavigationDebugState.navigating
        ..failureType = null
        ..previewRendered = false
        ..contentRendered = false
        ..duration = null
        ..completedAt = null
        ..routingSnapshot = null;
      tracker.stopwatch
        ..reset()
        ..start();
    }
    return true;
  }

  RoutingDebugSnapshot? _currentRoutingDebugSnapshot() {
    final routing = router;
    if (routing is! RoutingDebugInfoProvider) return null;
    return (routing as RoutingDebugInfoProvider).debugSnapshotFor(widget.uri);
  }

  bool _recordRenderedViewDebug(Widget view, bool isPreview) {
    final tracker = _navigationDebugTracker;
    if (tracker != null) {
      tracker
        ..state = isPreview
            ? _ScreenNavigationDebugState.preview
            : _ScreenNavigationDebugState.content
        ..renderedViewType = view.runtimeType
        ..routingSnapshot = _currentRoutingDebugSnapshot();
      if (isPreview) {
        tracker.previewRendered = true;
      } else {
        tracker.contentRendered = true;
      }
    }
    return true;
  }

  bool _finishNavigationDebug() {
    final tracker = _navigationDebugTracker;
    if (tracker == null) return true;
    final routingSnapshot = _currentRoutingDebugSnapshot();
    tracker.stopwatch.stop();
    tracker
      ..routingSnapshot = routingSnapshot ?? tracker.routingSnapshot
      ..duration = tracker.stopwatch.elapsed
      ..completedAt = DateTime.now();
    if (routingSnapshot?.phase == RoutingDebugPhase.rejected) {
      tracker
        ..state = _ScreenNavigationDebugState.rejected
        ..failureType = routingSnapshot?.failureType;
    } else if (tracker.state != _ScreenNavigationDebugState.failed) {
      tracker.state = _ScreenNavigationDebugState.completed;
    }
    return true;
  }

  bool _failNavigationDebug(Type failureType) {
    final tracker = _navigationDebugTracker;
    if (tracker != null) {
      tracker
        ..state = _ScreenNavigationDebugState.failed
        ..failureType = failureType
        ..routingSnapshot = _currentRoutingDebugSnapshot();
    }
    return true;
  }

  Future<void> navigate() async {
    if (navigated) return;

    assert(_startNavigationDebug());

    log('Navigating to: ${widget.uri}');

    try {
      await router.navigate(
        widget.uri.toString(),
        callback: (view, preview) => renderView(view, preview, widget.uri),
      );
    } catch (e, s) {
      assert(_failNavigationDebug(e.runtimeType));
      log('Navigation to ${widget.uri} failed', e, s);
    } finally {
      navigated = true;
      assert(_finishNavigationDebug());
    }

    // _viewChangedSubscription = router.onViewChanged((event) {
    //   if (event.context?.uri != widget.uri) {
    //     log(
    //       'Received a view for a different URI. This means the user has navigated to a different screen and this ScreenRenderer is yet to be disposed. Rendering the view for the new URI instead for faster navigation and to avoid showing a blank screen while the old view is being disposed.',
    //     );
    //   }
    //   renderView(event.view, event.isPreview, event.context?.uri);
    // });
  }

  void renderView(Widget view, bool isPreview, Uri? route) {
    if (!mounted) {
      log('ScreenRenderer is not mounted, cannot render view.');
      return;
    }

    log('Rendering ${isPreview ? 'preview' : 'final'} view for URI: $route');

    setState(() {
      _currentView = view;
    });
    assert(_recordRenderedViewDebug(view, isPreview));
  }

  Widget? _currentView;

  @override
  void initState() {
    super.initState();
    assert(_initializeNavigationDebug());
    navigate();
  }

  @override
  Level get logLevel => Level.FINEST;

  @override
  String get group => 'ScreenRenderer';

  @override
  Widget build(BuildContext context) {
    if (_currentView == null) {
      log('No view to render yet for URI: ${widget.uri}. Showing placeholder.');
    }

    return _currentView ?? const SizedBox.shrink();
  }

  @override
  String get logTag => '_ScreenRendererState';

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    final tracker = _navigationDebugTracker;
    if (tracker == null) return;

    properties.add(
      EnumProperty<_ScreenNavigationDebugState>(
        'navigation state',
        tracker.state,
      ),
    );
    properties.add(
      DiagnosticsProperty<Type>(
        'rendered view type',
        tracker.renderedViewType,
        defaultValue: null,
      ),
    );
    properties.add(
      DiagnosticsProperty<Type>(
        'failure type',
        tracker.failureType,
        defaultValue: null,
      ),
    );
    properties.add(
      FlagProperty(
        'preview rendered',
        value: tracker.previewRendered,
        ifTrue: 'yes',
        ifFalse: 'no',
      ),
    );
    properties.add(
      FlagProperty(
        'final content rendered',
        value: tracker.contentRendered,
        ifTrue: 'yes',
        ifFalse: 'no',
      ),
    );
    properties.add(
      IntProperty(
        'navigation duration',
        tracker.duration?.inMicroseconds,
        unit: 'µs',
        defaultValue: null,
      ),
    );
    properties.add(
      DiagnosticsProperty<DateTime>(
        'navigation completion',
        tracker.completedAt,
        defaultValue: null,
      ),
    );
    final routingSnapshot = tracker.routingSnapshot;
    if (routingSnapshot != null) {
      properties.add(
        DiagnosticsProperty<RoutingSnapshotDiagnostics>(
          'routing',
          RoutingSnapshotDiagnostics(routingSnapshot),
          expandableValue: true,
        ),
      );
    }
  }

  @override
  void dispose() {
    _viewChangedSubscription?.cancel();
    super.dispose();
  }
}
