import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/match_history_model.dart';
import '../../../../services/local_storage_service.dart';
import '../../../widgets/bouncing_game_button.dart';
import '../../../widgets/custom_sliver_app_bar.dart';
import '../../../widgets/game_glow_scaffold.dart';

class MatchHistoryScreen extends StatefulWidget {
  final int? userId;

  const MatchHistoryScreen({super.key, this.userId});

  @override
  State<MatchHistoryScreen> createState() => _MatchHistoryScreenState();
}

class _MatchHistoryScreenState extends State<MatchHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<MatchHistoryItem> _matches = [];
  bool _isLoading = false;
  String? _currentResultFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadMatches();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      switch (_tabController.index) {
        case 0:
          _currentResultFilter = null;
          break;
        case 1:
          _currentResultFilter = 'win';
          break;
        case 2:
          _currentResultFilter = 'loss';
          break;
        case 3:
          _currentResultFilter = 'draw';
          break;
      }
    });
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() => _isLoading = true);
    try {
      final matches =
          await LocalStorageService.getMatches(result: _currentResultFilter);
      if (mounted) {
        setState(() {
          _matches = matches;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: GameGlowScaffold(
        topGlowColor: AppColors.bgGlowPurple,
        bottomGlowColor: AppColors.bgGlowBlue,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            CustomSliverAppBar(
              title: 'Match History',
              icon: Icons.history_rounded,
              backgroundIcon: Icons.military_tech_rounded,
              expandedHeight: 160,
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.winHighlight,
                indicatorWeight: 3,
                labelColor: AppColors.textWhite,
                unselectedLabelColor: AppColors.textWhite70,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Wins'),
                  Tab(text: 'Losses'),
                  Tab(text: 'Draws'),
                ],
              ),
            ),
          ],
          body: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(AppColors.primary),
                  ),
                )
              : _matches.isEmpty
                  ? _buildEmptyState()
                  : _buildMatchesList(),
        ),
      ),
      // bottomNavigationBar: const CustomBottomNav(currentIndex: 1),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
            child: Icon(
              Icons.sports_esports_rounded,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Matches Recorded',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Play matches with Bot or 2-Players to build your record',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _matches.length,
      itemBuilder: (context, index) {
        final match = _matches[index];
        final bool isWin = match.result == 'win';
        final bool isDraw = match.result == 'draw';

        final Color statusColor = isDraw
            ? AppColors.draw
            : (isWin ? AppColors.victory : AppColors.defeat);

        final String resultText =
            isDraw ? 'DRAW' : (isWin ? 'VICTORY' : 'DEFEAT');

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowSubtle,
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              onTap: () => _showMatchDetailCard(context, match),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor.withValues(alpha: 0.1),
                  border: Border.all(color: statusColor, width: 2),
                ),
                child: Center(
                  child: Text(
                    match.mySymbol,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: statusColor,
                    ),
                  ),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      match.opponentUsername,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      resultText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        match.gameName,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMM d, h:mm a').format(match.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              trailing: Icon(
                Icons.info_outline_rounded,
                color: AppColors.textMuted,
                size: 20,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMatchDetailCard(BuildContext context, MatchHistoryItem match) {
    HapticFeedback.lightImpact();
    final bool isWin = match.result == 'win';
    final bool isDraw = match.result == 'draw';
    final Color statusColor = isDraw
        ? AppColors.draw
        : (isWin ? AppColors.victory : AppColors.defeat);
    final String resultText = isDraw ? 'DRAW' : (isWin ? 'VICTORY' : 'DEFEAT');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppColors.border, width: 1.5),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Symbol Avatar with status glow
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor.withValues(alpha: 0.12),
                    border: Border.all(color: statusColor, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      match.mySymbol,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Outcome Pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    resultText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  match.opponentUsername,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  match.gameName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),

                // Match Details Container Card
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        Icons.grid_4x4_rounded,
                        'Board Size',
                        '${match.boardRows} × ${match.boardCols} (5-streak)',
                      ),
                      Divider(color: AppColors.border, height: 18),
                      _buildDetailRow(
                        Icons.touch_app_rounded,
                        'Total Moves',
                        '${match.totalMoves} moves',
                      ),
                      if (match.durationSeconds != null &&
                          match.durationSeconds! > 0) ...[
                        Divider(color: AppColors.border, height: 18),
                        _buildDetailRow(
                          Icons.timer_rounded,
                          'Duration',
                          '${match.durationSeconds}s',
                        ),
                      ],
                      Divider(color: AppColors.border, height: 18),
                      _buildDetailRow(
                        Icons.calendar_today_rounded,
                        'Played On',
                        DateFormat('MMM d, h:mm a').format(match.createdAt),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Full-width Close Button
                BouncingGameButton(
                  width: double.infinity,
                  height: 48,
                  backgroundColor: AppColors.primary,
                  bevelColor: AppColors.buttonBevel,
                  onPressed: () => Navigator.pop(context),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_rounded,
                        color: AppColors.textWhite,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'CLOSE',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textWhite,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
