import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../bouncing_game_button.dart';

class CaroSurrenderDialog {
  static void show(BuildContext context, VoidCallback onSurrender) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppColors.border, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.defeat.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.flag_rounded,
                  color: AppColors.defeat,
                  size: 30,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Surrender Match?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Are you sure you want to forfeit this match to your opponent?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: BouncingGameButton(
                      height: 44,
                      backgroundColor: AppColors.surface,
                      bevelColor: AppColors.buttonWhiteBevel,
                      borderColor: AppColors.border,
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: BouncingGameButton(
                      height: 44,
                      backgroundColor: AppColors.defeat,
                      bevelColor: AppColors.defeatLight,
                      onPressed: () {
                        Navigator.pop(context);
                        onSurrender();
                      },
                      child: const Text(
                        'Surrender',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textWhite,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
