import 'package:flutter/widgets.dart';
import 'package:grumpy_flutter/grumpy_flutter.dart';
import 'package:logging/logging.dart';
import 'dart:async';

/// A widget that renders the current screen by listening to [RoutingService.onViewChanged].
class ScreenRenderer<AppConfig extends ResponsiveBreakpoints> extends StatefulWidget {
  /// Creates a ScreenRenderer.
  const ScreenRenderer({super.key, required this.uri});

  /// The URI to navigate to and render.
  final Uri uri;

  @override
  State<ScreenRenderer> createState() => _ScreenRendererState<AppConfig>();
}

class _ScreenRendererState<AppConfig extends ResponsiveBreakpoints>
    extends State<ScreenRenderer<AppConfig>>
    with LogMixin {
  final router = RoutingService<Widget, AppConfig>();
  StreamSubscription? _viewChangedSubscription;

  bool navigated = false;

  navigate() async {
    if (navigated) return;

    log('Navigating to: ${widget.uri}');

    try {
      await router.navigate(
        widget.uri.toString(),
        callback: (view, preview) => renderView(view, preview, widget.uri),
      );
    } catch (e, s) {
      log('Navigation to ${widget.uri} failed', e, s);
    } finally {
      navigated = true;
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
  }

  Widget? _currentView;

  @override
  void initState() {
    super.initState();
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
  void dispose() {
    _viewChangedSubscription?.cancel();
    super.dispose();
  }
}
