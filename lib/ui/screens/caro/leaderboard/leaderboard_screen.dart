import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tic_tac_go/models/leaderboard_model.dart';
import 'package:tic_tac_go/services/leaderboard_service.dart';
import 'package:tic_tac_go/services/local_storage_service.dart';
import 'package:tic_tac_go/services/friend_service.dart';
import 'package:tic_tac_go/ui/screens/caro/profile/user_profile_screen.dart';
import 'package:tic_tac_go/ui/widgets/custom_sliver_app_bar.dart';
import '../../../../core/theme/app_colors.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<LeaderboardEntry> _entries = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;

  int _currentOffset = 0;
  final int _limit = 20;
  bool _hasMore = true;

  Timer? _debounce;
  String _currentSearch = '';

  late AnimationController _fabAnimationController;
  late AnimationController _headerAnimationController;
  late Animation<double> _fabAnimation;
  late Animation<double> _headerAnimation;

  @override
  void initState() {
    super.initState();

    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _headerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeOutBack,
    );
    _headerAnimation = CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOut,
    );

    _fabAnimationController.forward();
    _headerAnimationController.forward();

    _scrollController.addListener(_onScroll);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    _fabAnimationController.dispose();
    _headerAnimationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadMore();
      }
    }
  }

  Future<void> _loadData({bool isRefresh = false}) async {
    if (!mounted) return;

    if (isRefresh) {
      _currentOffset = 0;
      _hasMore = true;
    }

    setState(() {
      _isLoading = isRefresh || _entries.isEmpty;
      _error = null;
    });

    try {
      final results = await LocalStorageService.getLeaderboard(
        search: _currentSearch.isEmpty ? null : _currentSearch,
      );

      if (mounted) {
        setState(() {
          _entries = results;
          _currentOffset = _limit;
          _hasMore = false;
          _isLoading = false;
        });
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

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final results = await LeaderboardService.getLeaderboard(
        offset: _currentOffset,
        limit: _limit,
        search: _currentSearch.isEmpty ? null : _currentSearch,
      );

      if (mounted) {
        setState(() {
          _entries.addAll(results);
          _currentOffset += _limit;
          _hasMore = results.length >= _limit;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.textWhite),
                const SizedBox(width: 12),
                Expanded(child: Text('Error loading more: ${e.toString()}')),
              ],
            ),
            backgroundColor: AppColors.defeat,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (_currentSearch != value) {
        setState(() => _currentSearch = value);
        _loadData(isRefresh: true);
      }
    });
  }

  Future<void> _sendFriendRequest(String username) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await FriendService.sendFriendRequest(username);
      await _loadData(isRefresh: true);

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

  void _navigateToProfile(int userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(userId: userId),
      ),
    ).then((_) {
      _loadData(isRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.primary : AppColors.primary,
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            CustomSliverAppBar(
              title: 'Leaderboard',
              icon: Icons.emoji_events_rounded,
              backgroundIcon: Icons.emoji_events_rounded,
              animation: _headerAnimation,
            ),
            _buildSearchBar(isDark),
            _buildBody(isDark),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(isDark),
      // bottomNavigationBar: const CustomBottomNav(currentIndex: 0),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SearchBarDelegate(
        child: Container(
          color: isDark ? AppColors.primary : AppColors.primary,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        AppColors.primary.withValues(alpha: 0.3),
                        AppColors.primary.withValues(alpha: 0.3),
                      ]
                    : [AppColors.textWhite, AppColors.primary],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? AppColors.textWhite.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(
                color: isDark ? AppColors.textWhite : AppColors.draw,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: 'Search players...',
                hintStyle: TextStyle(
                  color: isDark ? AppColors.textWhite50 : AppColors.draw,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppColors.primaryLight,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color:
                              isDark ? AppColors.textWhite70 : AppColors.draw,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.2),
                      AppColors.primary.withValues(alpha: 0.2),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryLight,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Loading leaderboard...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textWhite70 : AppColors.draw,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return SliverFillRemaining(child: _buildErrorWidget(isDark));
    }

    if (_entries.isEmpty) {
      return SliverFillRemaining(child: _buildEmptyState(isDark));
    }

    return SliverPadding(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index == _entries.length) {
            return _isLoadingMore
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? AppColors.primaryLight : AppColors.primary,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink();
          }

          final entry = _entries[index];
          return _buildLeaderboardCard(entry, index, isDark);
        }, childCount: _entries.length + (_isLoadingMore ? 1 : 0)),
      ),
    );
  }

  Widget _buildLeaderboardCard(LeaderboardEntry entry, int index, bool isDark) {
    final isTopThree = entry.rank <= 3;
    final rankColor = isTopThree
        ? (entry.rank == 1
            ? AppColors.primary
            : entry.rank == 2
                ? AppColors.primary
                : AppColors.primary)
        : AppColors.primaryLight;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index.clamp(0, 10) * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - value), 0),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColors.primaryLight.withValues(alpha: 0.3),
                    AppColors.primaryLight.withValues(alpha: 0.3),
                  ]
                : entry.isCurrentUser
                    ? [AppColors.primary, AppColors.textWhite]
                    : [AppColors.textWhite, AppColors.primary],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isTopThree
                ? rankColor.withValues(alpha: 0.5)
                : entry.isCurrentUser
                    ? AppColors.primaryLight.withValues(alpha: 0.5)
                    : isDark
                        ? AppColors.textWhite.withValues(alpha: 0.1)
                        : AppColors.primaryLight.withValues(alpha: 0.1),
            width: isTopThree || entry.isCurrentUser ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isTopThree
                  ? rankColor.withValues(alpha: 0.2)
                  : entry.isCurrentUser
                      ? AppColors.primaryLight.withValues(alpha: 0.2)
                      : AppColors.textPrimary.withValues(alpha: 0.05),
              blurRadius: isTopThree || entry.isCurrentUser ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: AppColors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _navigateToProfile(entry.userId),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _buildRankBadge(entry.rank, rankColor, isTopThree, isDark),
                  const SizedBox(width: 10),
                  _buildAvatar(entry, isDark),
                  const SizedBox(width: 10),
                  Expanded(child: _buildUserInfo(entry, isDark)),
                  const SizedBox(width: 6),
                  _buildActionButton(entry, isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRankBadge(int rank, Color color, bool isTopThree, bool isDark) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          gradient: isTopThree
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, color.withValues(alpha: 0.7)],
                )
              : null,
          color: isTopThree
              ? null
              : isDark
                  ? AppColors.textWhite.withValues(alpha: 0.05)
                  : AppColors.primary,
          shape: BoxShape.circle,
          border: Border.all(
            color: isTopThree
                ? AppColors.textWhite.withValues(alpha: 0.3)
                : AppColors.transparent,
            width: 2,
          ),
          boxShadow: isTopThree
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: isTopThree
              ? Icon(Icons.emoji_events_rounded,
                  color: AppColors.textWhite, size: 22)
              : Text(
                  '#$rank',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textWhite70 : AppColors.draw,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildAvatar(LeaderboardEntry entry, bool isDark) {
    return Stack(
      children: [
        Hero(
          tag: 'avatar_${entry.userId}',
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryLight, AppColors.primaryLight],
              ),
              border: Border.all(color: AppColors.textWhite, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: entry.avatarUrl != null && entry.avatarUrl!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        entry.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text(
                              entry.username[0].toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.textWhite,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : Center(
                      child: Text(
                        entry.username[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
          ),
        ),
        if (entry.isOnline && !entry.isCurrentUser)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.victory,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.textWhite, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.victory.withValues(alpha: 0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUserInfo(LeaderboardEntry entry, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                entry.username,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: entry.isCurrentUser
                      ? AppColors.primaryLight
                      : isDark
                          ? AppColors.textWhite
                          : AppColors.draw,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            if (entry.isCurrentUser) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryLight, AppColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'YOU',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.winHighlight, AppColors.winHighlight],
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: 11,
                    color: AppColors.winHighlight,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${entry.rating}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.winHighlight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                '${entry.wins}W ${entry.losses}L ${entry.draws}D',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textWhite70 : AppColors.draw,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _buildWinRateBar(entry.winRate, isDark),
      ],
    );
  }

  Widget _buildWinRateBar(double winRate, bool isDark) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.textWhite.withValues(alpha: 0.1)
                  : AppColors.draw,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (winRate / 100).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primary],
                  ),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${winRate.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textWhite70 : AppColors.draw,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(LeaderboardEntry entry, bool isDark) {
    if (entry.isCurrentUser) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryLight, AppColors.primaryLight],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.person_rounded, size: 14, color: AppColors.textWhite),
            SizedBox(width: 3),
            Text(
              'You',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textWhite,
              ),
            ),
          ],
        ),
      );
    } else if (entry.isFriend) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.people_rounded, size: 14, color: AppColors.textWhite),
            SizedBox(width: 3),
            Text(
              'Friends',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textWhite,
              ),
            ),
          ],
        ),
      );
    } else if (entry.hasPendingRequest) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.winHighlight, AppColors.winHighlight],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.schedule_rounded, size: 14, color: AppColors.textWhite),
            SizedBox(width: 3),
            Text(
              'Sent',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textWhite,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.primaryLight.withValues(alpha: 0.3),
          ),
        ),
        child: IconButton(
          icon: const Icon(Icons.person_add_rounded, size: 18),
          color: AppColors.primaryLight,
          onPressed: () => _sendFriendRequest(entry.username),
          tooltip: 'Add friend',
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(),
        ),
      );
    }
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.primary.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.leaderboard_outlined,
                size: 80,
                color: isDark ? AppColors.primaryLight : AppColors.primaryLight,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _currentSearch.isNotEmpty ? 'No results found' : 'No data yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textWhite : AppColors.draw,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _currentSearch.isNotEmpty
                  ? 'Try searching for something else'
                  : 'Play a game to appear on the leaderboard!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textWhite70 : AppColors.draw,
                height: 1.5,
              ),
            ),
          ],
        ),
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
              onPressed: () => _loadData(isRefresh: true),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB(bool isDark) {
    return ScaleTransition(
      scale: _fabAnimation,
      child: FloatingActionButton(
        onPressed: () {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
          );
        },
        backgroundColor: AppColors.primaryLight,
        elevation: 8,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryLight, AppColors.primaryLight],
            ),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.arrow_upward_rounded, color: AppColors.textWhite),
          ),
        ),
      ),
    );
  }
}

// Custom delegate for search bar
class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SearchBarDelegate({required this.child});

  @override
  double get minExtent => 80;

  @override
  double get maxExtent => 80;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox(height: maxExtent, child: child);
  }

  @override
  bool shouldRebuild(_SearchBarDelegate oldDelegate) {
    return false;
  }
}
