// given the range of days, create a dot pattern, each dot is a day
// passed dots are grey, future dots are black

import 'package:flutter/material.dart';
import 'dart:math' show sqrt;

class DotPattern extends StatelessWidget {
  final int days;
  final int startDay;
  final bool isYearView;
  final bool isMonthView;
  final bool isWidget;
  const DotPattern({
    super.key,
    required this.days,
    required this.startDay,
    this.isYearView = false,
    this.isMonthView = false,
    this.isWidget = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate optimal dot size and spacing based on screen size
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        
        double dotSize;
        double spacing;

        if (isWidget) {
          // Deterministic column sizing to guarantee that all dots fit inside the widget canvas
          int cols = 25;
          if (days <= 31) {
            cols = 7; // Perfect calendar week grid for month view
          } else if (days <= 100) {
            cols = 12; // Beautiful grid for life view years
          } else if (days > 366) {
            cols = 40; // Dense grid to fit all 960 months in Life View Months
          }

          // Subtract 16 for left/right padding (8dp each)
          final usableWidth = width - 16;
          final cellWidth = usableWidth / cols;
          
          // Set spacing proportional to the cell size
          spacing = cellWidth * (days <= 31 ? 0.12 : (days <= 100 ? 0.15 : 0.22));
          dotSize = cellWidth - spacing;
          
          // Ensure a minimum dot size of 2dp for visibility
          if (dotSize < 2.0) {
            dotSize = 2.0;
            spacing = 0.5;
          }
        } else {
          // Pre-existing layout calculations for the main app UI (Unchanged)
          final area = width * height;
          final dotArea = area /
              (days *
                  (isYearView
                      ? 2.0
                      : isMonthView
                          ? 2.5
                          : 1.5));
          dotSize = (sqrt(dotArea) * 0.8).clamp(
            isYearView
                ? 8.0
                : isMonthView
                    ? 5.0
                    : 4.0,
            isYearView
                ? 16.0
                : isMonthView
                    ? 11.5
                    : 12.0,
          );
          spacing = dotSize * (isMonthView ? 0.4 : 1.0);
        }

        return Container(
          padding: EdgeInsets.only(
            top: isWidget
                ? 8
                : MediaQuery.of(context).padding.top + 30, // Account for status bar and title
            left: isWidget ? 8 : 16,
            right: isWidget ? 8 : 16,
            bottom: isWidget ? 8 : 16,
          ),
          child: Center(
            child: Wrap(
              alignment: WrapAlignment.start,
              spacing: spacing,
              runSpacing: spacing,
              children: List.generate(days, (index) {
                return Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < startDay
                        ? Theme.of(context).colorScheme.onSurface.withOpacity(0.15)
                        : Theme.of(context).colorScheme.primary,
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}
