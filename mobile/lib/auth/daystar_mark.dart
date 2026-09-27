import 'package:flutter/material.dart';

/// The Daystar "D" mark, as on the site's login page.
///
/// The site only publishes it as a 395 px PNG (`/assets/daystar/logo@2x.png`),
/// so it's sized by width and kept small.
class DaystarMark extends StatelessWidget {
  const DaystarMark({super.key, this.size = 52});

  /// Width in logical pixels; the height follows the mark's proportions.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/brand/daystar_mark.png',
      width: size,
      semanticLabel: 'Daystar',
      filterQuality: FilterQuality.medium,
    );
  }
}
