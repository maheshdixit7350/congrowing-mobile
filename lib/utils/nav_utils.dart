import 'package:flutter/material.dart';

/// Safely pops the current route. If there is no route to pop to,
/// navigates to the home screen instead (prevents blank screens).
void safeNavigateBack(BuildContext context) {
  if (Navigator.canPop(context)) {
    Navigator.pop(context);
  } else {
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }
}
