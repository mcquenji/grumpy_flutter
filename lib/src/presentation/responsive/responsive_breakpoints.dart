import 'package:flutter/widgets.dart';

/// The complete breakpoint definition required by an app configuration.
///
/// Widths are logical pixels. Implement this interface or mix in
/// [DefaultResponsiveBreakpoints]. Configuration values should be immutable.
abstract interface class ResponsiveBreakpoints {
  /// The inclusive minimum width for the tablet view.
  double get tabletMinWidth;

  /// The inclusive minimum width for the desktop view.
  double get desktopMinWidth;
}

/// Default app thresholds, individually overridable by the app configuration.
mixin DefaultResponsiveBreakpoints implements ResponsiveBreakpoints {
  @override
  double get tabletMinWidth => 600;

  @override
  double get desktopMinWidth => 1024;
}

/// Partial thresholds for a component or [ResponsiveScope].
///
/// A null threshold inherits from the next level. The effective definition is
/// validated after merging, so overrides may not reverse the threshold order.
@immutable
class ResponsiveBreakpointOverrides {
  /// Creates partial overrides. Omitted values are inherited.
  const ResponsiveBreakpointOverrides({
    this.tabletMinWidth,
    this.desktopMinWidth,
  });

  /// Overrides the inclusive minimum tablet width, in logical pixels.
  final double? tabletMinWidth;

  /// Overrides the inclusive minimum desktop width, in logical pixels.
  final double? desktopMinWidth;
}

/// Supplies the app configuration to responsive descendants.
///
/// AppModule.run installs this automatically. Hosts calling buildApp directly
/// and standalone widget tests must wrap their tree explicitly. Replace the
/// configuration and rebuild this widget to change app thresholds.
///
/// A nested app scope starts a new chain, excluding outer scope overrides.
class ResponsiveAppScope extends StatelessWidget {
  /// Creates the root of a responsive configuration chain.
  const ResponsiveAppScope({
    required this.config,
    required this.child,
    super.key,
  });

  /// The app's complete breakpoint definition.
  final ResponsiveBreakpoints config;

  /// The subtree using this configuration.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tablet = config.tabletMinWidth;
    final desktop = config.desktopMinWidth;
    _validate(tablet, desktop, 'app configuration');
    return _AppBreakpoints(
      tablet: tablet,
      desktop: desktop,
      child: _ScopeOverrides(
        overrides: const ResponsiveBreakpointOverrides(),
        child: child,
      ),
    );
  }
}

/// Overrides selected thresholds for a subtree.
///
/// Each omitted value inherits from the nearest outer scope defining it, then
/// the app configuration. A component's own overrides take precedence.
class ResponsiveScope extends StatelessWidget {
  /// Creates a scope with partial breakpoint overrides.
  const ResponsiveScope({
    required this.overrides,
    required this.child,
    super.key,
  });

  /// Thresholds to override for this subtree.
  final ResponsiveBreakpointOverrides overrides;

  /// The subtree receiving these overrides.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final parent = context
        .dependOnInheritedWidgetOfExactType<_ScopeOverrides>();
    return _ScopeOverrides(
      overrides: ResponsiveBreakpointOverrides(
        tabletMinWidth:
            overrides.tabletMinWidth ?? parent?.overrides.tabletMinWidth,
        desktopMinWidth:
            overrides.desktopMinWidth ?? parent?.overrides.desktopMinWidth,
      ),
      child: child,
    );
  }
}

class _AppBreakpoints extends InheritedWidget {
  const _AppBreakpoints({
    required this.tablet,
    required this.desktop,
    required super.child,
  });

  final double tablet;
  final double desktop;

  @override
  bool updateShouldNotify(_AppBreakpoints oldWidget) =>
      tablet != oldWidget.tablet || desktop != oldWidget.desktop;
}

class _ScopeOverrides extends InheritedWidget {
  const _ScopeOverrides({required this.overrides, required super.child});

  final ResponsiveBreakpointOverrides overrides;

  @override
  bool updateShouldNotify(_ScopeOverrides oldWidget) =>
      overrides.tabletMinWidth != oldWidget.overrides.tabletMinWidth ||
      overrides.desktopMinWidth != oldWidget.overrides.desktopMinWidth;
}

void _validate(double tablet, double desktop, String source) {
  if (!tablet.isFinite ||
      !desktop.isFinite ||
      tablet <= 0 ||
      desktop <= tablet) {
    throw FlutterError(
      'Invalid responsive breakpoints in $source: '
      'tabletMinWidth=$tablet, desktopMinWidth=$desktop. '
      'Both must be finite and satisfy '
      '0 < tabletMinWidth < desktopMinWidth. '
      'Check app configuration and any partial scope or component overrides.',
    );
  }
}

/// Internal layout shared by responsive mixins; not part of the public API.
class ResponsiveLayout extends StatelessWidget {
  /// Creates a layout that invokes only the selected variant builder.
  const ResponsiveLayout({
    required this.overrides,
    required this.mobile,
    required this.tablet,
    required this.desktop,
    super.key,
  });

  /// Component-level overrides.
  final ResponsiveBreakpointOverrides? overrides;

  /// The compact view builder.
  final WidgetBuilder mobile;

  /// The intermediate view builder, including its mobile fallback.
  final WidgetBuilder tablet;

  /// The expanded view builder.
  final WidgetBuilder desktop;

  @override
  Widget build(BuildContext context) {
    final app = context.dependOnInheritedWidgetOfExactType<_AppBreakpoints>();
    if (app == null) {
      throw FlutterError(
        'Responsive rendering requires a ResponsiveAppScope. '
        'Use AppModule.run(), or wrap your widget tree in '
        'ResponsiveAppScope(config: appConfig, child: ...).',
      );
    }
    final scope = context.dependOnInheritedWidgetOfExactType<_ScopeOverrides>();
    final tabletWidth =
        overrides?.tabletMinWidth ??
        scope?.overrides.tabletMinWidth ??
        app.tablet;
    final desktopWidth =
        overrides?.desktopMinWidth ??
        scope?.overrides.desktopMinWidth ??
        app.desktop;
    _validate(
      tabletWidth,
      desktopWidth,
      'merged component/scope/app definition',
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.maybeSizeOf(context)?.width;
        if (width == null || !width.isFinite || width < 0) {
          throw FlutterError(
            'Responsive rendering requires a finite available width. '
            'Constrain the component with SizedBox, ConstrainedBox, or Expanded, '
            'or supply a MediaQuery for the unbounded-width fallback.',
          );
        }
        if (width < tabletWidth) return mobile(context);
        if (width < desktopWidth) return tablet(context);
        return desktop(context);
      },
    );
  }
}
