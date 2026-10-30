import 'package:flutter/material.dart';
import 'package:tic_tac_go/services/friend_service.dart';
import 'package:tic_tac_go/models/friend_model.dart';
import 'package:tic_tac_go/ui/screens/caro/profile/user_profile_screen.dart';
import 'package:tic_tac_go/ui/widgets/custom_sliver_app_bar.dart';
import '../../../../core/theme/app_colors.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  List<FriendUser> _friends = [];
  List<FriendRequest> _receivedRequests = [];
  List<FriendRequest> _sentRequests = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    _fabAnimationController.forward();
    _loadData();
  }

  void _onTabChanged() {
    // Don't reload data on every tab change
    // Data is already loaded in initState and refreshed after actions
    // if (!_tabController.indexIsChanging) {
    //   _loadData();
    // }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    // Don't show loading for refresh, only for initial load
    if (_friends.isEmpty &&
        _receivedRequests.isEmpty &&
        _sentRequests.isEmpty) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final localFriends = [
        FriendUser(
          id: 101,
          username: "Friend 1",
          rating: 1200,
          isFriend: true,
          isOnline: true,
        ),
        FriendUser(
          id: 102,
          username: "CaroBuddy",
          rating: 1350,
          isFriend: true,
          isOnline: false,
        ),
      ];

      if (mounted) {
        setState(() {
          _friends = localFriends;
          _receivedRequests = [];
          _sentRequests = [];
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

  Future<void> _removeFriend(FriendUser friend) async {
    // Save context before async gap
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Show loading
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.textWhite,
              ),
            ),
            SizedBox(width: 12),
            Text('Processing...'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      // Use friendshipId if available, otherwise fallback to id
      final idToRemove = friend.friendshipId ?? friend.id;
      await FriendService.removeFriend(idToRemove);

      // Hide loading first
      scaffoldMessenger.hideCurrentSnackBar();

      // Refresh data silently
      if (mounted) {
        await _loadData();
      }

      // Show success after data is refreshed
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.textWhite),
              SizedBox(width: 12),
              Text('Friend removed'),
            ],
          ),
          backgroundColor: AppColors.victory,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Hide loading and show error
      scaffoldMessenger.hideCurrentSnackBar();
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
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _respondToRequest(int requestId, String action) async {
    // Save context before async gap
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Show loading
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.textWhite,
              ),
            ),
            SizedBox(width: 12),
            Text('Processing...'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      await FriendService.respondToRequest(requestId, action);

      // Hide loading first
      scaffoldMessenger.hideCurrentSnackBar();

      // Refresh data silently
      if (mounted) {
        await _loadData();

        // Auto switch to friends tab if accepted
        if (action == 'accept' && _tabController.index != 0) {
          _tabController.animateTo(0);
        }
      }

      // Show success after data is refreshed
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.textWhite),
              const SizedBox(width: 12),
              Text(
                action == 'accept'
                    ? 'Invitation accepted'
                    : 'Invitation declined',
              ),
            ],
          ),
          backgroundColor: AppColors.victory,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Hide loading and show error
      scaffoldMessenger.hideCurrentSnackBar();
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
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _cancelRequest(int requestId) async {
    // Save context before async gap
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Show loading
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.textWhite,
              ),
            ),
            SizedBox(width: 12),
            Text('Processing...'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      await FriendService.cancelFriendRequest(requestId);

      // Hide loading first
      scaffoldMessenger.hideCurrentSnackBar();

      // Refresh data silently
      if (mounted) {
        await _loadData();
      }

      // Show success after data is refreshed
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.textWhite),
              SizedBox(width: 12),
              Text('Invitation canceled'),
            ],
          ),
          backgroundColor: AppColors.victory,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Hide loading and show error
      scaffoldMessenger.hideCurrentSnackBar();
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
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => _SearchUserDialog(onRequestSent: _loadData),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.draw,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            CustomSliverAppBar(
              title: 'Friends',
              icon: Icons.people_rounded,
              backgroundIcon: Icons.people_rounded,
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.draw,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  tabs: [
                    Tab(
                      child: _buildTabWithBadge(
                        'Friends',
                        Icons.people_rounded,
                        _friends.length,
                        false, // Show grey badge (not red notification)
                      ),
                    ),
                    Tab(
                      child: _buildTabWithBadge(
                        'Invites',
                        Icons.mail_rounded,
                        _receivedRequests.length,
                        true, // Show red badge (notification)
                      ),
                    ),
                    Tab(
                      child: _buildTabWithBadge(
                        'Sent',
                        Icons.send_rounded,
                        _sentRequests.length,
                        true, // Show red badge (notification)
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorWidget()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildFriendsList(),
                      _buildReceivedRequestsList(),
                      _buildSentRequestsList(),
                    ],
                  ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: _showSearchDialog,
          backgroundColor: AppColors.primary,
          elevation: 4,
          icon:
              const Icon(Icons.person_add_rounded, color: AppColors.textWhite),
          label: const Text(
            'Add Friend',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.textWhite),
          ),
        ),
      ),
      // bottomNavigationBar: CustomBottomNav(currentIndex: 1),
    );
  }

  Widget _buildTabWithBadge(
    String text,
    IconData icon,
    int count,
    bool showBadge,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 6),
        Text(text),
        if (count > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: showBadge ? AppColors.defeat : AppColors.draw,
              borderRadius: BorderRadius.circular(10),
            ),
            constraints: const BoxConstraints(minWidth: 20),
            child: Text(
              '$count',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: AppColors.defeat),
          const SizedBox(height: 16),
          Text(
            'An error occurred',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.draw,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.draw),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textWhite,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
    if (_friends.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline_rounded,
        title: 'No friends yet',
        subtitle: 'Add friends to start connecting!',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _friends.length,
        itemBuilder: (context, index) {
          final friend = _friends[index];
          return _buildAnimatedListItem(
            index: index,
            child: _buildFriendCard(friend),
          );
        },
      ),
    );
  }

  Widget _buildFriendCard(FriendUser friend) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.textWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Navigate to friend profile
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserProfileScreen(userId: friend.id),
              ),
            ).then((_) {
              // Refresh when coming back
              _loadData();
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar with online status
                Stack(
                  children: [
                    Hero(
                      tag: 'avatar_${friend.id}',
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary,
                              AppColors.primary,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            friend.username[0].toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.textWhite,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (friend.isOnline == true)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.victory,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.textWhite, width: 2.5),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.username,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.winHighlight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.emoji_events_rounded,
                                  size: 14,
                                  color: AppColors.winHighlight,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${friend.rating}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.winHighlight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (friend.isOnline == true) ...[
                            const SizedBox(width: 8),
                            Text(
                              'Online',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.victory,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Action button
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.draw,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'challenge',
                      child: Row(
                        children: [
                          Icon(
                            Icons.sports_esports_rounded,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          const Text('Challenge'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_rounded,
                            color: AppColors.draw,
                          ),
                          const SizedBox(width: 12),
                          const Text('View Profile'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem<String>(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_remove_rounded,
                            color: AppColors.defeat,
                          ),
                          const SizedBox(width: 12),
                          const Text('Remove Friend'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'remove') {
                      _showRemoveFriendDialog(friend);
                    } else if (value == 'profile') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              UserProfileScreen(userId: friend.id),
                        ),
                      ).then((_) {
                        // Refresh when coming back
                        _loadData();
                      });
                    } else if (value == 'challenge') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'The challenge feature is coming soon!',
                          ),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceivedRequestsList() {
    if (_receivedRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.mail_outline_rounded,
        title: 'No invitations',
        subtitle: 'You have no friend requests.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _receivedRequests.length,
        itemBuilder: (context, index) {
          final request = _receivedRequests[index];
          return _buildAnimatedListItem(
            index: index,
            child: _buildReceivedRequestCard(request),
          );
        },
      ),
    );
  }

  Widget _buildReceivedRequestCard(FriendRequest request) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.textWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.victory, AppColors.victory],
                ),
              ),
              child: Center(
                child: Text(
                  request.senderUsername[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.senderUsername,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: AppColors.draw,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(request.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.draw,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Action buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.victory,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.check_rounded,
                      color: AppColors.victory,
                    ),
                    onPressed: () => _respondToRequest(request.id, 'accept'),
                    tooltip: 'Accept',
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.defeat,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.close_rounded, color: AppColors.defeat),
                    onPressed: () => _respondToRequest(request.id, 'reject'),
                    tooltip: 'Decline',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentRequestsList() {
    if (_sentRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.send_outlined,
        title: 'No sent requests',
        subtitle: 'You have not sent any friend requests.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _sentRequests.length,
        itemBuilder: (context, index) {
          final request = _sentRequests[index];
          return _buildAnimatedListItem(
            index: index,
            child: _buildSentRequestCard(request),
          );
        },
      ),
    );
  }

  Widget _buildSentRequestCard(FriendRequest request) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.textWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.winHighlight, AppColors.winHighlight],
                ),
              ),
              child: Center(
                child: Text(
                  request.receiverUsername[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.receiverUsername,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: AppColors.draw,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(request.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.draw,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Cancel button
            TextButton.icon(
              onPressed: () => _cancelRequest(request.id),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancel'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.defeat,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.draw,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 60, color: AppColors.draw),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.draw,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.draw),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedListItem({required int index, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: child,
    );
  }

  void _showRemoveFriendDialog(FriendUser friend) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: AppColors.winHighlight),
            const SizedBox(width: 12),
            const Text('Remove Friend'),
          ],
        ),
        content: Text(
          'Are you sure you want to remove ${friend.username} from your friends?',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: AppColors.draw),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _removeFriend(friend);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.defeat,
              foregroundColor: AppColors.textWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Confirm'),
          ),
        ],
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

