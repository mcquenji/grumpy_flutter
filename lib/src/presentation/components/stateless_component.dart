import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:grumpy_flutter/grumpy_flutter.dart';

/// A base class for stateless components in the application.
abstract class StatelessComponent extends StatelessWidget implements Component {
  /// A base class for stateless components in the application.
  const StatelessComponent({super.key});

  /// The component category displayed by Flutter diagnostics tools.
  @protected
  String get debugComponentKind => 'stateless';

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      StringProperty('grumpy component', debugComponentKind, quoted: false),
    );
  }
}
