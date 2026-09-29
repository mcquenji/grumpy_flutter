import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:grumpy_flutter/grumpy_flutter.dart';

import 'modules.dart';
import 'repos.dart';

void main() {
  setUp(() async {
    await GetIt.I.reset(dispose: false);
  });

  tearDown(() async {
    await GetIt.I.reset(dispose: false);
    TestModule.resetTrackers();
    DummyModule.resetTrackers();
  });

  test('identifies stateless, stateful, and query components', () {
    expect(
      _propertyValue(const _StatelessTest(), 'grumpy component'),
      'stateless',
    );
    expect(
      _propertyValue(const _StatefulTest(), 'grumpy component'),
      'stateful',
    );

    const query = _RepoQuery();
    expect(_propertyValue(query, 'grumpy component'), 'query');
    expect(_propertyValue(query, 'query result type'), String);
    expect(_propertyValue(query, 'log tag'), '_RepoQuery');
    expect(_propertyValue(query, 'log group'), 'QueryComponent');
  });

  testWidgets('reports query loading, data, error, and dependency metadata', (
    tester,
  ) async {
    final repo = TestRepo();
    GetIt.I.registerSingletonAsync<TestRepo>(() async {
      await repo.initialize();
      return repo;
    });

    await tester.pumpWidget(const MaterialApp(home: _RepoQuery()));
    await tester.pump();

    var state = tester.state(find.byType(_RepoQuery));
    expect(
      _propertyValue(state, 'query state').toString(),
      contains('loading'),
    );
    expect(_propertyValue(state, 'active queries'), 0);
    expect(_propertyValue(state, 'dependencies'), isNotNull);

    repo.data(_secret);
    await tester.pumpAndSettle();
    state = tester.state(find.byType(_RepoQuery));
    expect(_propertyValue(state, 'query state').toString(), contains('data'));
    expect(
      _propertyValue(state, 'result shape'),
      'String (${_secret.length} characters)',
    );
    expect(_propertyValue(state, 'query executions'), greaterThan(0));
    expect(_propertyValue(state, 'latest query duration'), isA<int>());
    expect(_propertyValue(state, 'latest query completion'), isA<DateTime>());
    final dependencies =
        _propertyValue(state, 'dependencies')! as Diagnosticable;
    final repository =
        _propertyValue(dependencies, 'dependency 1')! as Diagnosticable;
    expect(_propertyValue(repository, 'repository type'), TestRepo);
    expect(_diagnosticText(state), isNot(contains(_secret)));

    repo.error(_SecretError(), StackTrace.current);
    await tester.pumpAndSettle();
    state = tester.state(find.byType(_RepoQuery));
    expect(_propertyValue(state, 'query state').toString(), contains('error'));
    expect(_propertyValue(state, 'error type'), _SecretError);
    expect(_propertyValue(state, 'stack trace'), isTrue);
    expect(_diagnosticText(state), isNot(contains(_secret)));
  });

  testWidgets('older query completion cannot replace latest timing outcome', (
    tester,
  ) async {
    final notifier = ValueNotifier<int>(0);
    final queries = <int, Completer<_SecretValue>>{
      0: Completer<_SecretValue>(),
      1: Completer<_SecretValue>(),
      2: Completer<_SecretValue>(),
    };

    await tester.pumpWidget(
      MaterialApp(home: _OverlappingQuery(notifier, queries)),
    );
    await tester.pump();
    notifier.value = 1;
    await tester.pump();
    notifier.value = 2;
    await tester.pump();

    queries[2]!.complete(_SecretValue());
    await tester.pump();
    final state = tester.state(find.byType(_OverlappingQuery));
    final latestCompletion =
        _propertyValue(state, 'latest query completion') as DateTime;

    queries[1]!.complete(_SecretValue());
    queries[0]!.complete(_SecretValue());
    await tester.pumpAndSettle();

    expect(_propertyValue(state, 'latest query completion'), latestCompletion);
    expect(_propertyValue(state, 'active queries'), 0);
    expect(_propertyValue(state, 'query executions'), 3);
    final dependencies =
        _propertyValue(state, 'dependencies')! as Diagnosticable;
    final external =
        _propertyValue(dependencies, 'dependency 1')! as Diagnosticable;
    expect(_propertyValue(external, 'key type'), ValueNotifier<int>);
    expect(_propertyValue(external, 'value type'), int);
    expect(_diagnosticText(state), isNot(contains(_secret)));
    notifier.dispose();
  });

  testWidgets('reports payload-stream dependency shape without payloads', (
    tester,
  ) async {
    final controller = StreamController<_SecretValue>.broadcast();
    await tester.pumpWidget(
      MaterialApp(home: _PayloadQuery(controller.stream)),
    );
    await tester.pump();

    var state = tester.state(find.byType(_PayloadQuery));
    var dependencies = _propertyValue(state, 'dependencies')! as Diagnosticable;
    var payload =
        _propertyValue(dependencies, 'dependency 1')! as Diagnosticable;
    expect(_propertyValue(payload, 'state').toString(), contains('pending'));
    expect(_propertyValue(payload, 'payload type'), _SecretValue);

    controller.add(_SecretValue());
    await tester.pumpAndSettle();
    state = tester.state(find.byType(_PayloadQuery));
    dependencies = _propertyValue(state, 'dependencies')! as Diagnosticable;
    payload = _propertyValue(dependencies, 'dependency 1')! as Diagnosticable;
    expect(_propertyValue(payload, 'state').toString(), contains('data'));
    expect(_diagnosticText(state), isNot(contains(_secret)));

    await tester.pumpWidget(const SizedBox.shrink());
    await controller.close();
  });

  testWidgets('screen hosts expose identity and route shape only', (
    tester,
  ) async {
    const route = RouteContext(
      fullPath: '/users/$_secret?token=$_secret#$_secret',
      pathParams: {'userId': _secret},
      queryParams: {'token': _secret},
      queryParamsAll: {
        'token': [_secret],
      },
      fragment: _secret,
    );
    const screen = _DiagnosticScreen();

    final content = await screen.content(route);
    await tester.pumpWidget(
      Directionality(textDirection: TextDirection.ltr, child: content),
    );
    final host = tester.widget(
      find.byWidgetPredicate(
        (widget) => widget.toStringShort() == '_DiagnosticScreen (content)',
      ),
    );
    expect(_propertyValue(host, 'screen type'), _DiagnosticScreen);
    expect(_propertyValue(host, 'path segments'), 2);
    expect(_propertyValue(host, 'path parameter names'), ['userId']);
    expect(_propertyValue(host, 'query parameter names'), ['token']);
    expect(_propertyValue(host, 'safe screen flag'), isTrue);
    expect(_diagnosticText(host), isNot(contains(_secret)));

    final preview = screen.preview(route);
    expect(preview.toStringShort(), '_DiagnosticScreen (preview)');
    expect(_diagnosticText(preview), isNot(contains(_secret)));
  });

  test('stateful wrappers report purpose and safe shapes', () {
    const route = RouteContext(
      fullPath: '/users/$_secret?token=$_secret#$_secret',
      pathParams: {'userId': _secret},
      queryParams: {'token': _secret},
      fragment: _secret,
    );
    final wrappers = <Diagnosticable>[
      const StatefulScreenContentComponent(
        _createScreenContentState,
        route: route,
      ),
      const StatefulScreenPreviewComponent(
        _createScreenPreviewState,
        route: route,
      ),
      StatefulQueryContentComponent<_SecretValue>(
        _createQueryContentState,
        data: _SecretValue(),
      ),
      StatefulQueryErrorComponent(
        _createQueryErrorState,
        error: _SecretError(),
        stackTrace: StackTrace.fromString(_secret),
      ),
      const StatefulQueryLoaderComponent(_createQueryLoaderState),
    ];

    expect(wrappers.map((widget) => _propertyValue(widget, 'grumpy wrapper')), [
      'stateful screen content',
      'stateful screen preview',
      'stateful query content',
      'stateful query error',
      'stateful query loader',
    ]);
    expect(_propertyValue(wrappers[2], 'data shape'), '_SecretValue');
    expect(_propertyValue(wrappers[3], 'error type'), _SecretError);
    expect(_propertyValue(wrappers[3], 'stack trace'), isTrue);
    expect(wrappers.map(_diagnosticText).join('\n'), isNot(contains(_secret)));
  });

  testWidgets('ScreenRenderer reports navigation timing and routing snapshot', (
    tester,
  ) async {
    final app = TestApp();
    await app.initialize();
    await app.activate();

    await tester.pumpWidget(app.buildApp());
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final renderer = find.byType(ScreenRenderer<TestAppConfig>);
    expect(renderer, findsOneWidget);
    final state = tester.state(renderer);
    expect(
      _propertyValue(state, 'navigation state').toString(),
      contains('completed'),
    );
    expect(_propertyValue(state, 'rendered view type'), isNotNull);
    expect(_propertyValue(state, 'preview rendered'), isTrue);
    expect(_propertyValue(state, 'final content rendered'), isTrue);
    expect(_propertyValue(state, 'navigation duration'), isA<int>());
    expect(_propertyValue(state, 'navigation completion'), isA<DateTime>());
    expect(_propertyValue(state, 'routing'), isNotNull);
  });
}

