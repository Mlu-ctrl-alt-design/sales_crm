import 'package:flutter/material.dart';

import '../theme/daystar_theme.dart';

/// Placeholder brand mark until the Daystar logo is supplied.
class DaystarMark extends StatelessWidget {
  const DaystarMark({super.key, this.size = 52});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: DaystarColors.brand,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(Icons.wb_sunny_outlined,
          color: DaystarColors.marigold, size: size * 0.5),
    );
  }
}
