// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import '../../core/theme/app_colors.dart';
// import '../screens/caro/caro_home_screen.dart';
// import '../screens/caro/history/match_history_screen.dart';
// import 'page_transition.dart';

// /// Clean 2-tab bottom navigation bar for Caro Game.
// class CustomBottomNav extends StatelessWidget {
//   final int currentIndex;

//   const CustomBottomNav({super.key, required this.currentIndex});

//   @override
//   Widget build(BuildContext context) {
//     // Only Play (0) and History (1) are active
//     final int selectedIndex = (currentIndex == 1 || currentIndex == 3) ? 1 : 0;

//     return SafeArea(
//       child: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//         decoration: BoxDecoration(
//           color: AppColors.surface,
//           borderRadius: BorderRadius.circular(32),
//           border: Border.all(color: AppColors.border, width: 1.5),
//           boxShadow: const [
//             BoxShadow(
//               color: AppColors.shadowMedium,
//               blurRadius: 16,
//               offset: Offset(0, 6),
//             ),
//           ],
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//           children: [
//             _buildNavItem(
//               context: context,
//               icon: Icons.sports_esports_rounded,
//               label: 'Play',
//               isActive: selectedIndex == 0,
//               onTap: () {
//                 if (selectedIndex != 0) {
//                   HapticFeedback.lightImpact();
//                   Navigator.pushReplacement(
//                     context,
//                     pageTransition(const CaroHomeScreen()),
//                   );
//                 }
//               },
//             ),
//             _buildNavItem(
//               context: context,
//               icon: Icons.history_rounded,
//               label: 'History',
//               isActive: selectedIndex == 1,
//               onTap: () {
//                 if (selectedIndex != 1) {
//                   HapticFeedback.lightImpact();
//                   Navigator.pushReplacement(
//                     context,
//                     pageTransition(const MatchHistoryScreen()),
//                   );
//                 }
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildNavItem({
//     required BuildContext context,
//     required IconData icon,
//     required String label,
//     required bool isActive,
//     required VoidCallback onTap,
//   }) {
//     return Expanded(
//       child: GestureDetector(
//         onTap: onTap,
//         behavior: HitTestBehavior.opaque,
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 220),
//           curve: Curves.easeOutCubic,
//           padding: const EdgeInsets.symmetric(vertical: 8),
//           decoration: BoxDecoration(
//             color: isActive ? AppColors.primary : AppColors.transparent,
//             borderRadius: BorderRadius.circular(24),
//             boxShadow: isActive
//                 ? const [
//                     BoxShadow(
//                       color: AppColors.glowPrimary,
//                       blurRadius: 10,
//                       offset: Offset(0, 3),
//                     ),
//                   ]
//                 : null,
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(
//                 icon,
//                 size: 20,
//                 color: isActive ? AppColors.textWhite : AppColors.textMuted,
//               ),
//               const SizedBox(width: 6),
//               Flexible(
//                 child: Text(
//                   label,
//                   style: TextStyle(
//                     fontSize: 13,
//                     fontWeight: FontWeight.bold,
//                     color: isActive ? AppColors.textWhite : AppColors.textMuted,
//                     letterSpacing: 0.2,
//                   ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
