import 'package:flutter/material.dart';
import 'package:tic_tac_go/game/caro/caro_controller.dart';
import 'package:tic_tac_go/game/caro/caro_chat_panel.dart';
import '../../../core/theme/app_colors.dart';

/// Chat overlay panel with a Messenger-style slide animation.
class CaroChatOverlay {
  static void show(BuildContext context, CaroController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (context) => _ChatOverlayContent(controller: controller),
    ).then((_) {
      // Close the chat when the overlay is dismissed.
      controller.closeChat();
    });
  }
}

class _ChatOverlayContent extends StatefulWidget {
  final CaroController controller;

  const _ChatOverlayContent({required this.controller});

  @override
  State<_ChatOverlayContent> createState() => _ChatOverlayContentState();
}

class _ChatOverlayContentState extends State<_ChatOverlayContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        color: AppColors.transparent,
        child: GestureDetector(
          onTap: () {}, // Prevent closing when tapping inside.
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: screenHeight * 0.7 + keyboardHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.textWhite, AppColors.draw],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Drag handle indicator
                          Expanded(
                            child: Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppColors.textWhite.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Divider line
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.transparent,
                            AppColors.primary,
                            AppColors.transparent,
                          ],
                        ),
                      ),
                    ),

                    // Title bar
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.textWhite,
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.draw,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primary,
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chat_bubble,
                              color: AppColors.textWhite,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Chat',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.close,
                              color: AppColors.draw,
                            ),
                            tooltip: 'Close',
                          ),
                        ],
                      ),
                    ),

                    // Chat panel content
                    Expanded(
                      child: CaroChatPanel(controller: widget.controller),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
