import 'package:flutter/widgets.dart' hide Route;
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:grumpy_flutter/grumpy_flutter.dart';
import 'package:grumpy/grumpy.dart' as grumpy;
import 'package:logging/logging.dart';

/// Represents a Flutter-specific [Route] in the application.
///
/// Provides integration with the `go_router` package for navigation.
abstract class FlutterRoute<AppConfig extends ResponsiveBreakpoints>
    extends grumpy.Route<Widget, AppConfig>
    with LogMixin {
  /// Represents a Flutter-specific [Route] in the application.
  ///
  /// Provides integration with the `go_router` package for navigation.
  const FlutterRoute({required super.path});

  /// Converts this route into a GoRouter [RouteBase].
  RouteBase get goRoute;

  @override
  String get group => 'FlutterRoute';

  @override
  Level get logLevel => Level.FINEST;
}

/// A route that displays a [Screen] in the application.
class ScreenRoute<AppConfig extends ResponsiveBreakpoints>
    extends grumpy.LeafRoute<Widget, AppConfig>
    with LogMixin
    implements FlutterRoute<AppConfig> {
  @override
  Screen get view => super.view as Screen;

  @override
  List<FlutterRoute<AppConfig>> get children =>
      super.children.cast<FlutterRoute<AppConfig>>();

  /// A route that displays a [Screen] in the application.
  ScreenRoute({
    required super.path,
    required super.view,
    super.middleware,
    super.children = const [],
  }) : assert(view is Screen, 'view must be a Screen'),
       assert(
         children.isEmpty || children is List<FlutterRoute<AppConfig>>,
         'children must be FlutterRoutes',
       );

  @override
  RouteBase get goRoute => GoRoute(
    path: path,
    builder: _createBuilder<AppConfig>(path, log),
    routes: children.map((child) => child.goRoute).toList(),
  );

  /// A root screen route.
  ///
  /// Used for defining the root of a module in a [ModuleRoute].
  ScreenRoute.root({required super.view, super.middleware, super.children})
    : assert(view is Screen, 'view must be a Screen'),
      assert(
        children.isEmpty || children is List<FlutterRoute<AppConfig>>,
        'children must be FlutterRoutes',
      ),
      super(path: '/');

  @override
  String get logTag => 'ScreenRoute';
}

/// A route that renders a shell around its child routes.
class ShellScreenRoute<AppConfig extends ResponsiveBreakpoints>
    extends Route<Widget, AppConfig>
    with LogMixin
    implements FlutterRoute<AppConfig> {
  /// Builds the shell widget.
  final ShellRouteBuilder shellBuilder;

  @override
  List<FlutterRoute<AppConfig>> get children =>
      super.children.cast<FlutterRoute<AppConfig>>();

  /// A route that renders a shell around its child routes.
  const ShellScreenRoute({
    required this.shellBuilder,
    super.middleware,
    super.children,
  }) : super(path: '');

  @override
  RouteBase get goRoute => ShellRoute(
    builder: shellBuilder,
    routes: children.map((child) => child.goRoute).toList(),
  );

  @override
  String get logTag => 'ShellScreenRoute';

  @override
  String treeLabel() {
    final info = treeInfo;
    final suffix = info.isEmpty ? '' : '[${info.join(', ')}]';

    return 'Shell $suffix';
  }

  @override
  List<String> get treeInfo => [...super.treeInfo];
}

/// A route that activates a [Module] when matched.
///
/// Use [ModuleRoute] for feature- or domain-level entry points that should
/// mount a dedicated [Module] (and its dependency graph) on navigation.
class ModuleRoute<AppConfig extends ResponsiveBreakpoints>
    extends grumpy.ModuleRoute<Widget, AppConfig>
    with LogMixin
    implements FlutterRoute<AppConfig> {
  @override
  List<FlutterRoute<AppConfig>> get children =>
      super.children.cast<FlutterRoute<AppConfig>>();

  @override
  grumpy.LeafRoute<Widget, AppConfig>? get root =>
      super.root ??
      module.routes.root ??
      ScreenRoute.root(view: GetIt.I<AppModule<AppConfig>>().notFoundScreen);

  @override
  Module<AppConfig> get module => super.module as Module<AppConfig>;

  /// A route that activates a [Module] when matched.
  ///
  /// Use [ModuleRoute] for feature- or domain-level entry points that should
  /// mount a dedicated [Module] (and its dependency graph) on navigation.
  ModuleRoute({
    required super.path,
    required super.module,
    super.middleware,
    super.root,
  }) : assert(
         root == null || root is ScreenRoute<AppConfig>,
         'root must be a ScreenRoute',
       ),
       assert(
         module is Module<AppConfig>,
         'module must be a Module<AppConfig>',
       );

  @override
  RouteBase get goRoute {
    // filter out root route from children since it will be added as the builder of the GoRoute
    final routes = module.routes.where((route) => route.path != '/');

    return GoRoute(
      path: path,

      builder: _createBuilder<AppConfig>(path, log),

      routes: routes.map((child) => child.goRoute).toList(),
    );
  }

  @override
  String get logTag => 'ModuleRoute';
}

GoRouterWidgetBuilder _createBuilder<AppConfig extends ResponsiveBreakpoints>(
  String path,
  void Function(String) log,
) => (BuildContext context, GoRouterState state) {
  return ScreenRenderer<AppConfig>(uri: state.uri, key: ValueKey(state.uri));
};
