import 'package:flutter/material.dart';
import 'package:tic_tac_go/models/leaderboard_model.dart';
import 'package:tic_tac_go/services/leaderboard_service.dart';
import 'package:tic_tac_go/services/friend_service.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';

class UserProfileScreen extends StatefulWidget {
  final int userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with TickerProviderStateMixin {
  UserProfileDetail? _profile;
  bool _isLoading = true;
  String? _error;

  late AnimationController _animationController;
  late AnimationController _headerAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _headerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _scaleAnimation = CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.elasticOut,
    );

    _loadProfile();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _headerAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await LeaderboardService.getUserProfile(widget.userId);

      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
        _animationController.forward();
        _headerAnimationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendFriendRequest() async {
    if (_profile == null) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await FriendService.sendFriendRequest(_profile!.username);

      // Refresh profile to update button state
      await _loadProfile();

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.textWhite.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.textWhite,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Friend request sent'),
            ],
          ),
          backgroundColor: AppColors.victory,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.textWhite),
              const SizedBox(width: 12),
              Expanded(child: Text('Error: ${e.toString()}')),
            ],
          ),
          backgroundColor: AppColors.defeat,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.primary
          : AppColors.primary,
      body: _isLoading
          ? _buildLoadingState(isDark)
          : _error != null
          ? _buildErrorWidget(isDark)
          : _buildProfileContent(isDark),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryLight.withValues(alpha: 0.2),
                  AppColors.primaryLight.withValues(alpha: 0.2),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading profile...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textWhite70 : AppColors.draw,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(bool isDark) {
    if (_profile == null) return const SizedBox();

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(isDark),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildStatsCard(isDark),
                    const SizedBox(height: 16),
                    _buildActionButtons(isDark),
                    const SizedBox(height: 16),
                    _buildRecentMatchesSection(isDark),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 320,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.transparent,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.textWhite.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate if app bar is collapsed
          final double appBarHeight = constraints.maxHeight;
          final bool isCollapsed = appBarHeight <= kToolbarHeight + 50;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [AppColors.primaryLight, AppColors.primaryLight]
                    : [AppColors.primaryLight, AppColors.primaryLight],
              ),
            ),
            child: Stack(
              children: [
                // Decorative circles
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.textWhite.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -30,
                  left: -30,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.textWhite.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                // Content
                FlexibleSpaceBar(
                  titlePadding: EdgeInsets.only(
                    left: isCollapsed
                        ? 56
                        : 20, // Avoid the back button when the app bar is collapsed.
                    bottom: 16,
                    right: 16,
                  ),
                  centerTitle: false,
                  title: Text(
                    _profile!.username,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  background: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 80),
                      // Avatar
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Hero(
                          tag: 'avatar_${_profile!.userId}',
                          child: Stack(
                            children: [
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.textWhite.withValues(alpha: 0.9),
                                      AppColors.textWhite.withValues(alpha: 0.7),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: AppColors.textWhite,
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.textPrimary.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(3),
                                  child:
                                      _profile!.avatarUrl != null &&
                                          _profile!.avatarUrl!.isNotEmpty
                                      ? ClipOval(
                                          child: Image.network(
                                            _profile!.avatarUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Center(
                                                    child: Text(
                                                      _profile!.username[0]
                                                          .toUpperCase(),
                                                      style: TextStyle(
                                                        color: Colors
                                                            .blue
                                                            ,
                                                        fontSize: 42,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  );
                                                },
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            _profile!.username[0].toUpperCase(),
                                            style: TextStyle(
                                              color: AppColors.primaryLight,
                                              fontSize: 42,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              if (_profile!.isOnline)
                                Positioned(
                                  bottom: 5,
                                  right: 5,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: AppColors.victory,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.textWhite,
                                        width: 4,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.victory.withValues(
                                            alpha: 0.5,
                                          ),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Bio
                      if (_profile!.bio != null && _profile!.bio!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            _profile!.bio!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textWhite.withValues(alpha: 0.95),
                              fontSize: 14,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const SizedBox(height: 16),
                      // Rank badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.textWhite.withValues(alpha: 0.25),
                              AppColors.textWhite.withValues(alpha: 0.15),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.textWhite.withValues(alpha: 0.4),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.textPrimary.withValues(alpha: 0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.winHighlight,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.winHighlight.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.emoji_events_rounded,
                                color: AppColors.textWhite,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Rank #${_profile!.rank}',
                              style: const TextStyle(
                                color: AppColors.textWhite,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ); // Close the LayoutBuilder container.
        }, // Close the builder function.
      ), // Close the LayoutBuilder.
    );
  }

  Widget _buildStatsCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.primaryLight.withValues(alpha: 0.3),
                  AppColors.primaryLight.withValues(alpha: 0.3),
                ]
              : [AppColors.textWhite, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? AppColors.textWhite.withValues(alpha: 0.1)
              : AppColors.primaryLight.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? AppColors.textPrimary.withValues(alpha: 0.3)
                : AppColors.primaryLight.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Rating
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.winHighlight, AppColors.winHighlight],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.winHighlight.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.textWhite.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: AppColors.textWhite,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rating',
                      style: TextStyle(
                        color: AppColors.textWhite.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_profile!.rating}',
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Stats grid
          LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Wins',
                      '${_profile!.wins}',
                      AppColors.victory,
                      Icons.check_circle_rounded,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(
                      'Losses',
                      '${_profile!.losses}',
                      AppColors.defeat,
                      Icons.cancel_rounded,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(
                      'Draws',
                      '${_profile!.draws}',
                      AppColors.draw,
                      Icons.remove_circle_rounded,
                      isDark,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          // Win rate bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.trending_up_rounded,
                        size: 18,
                        color: isDark ? AppColors.textWhite70 : AppColors.draw,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Win rate',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textWhite70 : AppColors.draw,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.victory, AppColors.victory],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.victory.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(
                      '${_profile!.winRate.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textWhite,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.textWhite.withValues(alpha: 0.1)
                      : AppColors.draw,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (_profile!.winRate / 100).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primary],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Total games
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        AppColors.textWhite.withValues(alpha: 0.05),
                        AppColors.textWhite.withValues(alpha: 0.02),
                      ]
                    : [AppColors.draw, AppColors.draw],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? AppColors.textWhite.withValues(alpha: 0.1)
                    : AppColors.draw,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.games_rounded,
                    color: AppColors.primaryLight,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Total matches: ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textWhite70 : AppColors.draw,
                  ),
                ),
                Text(
                  '${_profile!.totalGames}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textWhite : AppColors.draw,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Member since
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today_rounded,
                color: isDark ? AppColors.textWhite50 : AppColors.draw,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                'Joined: ${DateFormat('dd/MM/yyyy').format(_profile!.createdAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textWhite50 : AppColors.draw,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    Color color,
    IconData icon,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textWhite70 : AppColors.draw,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Friend action button
          if (!_profile!.isFriend && !_profile!.hasPendingRequest)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryLight, AppColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryLight.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _sendFriendRequest,
                  icon: const Icon(Icons.person_add_rounded, size: 20),
                  label: const Text('Add Friend'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.transparent,
                    foregroundColor: AppColors.textWhite,
                    shadowColor: AppColors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            )
          else if (_profile!.hasPendingRequest)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.winHighlight.withValues(alpha: 0.2),
                      AppColors.winHighlight.withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.winHighlight, width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      color: AppColors.winHighlight,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Request sent',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.winHighlight,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_profile!.isFriend)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.victory, AppColors.victory],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.victory.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.info_outline, color: AppColors.textWhite),
                            SizedBox(width: 12),
                            Text('The challenge feature is coming soon!'),
                          ],
                        ),
                        backgroundColor: AppColors.primaryLight,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.sports_esports_rounded, size: 20),
                  label: const Text('Challenge'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.transparent,
                    foregroundColor: AppColors.textWhite,
                    shadowColor: AppColors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          if (_profile!.isFriend) ...[
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          AppColors.textWhite.withValues(alpha: 0.1),
                          AppColors.textWhite.withValues(alpha: 0.05),
                        ]
                      : [AppColors.draw, AppColors.draw],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? AppColors.textWhite.withValues(alpha: 0.2)
                      : AppColors.draw,
                ),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.message_rounded,
                  color: isDark ? AppColors.textWhite70 : AppColors.draw,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.textWhite),
                          SizedBox(width: 12),
                          Text('The messaging feature is coming soon!'),
                        ],
                      ),
                      backgroundColor: AppColors.primaryLight,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
                tooltip: 'Message',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentMatchesSection(bool isDark) {
    if (_profile!.recentMatches.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryLight, AppColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: AppColors.textWhite,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Recent Matches',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textWhite : AppColors.draw,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryLight.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '${_profile!.recentMatches.length}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryLight,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _profile!.recentMatches.length,
          itemBuilder: (context, index) {
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 400 + (index * 100)),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(30 * (1 - value), 0),
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: _buildMatchCard(_profile!.recentMatches[index], isDark),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMatchCard(RecentMatch match, bool isDark) {
    final isWin = match.result == 'win';
    final isDraw = match.result == 'draw';
    final resultColor = isWin
        ? AppColors.victory
        : isDraw
        ? AppColors.draw
        : AppColors.defeat;
    final resultIcon = isWin
        ? Icons.check_circle_rounded
        : isDraw
        ? Icons.remove_circle_rounded
        : Icons.cancel_rounded;
    final resultText = isWin
        ? 'Win'
        : isDraw
        ? 'Draw'
        : 'Loss';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  resultColor.withValues(alpha: 0.15),
                  resultColor.withValues(alpha: 0.08),
                ]
              : [AppColors.textWhite, resultColor.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: resultColor.withValues(alpha: 0.4), width: 2),
        boxShadow: [
          BoxShadow(
            color: resultColor.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Result badge
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  resultColor.withValues(alpha: 0.2),
                  resultColor.withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: resultColor.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Icon(resultIcon, color: resultColor, size: 28),
          ),
          const SizedBox(width: 16),
          // Match info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resultText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: resultColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'vs ',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppColors.textWhite50 : AppColors.draw,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        match.opponentUsername,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textWhite : AppColors.draw,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: isDark ? AppColors.textWhite50 : AppColors.draw,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(match.finishedAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textWhite50 : AppColors.draw,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Symbol badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        AppColors.textWhite.withValues(alpha: 0.1),
                        AppColors.textWhite.withValues(alpha: 0.05),
                      ]
                    : [AppColors.draw, AppColors.draw],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? AppColors.textWhite.withValues(alpha: 0.2)
                    : AppColors.draw,
              ),
            ),
            child: Text(
              match.symbol,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textWhite70 : AppColors.draw,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.defeat.withValues(alpha: 0.2),
                    AppColors.defeat.withValues(alpha: 0.2),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 60,
                color: isDark ? AppColors.defeat : AppColors.defeat,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'An error occurred',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textWhite : AppColors.draw,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? AppColors.textWhite70 : AppColors.draw,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: AppColors.textWhite,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: AppColors.primaryLight.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0) {
      return '${diff.inDays} days ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hours ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}
