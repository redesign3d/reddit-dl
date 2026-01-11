import 'package:flutter/material.dart';

import 'tokens_generated.dart';

export 'tokens_generated.dart';

extension AppTokensContext on BuildContext {
  AppColorScheme get appColors {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark ? AppTokens.dark : AppTokens.light;
  }
}