class _SearchUserDialog extends StatefulWidget {
  final VoidCallback onRequestSent;

  const _SearchUserDialog({required this.onRequestSent});

  @override
  State<_SearchUserDialog> createState() => _SearchUserDialogState();
}

class _SearchUserDialogState extends State<_SearchUserDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<FriendUser> _searchResults = [];
  bool _isSearching = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      final results = await FriendService.searchUsers(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSearching = false;
      });
    }
  }

  Future<void> _sendRequest(String username) async {
    // Save context and navigator before async gap
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // Show loading
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.textWhite,
              ),
            ),
            SizedBox(width: 12),
            Text('Sending...'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      await FriendService.sendFriendRequest(username);

      // Hide loading first
      scaffoldMessenger.hideCurrentSnackBar();

      // Refresh parent data
      widget.onRequestSent();

      // Close dialog
      navigator.pop();

      // Show success
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.textWhite),
              SizedBox(width: 12),
              Text('Friend request sent'),
            ],
          ),
          backgroundColor: AppColors.victory,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Hide loading and show error (don't close dialog)
      scaffoldMessenger.hideCurrentSnackBar();
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
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.person_search_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Find Friends',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.draw,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Search field
            Container(
              decoration: BoxDecoration(
                color: AppColors.draw,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.draw),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Enter a username to search...',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.draw,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  suffixIcon: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded,
                          color: AppColors.textWhite),
                      onPressed: _search,
                    ),
                  ),
                ),
                onSubmitted: (_) => _search(),
              ),
            ),
            const SizedBox(height: 20),
            // Results
            if (_isSearching)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 60,
                        color: AppColors.defeat,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'An error occurred',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.draw,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.draw),
                      ),
                    ],
                  ),
                ),
              )
            else if (_searchResults.isEmpty &&
                _searchController.text.isNotEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_off_rounded,
                        size: 60,
                        color: AppColors.draw,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No results found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.draw,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No users found with this username',
                        style: TextStyle(color: AppColors.draw),
                      ),
                    ],
                  ),
                ),
              )
            else if (_searchResults.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.textWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.draw),
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primaryDark,
                                  AppColors.primaryDark,
                                ],
                              ),
                            ),
                            child: Center(
                              child: Text(
                                user.username[0].toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // User info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.username,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.winHighlight,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.emoji_events_rounded,
                                        size: 12,
                                        color: AppColors.winHighlight,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${user.rating}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.winHighlight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Action button
                          if (user.isFriend == true)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.victory,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 12,
                                    color: AppColors.victory,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Friend',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.victory,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (user.hasPendingRequest == true)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.winHighlight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: 12,
                                    color: AppColors.winHighlight,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Sent',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.winHighlight,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ElevatedButton(
                              onPressed: () => _sendRequest(user.username),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.textWhite,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 5,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.person_add_rounded, size: 12),
                                  SizedBox(width: 2),
                                  Text(
                                    'Add',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              )
            else
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.manage_search_rounded,
                        size: 80,
                        color: AppColors.draw,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Start searching',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.draw,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter a username to find new friends',
                        style: TextStyle(color: AppColors.draw),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Custom SliverPersistentHeaderDelegate for TabBar
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: AppColors.textWhite, child: tabBar);
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
