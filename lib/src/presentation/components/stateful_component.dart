import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:grumpy_flutter/grumpy_flutter.dart';

/// A base class for stateful components in the application.
abstract class StatefulComponent extends StatefulWidget implements Component {
  /// A base class for stateful components in the application.
  const StatefulComponent({super.key});

  /// The component category displayed by Flutter diagnostics tools.
  @protected
  String get debugComponentKind => 'stateful';

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      StringProperty('grumpy component', debugComponentKind, quoted: false),
    );
  }
}