const _secret = 'GRUMPY_WIDGET_INSPECTOR_SENTINEL';

Object? _propertyValue(Diagnosticable diagnosticable, String name) {
  final property = diagnosticable
      .toDiagnosticsNode()
      .getProperties()
      .singleWhere((node) => node.name == name);
  return (property as DiagnosticsProperty<Object?>).value;
}

String _diagnosticText(
  Diagnosticable diagnosticable, [
  Set<Diagnosticable>? visited,
]) {
  visited ??= Set<Diagnosticable>.identity();
  if (!visited.add(diagnosticable)) return '';
  final properties = diagnosticable.toDiagnosticsNode().getProperties();
  return <String>[
    diagnosticable.runtimeType.toString(),
    for (final property in properties) ...[
      property.name ?? '',
      if (property is DiagnosticsProperty<Object?>)
        if (property.value case final Diagnosticable nested)
          _diagnosticText(nested, visited)
        else
          property.value.toString(),
    ],
  ].join('\n');
}

final class _SecretValue {
  @override
  String toString() => _secret;
}

final class _SecretError implements Exception {
  @override
  String toString() => _secret;
}

final class _StatelessTest extends StatelessComponent {
  const _StatelessTest();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

final class _StatefulTest extends StatefulComponent {
  const _StatefulTest();

