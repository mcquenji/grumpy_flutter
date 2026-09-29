import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'modules.dart';
import 'package:grumpy_flutter/grumpy_flutter.dart';

void main() {
  setUp(() {
    _CounterState.initializations = 0;
    _CounterState.disposals = 0;
  });

  Future<void> pump(
    WidgetTester tester, {
    double width = 800,
    Widget child = const _View(),
    ResponsiveBreakpoints config = const _Config(),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ResponsiveAppScope(
        config: config,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: width, child: child),
          ),
        ),
      ),
    );
  }

  testWidgets('AppModule.run installs app config automatically', (
    tester,
  ) async {
    final app = _App();
    addTearDown(() => GetIt.I.reset(dispose: false));
    await app.run();
    await tester.pumpAndSettle();
    expect(find.byType(ResponsiveAppScope), findsOneWidget);
    expect(find.text('tablet'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('adapters honor explicit tablet builders and null stack traces', (
    tester,
  ) async {
    final query = _TabletQuery(Completer<String>(), []);
    final screen = _TabletScreen();
    final route = RouteContext.fromUri(Uri.parse('/tablet'));
    final error = StateError('test');
    final builders = <(WidgetBuilder, String)>[
      (query.buildLoader, 'loader-tablet'),
      (
        (context) => query.buildContent(context, 'payload'),
        'content-tablet:payload',
      ),
      ((context) => query.buildError(context, error, null), 'error-tablet'),
      ((context) => screen.buildContent(context, route), 'content-tablet'),
      ((context) => screen.buildPreview(context, route), 'preview-tablet'),
    ];
    for (final (builder, label) in builders) {
      await pump(tester, child: Builder(builder: builder));
      expect(find.text(label), findsOneWidget);
    }
    expect(query.tracker.lastError, same(error));
    expect(query.tracker.lastStackTrace, isNull);
    expect(screen.lastRoute, same(route));
  });

  testWidgets('selects exact boundaries and invokes only the active builder', (
    tester,
  ) async {
    final calls = <String>[];
    final view = _TabletView(calls: calls);
    for (final (width, expected) in [
      (599.0, 'mobile'),
      (600.0, 'tablet'),
      (1023.0, 'tablet'),
      (1024.0, 'desktop'),
      (300.0, 'mobile'),
    ]) {
      calls.clear();
      await pump(tester, width: width, child: view);
      expect(find.text(expected), findsOneWidget);
      expect(calls, [expected]);
    }
  });

  testWidgets('tablet falls back to mobile despite a desktop window', (
    tester,
  ) async {
    await pump(tester, width: 800);
    expect(find.text('mobile'), findsOneWidget);
    await pump(tester, width: 1024);
    expect(find.text('desktop'), findsOneWidget);
  });

  testWidgets(
    'merges each threshold through component, nested scopes, and app',
    (tester) async {
      const child = ResponsiveScope(
        overrides: ResponsiveBreakpointOverrides(tabletMinWidth: 400),
        child: ResponsiveScope(
          overrides: ResponsiveBreakpointOverrides(desktopMinWidth: 900),
          child: _TabletView(
            overrides: ResponsiveBreakpointOverrides(desktopMinWidth: 1100),
          ),
        ),
      );
      await pump(tester, width: 450, child: child);
      expect(find.text('tablet'), findsOneWidget);
      await pump(tester, width: 1000, child: child);
      expect(find.text('tablet'), findsOneWidget);
      await pump(tester, width: 1100, child: child);
      expect(find.text('desktop'), findsOneWidget);

      await pump(
        tester,
        width: 850,
        config: const _Config(desktopMinWidth: 800),
        child: const ResponsiveScope(
          overrides: ResponsiveBreakpointOverrides(tabletMinWidth: 300),
          child: _TabletView(),
        ),
      );
      expect(find.text('desktop'), findsOneWidget);
    },
  );

  testWidgets('reacts to app and outer scope changes with an unchanged child', (
    tester,
  ) async {
    const view = _TabletView();
    await pump(tester, width: 800, child: view);
    expect(find.text('tablet'), findsOneWidget);
    await pump(
      tester,
      width: 800,
      child: view,
      config: const _Config(desktopMinWidth: 750),
    );
    expect(find.text('desktop'), findsOneWidget);

    Widget scoped(double tablet) => ResponsiveScope(
      overrides: ResponsiveBreakpointOverrides(tabletMinWidth: tablet),
      child: const ResponsiveScope(
        overrides: ResponsiveBreakpointOverrides(desktopMinWidth: 1200),
        child: view,
      ),
    );
    await pump(tester, width: 800, child: scoped(700));
    expect(find.text('tablet'), findsOneWidget);
    await pump(tester, width: 800, child: scoped(900));
    expect(find.text('mobile'), findsOneWidget);
  });

  testWidgets(
    'nearest supplied threshold wins and removing it inherits again',
    (tester) async {
      Widget scoped(double? tablet) => ResponsiveScope(
        overrides: const ResponsiveBreakpointOverrides(tabletMinWidth: 400),
        child: ResponsiveScope(
          overrides: ResponsiveBreakpointOverrides(tabletMinWidth: tablet),
          child: const _TabletView(),
        ),
      );
      await pump(tester, width: 500, child: scoped(700));
      expect(find.text('mobile'), findsOneWidget);
      await pump(tester, width: 500, child: scoped(null));
      expect(find.text('tablet'), findsOneWidget);
    },
  );

  testWidgets('nested app scope starts a fresh override chain', (tester) async {
    await pump(
      tester,
      width: 800,
      child: const ResponsiveScope(
        overrides: ResponsiveBreakpointOverrides(tabletMinWidth: 900),
        child: ResponsiveAppScope(config: _Config(), child: _TabletView()),
      ),
    );
    expect(find.text('tablet'), findsOneWidget);
  });

  testWidgets('uses MediaQuery for unbounded width and tracks size changes', (
    tester,
  ) async {
    Widget unbounded(double width) => MediaQuery(
      data: MediaQueryData(size: Size(width, 900)),
      child: const UnconstrainedBox(
        constrainedAxis: Axis.vertical,
        child: _TabletView(),
      ),
    );
    await pump(tester, child: unbounded(1200));
    expect(find.text('desktop'), findsOneWidget);
    await pump(tester, child: unbounded(400));
    expect(find.text('mobile'), findsOneWidget);
  });

  testWidgets('bounded width takes precedence over MediaQuery', (tester) async {
    await pump(
      tester,
      width: 350,
      child: const MediaQuery(
        data: MediaQueryData(size: Size(1400, 900)),
        child: _TabletView(),
      ),
    );
    expect(find.text('mobile'), findsOneWidget);
  });

  testWidgets('reports missing width and app provider clearly', (tester) async {
    // RawView omits the MediaQuery normally installed by the test harness.
    await tester.pumpWidget(
      RawView(
        view: tester.view,
        child: const ResponsiveAppScope(
          config: _Config(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: OverflowBox(
              minWidth: 0,
              maxWidth: double.infinity,
              child: _View(),
            ),
          ),
        ),
      ),
      wrapWithView: false,
    );
    expect(
      tester.takeException(),
      isA<FlutterError>().having(
        (e) => e.toString(),
        'message',
        contains('finite available width'),
      ),
    );
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: _View(
          overrides: ResponsiveBreakpointOverrides(
            tabletMinWidth: 600,
            desktopMinWidth: 1024,
          ),
        ),
      ),
    );
    expect(
      tester.takeException(),
      isA<FlutterError>().having(
        (e) => e.toString(),
        'message',
        contains('requires a ResponsiveAppScope'),
      ),
    );
  });

  testWidgets('rejects invalid app definitions and merged partial overrides', (
    tester,
  ) async {
    for (final config in [
      const _Config(tabletMinWidth: 0),
      const _Config(tabletMinWidth: -1),
      const _Config(tabletMinWidth: double.nan),
      const _Config(desktopMinWidth: double.infinity),
      const _Config(tabletMinWidth: 1024),
      const _Config(desktopMinWidth: 500),
    ]) {
      await pump(tester, config: config);
      expect(
        tester.takeException(),
        isA<FlutterError>().having(
          (e) => e.toString(),
          'message',
          contains('app configuration'),
        ),
      );
    }
    await pump(
      tester,
      child: const ResponsiveScope(
        overrides: ResponsiveBreakpointOverrides(tabletMinWidth: 900),
        child: _View(
          overrides: ResponsiveBreakpointOverrides(desktopMinWidth: 800),
        ),
      ),
    );
    expect(
      tester.takeException(),
      isA<FlutterError>().having(
        (e) => e.toString(),
        'message',
        contains('merged component/scope/app'),
      ),
    );
  });

  testWidgets('owning state and its data survive breakpoint changes', (
    tester,
  ) async {
    const counter = _Counter();
    await pump(tester, width: 400, child: counter);
    final state = tester.state<_CounterState>(find.byType(_Counter));
    state.increment();
    await tester.pump();
    expect(find.text('mobile:1'), findsOneWidget);
    await pump(tester, width: 1200, child: counter);
    expect(find.text('desktop:1'), findsOneWidget);
    expect(tester.state(find.byType(_Counter)), same(state));
    expect(_CounterState.initializations, 1);
    expect(_CounterState.disposals, 0);
    await tester.pumpWidget(const SizedBox());
    expect(_CounterState.disposals, 1);
  });

  for (final fails in [false, true]) {
    testWidgets(
      'query adapters forward ${fails ? 'errors' : 'data'} without rerunning on resize',
      (tester) async {
        final completer = Completer<String>();
        final calls = <String>[];
        final failure = StateError('failure');
        final trace = StackTrace.current;
        final query = _Query(completer, calls);
        await pump(tester, width: 400, child: query);
        expect(find.text('loader-mobile'), findsOneWidget);
        await pump(tester, width: 1200, child: query);
        expect(find.text('loader-desktop'), findsOneWidget);
        expect(query.tracker.queryCalls, 1);
        if (fails) {
          completer.completeError(failure, trace);
        } else {
          completer.complete('payload');
        }
        await tester.pumpAndSettle();
        expect(
          find.text(fails ? 'error-desktop' : 'content-desktop:payload'),
          findsOneWidget,
        );
        for (final width in [400.0, 800.0, 1200.0]) {
          calls.clear();
          await pump(tester, width: width, child: query);
          expect(calls, [width < 1024 ? 'mobile' : 'desktop']);
        }
        expect(query.tracker.queryCalls, 1);
        if (fails) {
          expect(query.tracker.lastError, same(failure));
          expect(query.tracker.lastStackTrace, same(trace));
        }
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets('screen adapters forward route identity for both phases', (
    tester,
  ) async {
    final route = RouteContext.fromUri(Uri.parse('/profile?id=42'));
    final screen = _Screen();
    for (final preview in [false, true]) {
      for (final (width, variant) in [
        (400.0, 'mobile'),
        (800.0, 'mobile'),
        (1200.0, 'desktop'),
      ]) {
        await pump(
          tester,
          width: width,
          child: Builder(
            builder: (context) => preview
                ? screen.buildPreview(context, route)
                : screen.buildContent(context, route),
          ),
        );
        expect(
          find.text('${preview ? 'preview' : 'content'}-$variant'),
          findsOneWidget,
        );
        expect(screen.lastRoute, same(route));
      }
    }
  });
}

class _Config implements ResponsiveBreakpoints {
  const _Config({this.tabletMinWidth = 600, this.desktopMinWidth = 1024});
  @override
  final double tabletMinWidth;
  @override
  final double desktopMinWidth;
}

class _View extends StatelessComponent with Responsive {
  const _View({this.overrides, this.calls});
  final ResponsiveBreakpointOverrides? overrides;
  final List<String>? calls;
  @override
  ResponsiveBreakpointOverrides? get responsiveBreakpoints => overrides;
  @override
  Widget buildMobile(BuildContext context) {
    calls?.add('mobile');
    return const Text('mobile');
  }

  @override
  Widget buildDesktop(BuildContext context) {
    calls?.add('desktop');
    return const Text('desktop');
  }
}

class _TabletView extends _View {
  const _TabletView({super.overrides, super.calls});
  @override
  Widget buildTablet(BuildContext context) {
    calls?.add('tablet');
    return const Text('tablet');
  }
}

class _Counter extends StatefulComponent {
  const _Counter();
  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> with Responsive {
  static int initializations = 0;
  static int disposals = 0;
  int count = 0;
  void increment() => setState(() => count++);
  @override
  void initState() {
    super.initState();
    initializations++;
  }

  @override
  void dispose() {
    disposals++;
    super.dispose();
  }

  @override
  Widget buildMobile(BuildContext context) => Text('mobile:$count');
  @override
  Widget buildDesktop(BuildContext context) => Text('desktop:$count');
}

class _Query extends QueryComponent<String>
    with
        ResponsiveQueryContent<String>,
        ResponsiveQueryLoader<String>,
        ResponsiveQueryError<String> {
  _Query(this.completer, this.calls);
  final Completer<String> completer;
  final List<String> calls;
  final tracker = _QueryTracker();
  @override
  String get logTag => '_Query';
  @override
  Future<String> query(QueryHooks use) {
    tracker.queryCalls++;
    return completer.future;
  }

  @override
  Widget buildLoaderMobile(BuildContext context) => const Text('loader-mobile');
  @override
  Widget buildLoaderDesktop(BuildContext context) =>
      const Text('loader-desktop');
  @override
  Widget buildContentMobile(BuildContext context, String data) {
    calls.add('mobile');
    return Text('content-mobile:$data');
  }

  @override
  Widget buildContentDesktop(BuildContext context, String data) {
    calls.add('desktop');
    return Text('content-desktop:$data');
  }

  @override
  Widget buildErrorMobile(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    calls.add('mobile');
    tracker.lastError = error;
    tracker.lastStackTrace = stackTrace;
    return const Text('error-mobile');
  }

  @override
  Widget buildErrorDesktop(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    calls.add('desktop');
    tracker.lastError = error;
    tracker.lastStackTrace = stackTrace;
    return const Text('error-desktop');
  }
}

class _Screen extends Screen
    with ResponsiveScreenContent, ResponsiveScreenPreview {
  RouteContext? lastRoute;
  @override
  Widget buildContentMobile(BuildContext context, RouteContext route) {
    lastRoute = route;
    return const Text('content-mobile');
  }

  @override
  Widget buildContentDesktop(BuildContext context, RouteContext route) {
    lastRoute = route;
    return const Text('content-desktop');
  }

  @override
  Widget buildPreviewMobile(BuildContext context, RouteContext route) {
    lastRoute = route;
    return const Text('preview-mobile');
  }

  @override
  Widget buildPreviewDesktop(BuildContext context, RouteContext route) {
    lastRoute = route;
    return const Text('preview-desktop');
  }
}

class _QueryTracker {
  int queryCalls = 0;
  Object? lastError;
  StackTrace? lastStackTrace;
}

class _App extends TestApp {
  @override
  String get logTag => '_App';
  @override
  Widget buildApp() => const Directionality(
    textDirection: TextDirection.ltr,
    child: Align(child: SizedBox(width: 700, child: _TabletView())),
  );
}

class _TabletQuery extends _Query {
  @override
  String get logTag => '_TabletQuery';
  _TabletQuery(super.completer, super.calls);
  @override
  Widget buildLoaderTablet(BuildContext context) => const Text('loader-tablet');
  @override
  Widget buildContentTablet(BuildContext context, String data) =>
      Text('content-tablet:$data');
  @override
  Widget buildErrorTablet(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    tracker.lastError = error;
    tracker.lastStackTrace = stackTrace;
    return const Text('error-tablet');
  }
}

class _TabletScreen extends _Screen {
  @override
  Widget buildContentTablet(BuildContext context, RouteContext route) {
    lastRoute = route;
    return const Text('content-tablet');
  }

  @override
  Widget buildPreviewTablet(BuildContext context, RouteContext route) {
    lastRoute = route;
    return const Text('preview-tablet');
  }
}
