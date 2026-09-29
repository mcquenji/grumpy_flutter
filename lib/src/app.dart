import 'package:flutter/widgets.dart' hide Route;
import 'package:go_router/go_router.dart';
import 'package:grumpy/grumpy.dart' as grumpy;
import 'package:grumpy_flutter/grumpy_flutter.dart';

export 'domain/domain.dart';
export 'utils/utils.dart';
export 'presentation/presentation.dart';
export 'package:grumpy/grumpy.dart'
    hide RootModule, LeafRoute, Leaf, ModuleRoute;

/// A type alias for a raw module that can be used in the [imports] of an [AppModule].
///
/// This is just a convenience to avoid having to import the full `grumpy` package when defining imports.
typedef ModuleImport<AppConfig extends ResponsiveBreakpoints> =
    grumpy.Module<Widget, AppConfig>;

/// The root module of a Flutter application.
abstract class AppModule<AppConfig extends ResponsiveBreakpoints>
    extends grumpy.RootModule<Widget, AppConfig> {
  /// The root module of a Flutter application.
  AppModule(super.cfg);

  GoRouter? _goRouter;

  /// The screen to display for unknown routes (404).
  ///
  /// Should not depend on any modules or repositories other than the root module, as it may be displayed when the user navigates to an unknown route and the app is not fully initialized.
  ///
  /// If [goRouter] does not find a matching route [Screen.buildContent] will be called on the returned screen to display the 404 page.
  Screen get notFoundScreen;

  /// The initial location to navigate to on app start.
  String get initialLocation => '/';

  /// The path for the not found (404) screen.
  static const String notFoundPath = '/404';

  @override
  @mustCallSuper
  void bindExternalDeps(grumpy.Bind<Object, AppConfig> bind) {
    bind<AppModule<AppConfig>>((_, _) => this);
  }

  @override
  List<FlutterRoute<AppConfig>> get routes => [];

  @override
  List<ModuleImport<AppConfig>> get imports => [];

  @override
  // we want to redefine root here to add the 404 route
  // ignore: invalid_use_of_internal_member
  Route<Widget, AppConfig> get root => Route.root([
    ScreenRoute(path: notFoundPath, view: notFoundScreen),
    ...routes,
  ]);

  /// The GoRouter instance for the application.
  GoRouter get goRouter {
    return _goRouter ??= GoRouter(
      debugLogDiagnostics: true,
      initialLocation: initialLocation,
      routes: _createGoRoutes(),
      errorBuilder: (context, state) =>
          notFoundScreen.buildContent(context, RouteContext.fromUri(state.uri)),
    );
  }

  List<RouteBase> _createGoRoutes() {
    final root = this.root;

    final routes = <RouteBase>[];

    for (final child in root.children) {
      if (child is! FlutterRoute<AppConfig>) {
        throw StateError('All routes in AppModule must be FlutterRoutes');
      }

      routes.add(child.goRoute);
    }

    return routes;
  }

  /// Builds the root widget of the application.
  ///
  /// Use this to wrap the [goRouter] in a [MaterialApp] or similar.
  ///
  /// Example:
  /// ```dart
  /// Widget buildApp() {
  ///   return MaterialApp.router(routerConfig: goRouter);
  /// }
  /// ```
  Widget buildApp();
  @override
  String get group => '${super.group}.AppModule';

  @override
  String toString() => '$logTag<$AppConfig>';

  /// Retrieves the module configuration from the dependency injector.
  static T getConfig<T extends Object>() => grumpy.RootModule.getConfig<T>();

  /// Bootstraps the app and wraps [buildApp] in [ResponsiveAppScope].
  Future<void> run() async {
    await bootstrap();
    runApp(ResponsiveAppScope(config: cfg, child: buildApp()));
  }
}

/// A modular unit of functionality within an application
/// encapsulating routes and dependencies.
///
/// Use this to define your App's features.
abstract class Module<AppConfig extends ResponsiveBreakpoints>
    extends grumpy.Module<Widget, AppConfig> {
  @override
  List<FlutterRoute<AppConfig>> get routes => [];

  @override
  List<ModuleImport<AppConfig>> get imports => [];
  @override
  String get group => '${super.group}.Module';

  @override
  String toString() => '$logTag<$AppConfig>';
}
