import 'package:flutter/widgets.dart';
import 'package:grumpy/grumpy.dart';

import '../components/query_component.dart';
import '../screens/screen.dart';
import 'responsive_breakpoints.dart';

/// Adds width-based views to a stateless widget or a State class.
///
/// Implement [buildMobile] and [buildDesktop], and optionally [buildTablet],
/// instead of build. For a stateful widget apply this mixin to its State.
/// The owning state survives breakpoint changes; child state follows normal
/// Flutter identity rules. Inactive views are not retained.
///
/// Uses available parent width, falling back to MediaQuery for unbounded width.
/// Parents requiring intrinsic child measurements are not supported; supply
/// explicit width constraints instead. Requires a ResponsiveAppScope ancestor.
mixin Responsive {
  /// Partial component overrides; omitted thresholds inherit from scopes/app.
  ResponsiveBreakpointOverrides? get responsiveBreakpoints => null;

  /// Builds the mobile view.
  Widget buildMobile(BuildContext context);

  /// Builds the tablet view, defaulting to the mobile view.
  Widget buildTablet(BuildContext context) => buildMobile(context);

  /// Builds the desktop view.
  Widget buildDesktop(BuildContext context);

  /// Selects a view from the available width. Implement the variant builders.
  Widget build(BuildContext context) => ResponsiveLayout(
    overrides: responsiveBreakpoints,
    mobile: buildMobile,
    tablet: buildTablet,
    desktop: buildDesktop,
  );
}

/// Adds responsive content views to a [QueryComponent].
///
/// Implement the mobile and desktop variants instead of buildContent; tablet
/// defaults to mobile. Do not combine with another mixin replacing buildContent.
/// With a stateful wrapper for this hook, apply Responsive to its State instead.
mixin ResponsiveQueryContent<T> on QueryComponent<T> {
  /// Partial component overrides; omitted thresholds inherit from scopes/app.
  ResponsiveBreakpointOverrides? get responsiveBreakpoints => null;

  /// Builds the mobile content view.
  Widget buildContentMobile(BuildContext context, T data);

  /// Builds the tablet content view, defaulting to mobile.
  Widget buildContentTablet(BuildContext context, T data) =>
      buildContentMobile(context, data);

  /// Builds the desktop content view.
  Widget buildContentDesktop(BuildContext context, T data);

  @override
  Widget buildContent(BuildContext context, T data) => ResponsiveLayout(
    overrides: responsiveBreakpoints,
    mobile: (context) => buildContentMobile(context, data),
    tablet: (context) => buildContentTablet(context, data),
    desktop: (context) => buildContentDesktop(context, data),
  );
}

/// Adds responsive loader views to a [QueryComponent].
///
/// Implement the mobile and desktop variants instead of buildLoader; tablet
/// defaults to mobile. Do not combine with another mixin replacing buildLoader.
/// With a stateful wrapper for this hook, apply Responsive to its State instead.
mixin ResponsiveQueryLoader<T> on QueryComponent<T> {
  /// Partial component overrides; omitted thresholds inherit from scopes/app.
  ResponsiveBreakpointOverrides? get responsiveBreakpoints => null;

  /// Builds the mobile loader view.
  Widget buildLoaderMobile(BuildContext context);

  /// Builds the tablet loader view, defaulting to mobile.
  Widget buildLoaderTablet(BuildContext context) => buildLoaderMobile(context);

  /// Builds the desktop loader view.
  Widget buildLoaderDesktop(BuildContext context);

  @override
  Widget buildLoader(BuildContext context) => ResponsiveLayout(
    overrides: responsiveBreakpoints,
    mobile: (context) => buildLoaderMobile(context),
    tablet: (context) => buildLoaderTablet(context),
    desktop: (context) => buildLoaderDesktop(context),
  );
}

/// Adds responsive error views to a [QueryComponent].
///
/// Implement the mobile and desktop variants instead of buildError; tablet
/// defaults to mobile. Do not combine with another mixin replacing buildError.
/// With a stateful wrapper for this hook, apply Responsive to its State instead.
mixin ResponsiveQueryError<T> on QueryComponent<T> {
  /// Partial component overrides; omitted thresholds inherit from scopes/app.
  ResponsiveBreakpointOverrides? get responsiveBreakpoints => null;

  /// Builds the mobile error view.
  Widget buildErrorMobile(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  );

  /// Builds the tablet error view, defaulting to mobile.
  Widget buildErrorTablet(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) => buildErrorMobile(context, error, stackTrace);

  /// Builds the desktop error view.
  Widget buildErrorDesktop(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  );

  @override
  Widget buildError(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) => ResponsiveLayout(
    overrides: responsiveBreakpoints,
    mobile: (context) => buildErrorMobile(context, error, stackTrace),
    tablet: (context) => buildErrorTablet(context, error, stackTrace),
    desktop: (context) => buildErrorDesktop(context, error, stackTrace),
  );
}

/// Adds responsive content views to a [Screen].
///
/// Implement the mobile and desktop variants instead of buildContent; tablet
/// defaults to mobile. Do not combine with another mixin replacing buildContent.
/// With a stateful wrapper for this hook, apply Responsive to its State instead.
mixin ResponsiveScreenContent on Screen {
  /// Partial component overrides; omitted thresholds inherit from scopes/app.
  ResponsiveBreakpointOverrides? get responsiveBreakpoints => null;

  /// Builds the mobile content view.
  Widget buildContentMobile(BuildContext context, RouteContext route);

  /// Builds the tablet content view, defaulting to mobile.
  Widget buildContentTablet(BuildContext context, RouteContext route) =>
      buildContentMobile(context, route);

  /// Builds the desktop content view.
  Widget buildContentDesktop(BuildContext context, RouteContext route);

  @override
  Widget buildContent(BuildContext context, RouteContext route) =>
      ResponsiveLayout(
        overrides: responsiveBreakpoints,
        mobile: (context) => buildContentMobile(context, route),
        tablet: (context) => buildContentTablet(context, route),
        desktop: (context) => buildContentDesktop(context, route),
      );
}

/// Adds responsive preview views to a [Screen].
///
/// Implement the mobile and desktop variants instead of buildPreview; tablet
/// defaults to mobile. Do not combine with another mixin replacing buildPreview.
/// With a stateful wrapper for this hook, apply Responsive to its State instead.
mixin ResponsiveScreenPreview on Screen {
  /// Partial component overrides; omitted thresholds inherit from scopes/app.
  ResponsiveBreakpointOverrides? get responsiveBreakpoints => null;

  /// Builds the mobile preview view.
  Widget buildPreviewMobile(BuildContext context, RouteContext route);

  /// Builds the tablet preview view, defaulting to mobile.
  Widget buildPreviewTablet(BuildContext context, RouteContext route) =>
      buildPreviewMobile(context, route);

  /// Builds the desktop preview view.
  Widget buildPreviewDesktop(BuildContext context, RouteContext route);

  @override
  Widget buildPreview(BuildContext context, RouteContext route) =>
      ResponsiveLayout(
        overrides: responsiveBreakpoints,
        mobile: (context) => buildPreviewMobile(context, route),
        tablet: (context) => buildPreviewTablet(context, route),
        desktop: (context) => buildPreviewDesktop(context, route),
      );
}
