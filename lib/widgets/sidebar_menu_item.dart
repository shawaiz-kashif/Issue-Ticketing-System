import 'package:flutter/material.dart';

class SidebarMenuItem extends StatefulWidget {
  final String title;
  final IconData icon;
  final IconData filledIcon;
  final bool isSelected;
  // Removed: final bool isCollapsed; // No longer needed
  final VoidCallback onTap;
  final int index; // Used for staggered initial animation

  const SidebarMenuItem({
    super.key,
    required this.title,
    required this.icon,
    required this.filledIcon,
    required this.isSelected,
    // Removed: required this.isCollapsed,
    required this.onTap,
    required this.index,
  });

  @override
  State<SidebarMenuItem> createState() => _SidebarMenuItemState();
}

class _SidebarMenuItemState extends State<SidebarMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Initial entrance animation for each item, still staggered.
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (widget.index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animationValue, child) {
        return Transform.translate(
          offset: Offset(-50 * (1 - animationValue), 0),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: animationValue,
            child: MouseRegion(
              // Localized MouseRegion and hover state
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: GestureDetector(
                onTap: widget.onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  transform: Matrix4.identity()
                    ..scale(_isHovered ? 1.02 : 1.0), // Local hover scale
                  decoration: BoxDecoration(
                    color: widget.isSelected
                        ? Colors.white.withOpacity(0.15)
                        : _isHovered
                            ? Colors.white.withOpacity(0.08)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: widget.isSelected
                        ? Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          )
                        : null,
                    boxShadow: widget.isSelected
                        ? [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Padding(
                    // Added Padding to ensure consistent inner spacing
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20, // Fixed padding for expanded state
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(opacity: animation, child: child),
                          child: Icon(
                            widget.isSelected ? widget.filledIcon : widget.icon,
                            key: ValueKey(
                                widget.isSelected), // Key for AnimatedSwitcher
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        // Text is always visible as sidebar is not collapsed
                        const SizedBox(width: 16),
                        Expanded(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: widget.isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                            child: Text(
                              widget.title,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
