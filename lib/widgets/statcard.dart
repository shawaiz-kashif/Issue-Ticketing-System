import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12), // 👈 Reduced padding further
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // 👈 Reduced border radius
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        // 👈 Use LayoutBuilder to adapt to available space
        builder: (context, constraints) {
          final isVerySmall = constraints.maxHeight < 60;
          final isSmall = constraints.maxHeight < 80;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top row with icon and value
              Expanded(
                flex: isVerySmall ? 1 : 2,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isVerySmall ? 4 : 6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: isVerySmall ? 12 : 16, // 👈 Adaptive icon size
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                      child: FittedBox(
                        // 👈 Use FittedBox to scale text
                        fit: BoxFit.scaleDown,
                        child: Text(
                          value,
                          style: TextStyle(
                            fontSize: isVerySmall
                                ? 14
                                : (isSmall ? 16 : 18), // 👈 Adaptive font size
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom title
              if (!isVerySmall) // 👈 Hide title on very small cards
                Expanded(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: FittedBox(
                      // 👈 Use FittedBox for title too
                      fit: BoxFit.scaleDown,
                      child: Text(
                        title,
                        style: TextStyle(
                          color: const Color(0xFF6B7280),
                          fontSize: isSmall ? 15 : 20, // 👈 Adaptive font size
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
