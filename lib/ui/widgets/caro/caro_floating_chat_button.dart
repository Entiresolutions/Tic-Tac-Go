import 'package:flutter/material.dart';
import 'package:tic_tac_go/game/caro/caro_controller.dart';
import '../../../core/theme/app_colors.dart';

/// Floating chat button with a Messenger-style notification badge.
class CaroFloatingChatButton extends StatefulWidget {
  final CaroController controller;
  final VoidCallback onPressed;
  final int unreadCount;

  const CaroFloatingChatButton({
    super.key,
    required this.controller,
    required this.onPressed,
    required this.unreadCount,
  });

  @override
  State<CaroFloatingChatButton> createState() => _CaroFloatingChatButtonState();
}

class _CaroFloatingChatButtonState extends State<CaroFloatingChatButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = widget.unreadCount > 0;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: hasUnread ? _scaleAnimation.value : 1.0,
          child: GestureDetector(
            onTap: widget.onPressed,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.5),
                    blurRadius: hasUnread ? 16 : 12,
                    spreadRadius: hasUnread ? 2 : 0,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Icon chat
                  const Center(
                    child: Icon(
                      Icons.chat_bubble,
                      color: AppColors.textWhite,
                      size: 26,
                    ),
                  ),

                  // Badge notification
                  if (hasUnread)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.defeat,
                                AppColors.defeat,
                              ],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.textWhite, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.defeat.withValues(alpha: 0.6),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Center(
                            child: Text(
                              widget.unreadCount > 99
                                  ? '99+'
                                  : '${widget.unreadCount}',
                              style: const TextStyle(
                                color: AppColors.textWhite,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
