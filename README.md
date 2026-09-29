# Grumpy Flutter

Flutter presentation primitives for Grumpy applications, including components,
query-driven widgets, screens, stateful screen/query wrappers, and routing
integration.

## Features

- Stateless, stateful, and query component base classes.
- Screen routes with preview and final-content phases.
- Stateful wrappers that preserve local UI state.
- Structured Flutter Widget Inspector diagnostics.

## Widget Inspector

In debug builds, Grumpy widgets add structured properties to Flutter's Widget
Inspector. Inspect a `QueryComponent`, screen host, `ScreenRenderer`, or
stateful wrapper to see component identity, safe query/result shapes,
dependency state and counters, navigation timing, and complete
route/module/middleware lineage.

The diagnostics retain metadata only. They do not expose query results, route
or query values, controller text, errors, messages, URLs, callback closures, or
stack frames. Tracking is created inside assertions, so release and profile
builds do not retain it.

Private screen-host and wrapper widgets are implementation nodes. In DevTools,
enable **Show implementation widgets** if they are hidden. If package widgets
are filtered, add the `grumpy_flutter` package directory to the Inspector's
package-directory configuration.

Screen subclasses can contribute safe properties through the protected hook:

```dart
class SettingsScreen extends Screen {
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      FlagProperty('offline capable', value: true, ifTrue: 'enabled'),
    );
  }

  // buildContent and buildPreview omitted.
}
```

Only add configuration metadata such as types, flags, enums, and counts. Do not
add user data, resolved route values, credentials, controller contents, errors,
or stack traces. The hook does not change `Screen.toString()` and does not make
`Screen` a widget.

## Usage

Extend the component or screen type matching the UI lifecycle you need:

```dart
class ProfileSummary extends StatelessComponent {
  const ProfileSummary({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
```

## Responsive views

App configuration must implement `ResponsiveBreakpoints`. Mix in
`DefaultResponsiveBreakpoints` to start with tablet at 600 and desktop at 1024
logical pixels, then override either getter as needed:

```dart
class AppConfig with DefaultResponsiveBreakpoints {
  const AppConfig();

  @override
  double get desktopMinWidth => 1200;
}
```

Use `Responsive` on a `StatelessComponent` (or a Flutter `StatelessWidget`) and
provide mobile and desktop builders. Tablet is optional and defaults to mobile:

```dart
class ProfileCard extends StatelessComponent with Responsive {
  const ProfileCard({super.key});

  @override
  Widget buildMobile(BuildContext context) => const Text('Compact profile');

  @override
  Widget buildDesktop(BuildContext context) => const Text('Expanded profile');

  // Optionally implement buildTablet(BuildContext context).
}
```

For a stateful component, apply `Responsive` to its `State` class and implement
these same builders instead of `build`. Its state, controllers, and other owned
resources survive breakpoint changes. Descendant state follows normal Flutter
widget identity rules; inactive views are not cached.

Each threshold resolves independently: **component override → nearest scope
supplying that threshold → app config**. To override only desktop for a component:

```dart
@override
ResponsiveBreakpointOverrides get responsiveBreakpoints =>
    const ResponsiveBreakpointOverrides(desktopMinWidth: 1400);
```

Scopes can override selected thresholds for a subtree:

```dart
ResponsiveScope(
  overrides: const ResponsiveBreakpointOverrides(tabletMinWidth: 500),
  child: const ProfileCard(),
)
```

Nested scopes inherit omitted values from outer scopes. The final values must be
finite and satisfy `0 < tabletMinWidth < desktopMinWidth`; conflicting partial
overrides produce a descriptive error. Configurations should be immutable;
rebuild a scope with updated configuration to update responsive descendants.

`AppModule.run()` installs `ResponsiveAppScope` automatically. When calling
`buildApp()` directly, or rendering standalone components in tests, wrap the tree:

```dart
ResponsiveAppScope(
  config: const AppConfig(),
  child: app.buildApp(),
)
```

An app scope is required even when component overrides specify both thresholds.
Nested app scopes start an independent configuration chain.

The selected view depends on **available parent width**, using `LayoutBuilder`:
mobile below `tabletMinWidth`, tablet from there up to `desktopMinWidth`, and
desktop at or above `desktopMinWidth`. A narrow sidebar can therefore use a mobile
view inside a desktop window. If horizontal constraints are unbounded, window
width from the nearest `MediaQuery` is used; without either width source, rendering
reports an error. Constrain components with `SizedBox`, `ConstrainedBox`, or
`Expanded` where appropriate. Parents that require intrinsic child measurements
are not supported by `LayoutBuilder`; use explicit constraints instead.

Query and screen adapters use the same selection and configuration rules:

| Mixin | Builders (mobile and desktop required; tablet optional) |
| --- | --- |
| `ResponsiveQueryContent<T>` | `buildContentMobile/Tablet/Desktop(context, data)` |
| `ResponsiveQueryLoader<T>` | `buildLoaderMobile/Tablet/Desktop(context)` |
| `ResponsiveQueryError<T>` | `buildErrorMobile/Tablet/Desktop(context, error, stackTrace)` |
| `ResponsiveScreenContent` | `buildContentMobile/Tablet/Desktop(context, route)` |
| `ResponsiveScreenPreview` | `buildPreviewMobile/Tablet/Desktop(context, route)` |

Adapters for different hooks can coexist on a class. Implement the variant
builders instead of the original hook. Do not combine two mixins replacing the
same hook: with `StatefulQueryContent`, `StatefulQueryLoader`,
`StatefulQueryError`, `StatefulScreenContent`, or `StatefulScreenPreview`, apply
`Responsive` to the created state instead. Resizing a query view does not rerun
its query.

**Migration:** existing app configs must implement `ResponsiveBreakpoints` or
mix in `DefaultResponsiveBreakpoints`. Generic wrappers around this package's
modules, routes, guards, and screen renderers must also use
`AppConfig extends ResponsiveBreakpoints`.

## Sister packages

Explore the other packages in the Grumpy ecosystem:

| Package | Purpose |
| --- | --- |
| [grumpy](https://github.com/mcquenji/grumpy) | Core modules, repositories, routing, and lifecycle management. |
| [grumpy_annotations](https://github.com/mcquenji/grumpy_annotations) | Annotations for architecture rules and code generation. |
| [grumpy_cli](https://github.com/mcquenji/grumpy_cli) | Typed command-line applications, configuration, and prompts. |
| [grumpy_io](https://github.com/mcquenji/grumpy_io) | File system, networking, and other IO utilities. |
| [grumpy_gen](https://github.com/mcquenji/grumpy_gen) | Route and typed configuration code generation. |
| [grumpy_lints](https://github.com/mcquenji/grumpy_lints) | Analyzer rules for Grumpy architecture conventions. |
| [grumpy_context](https://github.com/mcquenji/grumpy_context) | Project discovery and shared generation configuration. |
| [grumpy_bricks](https://github.com/mcquenji/grumpy_bricks) | Mason bricks for generating Grumpy architecture units. |
| [grumpy_posthog](https://github.com/mcquenji/grumpy_posthog) | PostHog integration package scaffold (not yet implemented). |
| [grumpy_sentry](https://github.com/mcquenji/grumpy_sentry) | Sentry integration package scaffold (not yet implemented). |
