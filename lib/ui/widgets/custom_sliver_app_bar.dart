import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/audio_service.dart';
import '../../services/haptic_service.dart';

class CustomSliverAppBar extends StatelessWidget {
  final String title;
  final IconData icon;
  final IconData? backgroundIcon;
  final Animation<double>? animation;
  final PreferredSizeWidget? bottom;
  final double expandedHeight;

  const CustomSliverAppBar({
    super.key,
    required this.title,
    required this.icon,
    this.backgroundIcon,
    this.animation,
    this.bottom,
    this.expandedHeight = 160,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      iconTheme: const IconThemeData(color: AppColors.textWhite),
      leading: Navigator.canPop(context)
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textWhite),
              tooltip: 'Back',
              onPressed: () {
                HapticService.instance.lightImpact();
                AudioService.instance.playButtonClick();
                Navigator.pop(context);
              },
            )
          : null,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textWhite, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textWhite,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      centerTitle: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.deepBlue],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.overlayLight,
                  ),
                ),
              ),
              if (backgroundIcon != null)
                Positioned(
                  right: 20,
                  bottom: bottom != null ? 58 : 20,
                  child: Opacity(
                    opacity: 0.1,
                    child: Icon(
                      backgroundIcon,
                      size: 80,
                      color: AppColors.textWhite,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottom: bottom,
    );
  }
}