  @override
  State<_StatefulTest> createState() => _StatefulTestState();
}

final class _StatefulTestState extends State<_StatefulTest> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

final class _RepoQuery extends QueryComponent<String> {
  const _RepoQuery();

  @override
  Widget buildContent(BuildContext context, String data) =>
      const SizedBox.shrink();

  @override
  Widget buildError(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) => const SizedBox.shrink();

  @override
  Widget buildLoader(BuildContext context) => const SizedBox.shrink();

  @override
  String get logTag => '_RepoQuery';

  @override
  Future<String> query(QueryHooks use) async {
    final (value, _) = await use.repo<String, TestRepo>();
    return value;
  }
}

final class _OverlappingQuery extends QueryComponent<_SecretValue> {
  const _OverlappingQuery(this.notifier, this.queries);

  final ValueNotifier<int> notifier;
  final Map<int, Completer<_SecretValue>> queries;

  @override
  Widget buildContent(BuildContext context, _SecretValue data) =>
      const SizedBox.shrink();

  @override
  Widget buildError(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) => const SizedBox.shrink();

  @override
  Widget buildLoader(BuildContext context) => const SizedBox.shrink();

  @override
  String get logTag => '_OverlappingQuery';

  @override
  Future<_SecretValue> query(QueryHooks use) {
    final invocation = use.value(notifier);
    return queries[invocation]!.future;
  }
}

final class _PayloadQuery extends QueryComponent<_SecretValue> {
  const _PayloadQuery(this.stream);

  final Stream<_SecretValue> stream;

  @override
  Widget buildContent(BuildContext context, _SecretValue data) =>
      const SizedBox.shrink();

  @override
  Widget buildError(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) => const SizedBox.shrink();

  @override
  Widget buildLoader(BuildContext context) => const SizedBox.shrink();

  @override
  String get logTag => '_PayloadQuery';

  @override
  Future<_SecretValue> query(QueryHooks use) async =>
      use.payloadStream<_SecretValue>(
        #payload,
        sourceKey: #source,
        createStream: () => stream,
      );
}

final class _DiagnosticScreen extends Screen {
  const _DiagnosticScreen();

  @override
  Widget buildContent(BuildContext context, RouteContext route) =>
      const SizedBox.shrink();

  @override
  Widget buildPreview(BuildContext context, RouteContext route) =>
      const SizedBox.shrink();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      FlagProperty('safe screen flag', value: true, ifTrue: 'enabled'),
    );
  }
}

ScreenContentState _createScreenContentState() => _ScreenContentState();
ScreenPreviewState _createScreenPreviewState() => _ScreenPreviewState();
QueryComponentContentState<_SecretValue> _createQueryContentState() =>
    _QueryContentState();
QueryComponentErrorState _createQueryErrorState() => _QueryErrorState();
QueryComponentLoaderState _createQueryLoaderState() => _QueryLoaderState();

final class _ScreenContentState extends State<StatefulScreenContentComponent> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

final class _ScreenPreviewState extends State<StatefulScreenPreviewComponent> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

final class _QueryContentState
    extends State<StatefulQueryContentComponent<_SecretValue>> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

final class _QueryErrorState extends State<StatefulQueryErrorComponent> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

final class _QueryLoaderState extends State<StatefulQueryLoaderComponent> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
