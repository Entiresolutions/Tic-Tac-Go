import 'package:flutter/material.dart';
import '../../../../models/room_model.dart';
import '../../../../services/room_service.dart';
import 'room_waiting_screen.dart';
import '../../../../core/theme/app_colors.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roomNameController = TextEditingController();
  final _passwordController = TextEditingController();

  int _maxPlayers = 2;
  int _boardRows = 15;
  int _boardCols = 19;
  int _winLen = 5;
  bool _isPublic = true;
  bool _hasPassword = false;
  bool _isCreating = false;

  @override
  void dispose() {
    _roomNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final request = CreateRoomRequest(
        roomName: _roomNameController.text.trim(),
        password: _hasPassword ? _passwordController.text.trim() : null,
        maxPlayers: _maxPlayers,
        boardRows: _boardRows,
        boardCols: _boardCols,
        winLen: _winLen,
        isPublic: _isPublic,
      );

      final roomDetail = await RoomService.createRoom(request);

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.textWhite),
              const SizedBox(width: 12),
              Expanded(child: Text('Room created: ${roomDetail.roomCode}')),
            ],
          ),
          backgroundColor: AppColors.victory,
          duration: const Duration(seconds: 2),
        ),
      );

      // Close the room creation screen and navigate to the waiting screen.
      navigator.pop(); // Close CreateRoomScreen.
      navigator.push(
        MaterialPageRoute(
          builder: (context) => RoomWaitingScreen(roomDetail: roomDetail),
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.textWhite),
              const SizedBox(width: 12),
              Expanded(child: Text(e.toString())),
            ],
          ),
          backgroundColor: AppColors.defeat,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.draw,
      appBar: AppBar(
        title:         const Text('Create New Room'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Room Name
            _buildSectionTitle('Room Information', Icons.info_outline),
            const SizedBox(height: 12),
            _buildCard(
              child: Column(
                children: [
                  TextFormField(
                    controller: _roomNameController,
                    decoration: InputDecoration(
                      labelText: 'Room Name *',
                      hintText: 'Enter a room name',
                      prefixIcon: const Icon(Icons.meeting_room_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a room name';
                      }
                      if (value.trim().length > 100) {
                        return 'Room names can be up to 100 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Is Public
                  SwitchListTile(
                    value: _isPublic,
                    onChanged: (value) => setState(() => _isPublic = value),
                    title: const Text('Public Room'),
                    subtitle: const Text(
                      'Show in the room list',
                      style: TextStyle(fontSize: 12),
                    ),
                    secondary: Icon(
                      _isPublic ? Icons.public : Icons.lock_outline,
                      color: AppColors.primary,
                    ),
                  ),
                  // Has Password
                  SwitchListTile(
                    value: _hasPassword,
                    onChanged: (value) => setState(() => _hasPassword = value),
                    title: const Text('Set Password'),
                    subtitle: const Text(
                      'Require a password to join',
                      style: TextStyle(fontSize: 12),
                    ),
                    secondary: Icon(
                      Icons.lock_rounded,
                      color: AppColors.winHighlight,
                    ),
                  ),
                  if (_hasPassword) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password *',
                        hintText: 'Enter a password',
                        prefixIcon: const Icon(Icons.key_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (_hasPassword && (value == null || value.isEmpty)) {
                          return 'Please enter a password';
                        }
                        if (_hasPassword && value!.length > 50) {
                          return 'Passwords can be up to 50 characters';
                        }
                        return null;
                      },
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Game Settings
            _buildSectionTitle('Game Settings', Icons.settings_rounded),
            const SizedBox(height: 12),
            _buildCard(
              child: Column(
                children: [
                  // Max Players
                  _buildSliderOption(
                    title: 'Number of Players',
                    value: _maxPlayers.toDouble(),
                    min: 2,
                    max: 4,
                    divisions: 2,
                    label: '$_maxPlayers players',
                    icon: Icons.people_rounded,
                    color: AppColors.victory,
                    onChanged: (value) =>
                        setState(() => _maxPlayers = value.toInt()),
                  ),
                  const Divider(height: 32),
                  // Board Rows
                  _buildSliderOption(
                    title: 'Rows',
                    value: _boardRows.toDouble(),
                    min: 10,
                    max: 20,
                    divisions: 10,
                    label: '$_boardRows rows',
                    icon: Icons.view_headline_rounded,
                    color: AppColors.primary,
                    onChanged: (value) =>
                        setState(() => _boardRows = value.toInt()),
                  ),
                  const Divider(height: 32),
                  // Board Cols
                  _buildSliderOption(
                    title: 'Columns',
                    value: _boardCols.toDouble(),
                    min: 10,
                    max: 25,
                    divisions: 15,
                    label: '$_boardCols columns',
                    icon: Icons.view_week_rounded,
                    color: AppColors.primary,
                    onChanged: (value) =>
                        setState(() => _boardCols = value.toInt()),
                  ),
                  const Divider(height: 32),
                  // Win Length
                  _buildSliderOption(
                    title: 'Pieces to Win',
                    value: _winLen.toDouble(),
                    min: 3,
                    max: 7,
                    divisions: 4,
                    label: '$_winLen pieces',
                    icon: Icons.emoji_events_rounded,
                    color: AppColors.winHighlight,
                    onChanged: (value) =>
                        setState(() => _winLen = value.toInt()),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Preview
            _buildSectionTitle('Preview', Icons.preview_rounded),
            const SizedBox(height: 12),
            _buildCard(
              child: Column(
                children: [
                  _buildPreviewRow(
                    'Board',
                    '$_boardRows × $_boardCols',
                    Icons.grid_4x4_rounded,
                  ),
                  const Divider(height: 20),
                  _buildPreviewRow(
                    'Win Condition',
                    '$_winLen in a row',
                    Icons.flag_rounded,
                  ),
                  const Divider(height: 20),
                  _buildPreviewRow(
                    'Players',
                    '$_maxPlayers players',
                    Icons.people_rounded,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Create Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isCreating ? null : _createRoom,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textWhite,
                  disabledBackgroundColor: AppColors.draw,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isCreating
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textWhite,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_rounded, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'CREATE ROOM',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.draw),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.draw,
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: child,
    );
  }

  Widget _buildSliderOption({
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required IconData icon,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.draw,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: label,
          activeColor: color,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildPreviewRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: AppColors.draw),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.draw,
          ),
        ),
      ],
    );
  }
}
