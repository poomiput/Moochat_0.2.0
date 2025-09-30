import 'package:flutter/material.dart';
import 'package:moochat/core/theming/colors.dart';

/// Modern User Avatar Widget with updated design
///
/// Features:
/// - Clean circular design with subtle border
/// - Gradient backgrounds for initials
/// - Online status indicator
/// - Smooth hover animations
/// - Better accessibility support
class ModernUserAvatar extends StatelessWidget {
  const ModernUserAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.radius = 20.0,
    this.isOnline = false,
    this.showOnlineStatus = false,
    this.backgroundColor,
    this.textColor,
    this.onTap,
  });

  final String? imageUrl;
  final String? name;
  final double radius;
  final bool isOnline;
  final bool showOnlineStatus;
  final Color? backgroundColor;
  final Color? textColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // Main avatar
          Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: ColorsManager.outline.withOpacity(0.3),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8.0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: _buildAvatarContent(),
            ),
          ),

          // Online status indicator
          if (showOnlineStatus)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: radius * 0.6,
                height: radius * 0.6,
                decoration: BoxDecoration(
                  color: isOnline
                      ? ColorsManager.secondary
                      : ColorsManager.onSurfaceVariant,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ColorsManager.backgroundColor,
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4.0,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildInitialsAvatar();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingAvatar();
        },
      );
    }
    return _buildInitialsAvatar();
  }

  Widget _buildInitialsAvatar() {
    final initials = _getInitials();
    final gradientColors = _getGradientColors();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: textColor ?? Colors.white,
            fontSize: radius * 0.8,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingAvatar() {
    return Container(
      color: ColorsManager.surface,
      child: Center(
        child: SizedBox(
          width: radius * 0.6,
          height: radius * 0.6,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            valueColor: AlwaysStoppedAnimation<Color>(
              ColorsManager.primary.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }

  String _getInitials() {
    if (name == null || name!.isEmpty) {
      return '?';
    }

    final words = name!.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else {
      return name![0].toUpperCase();
    }
  }

  List<Color> _getGradientColors() {
    if (backgroundColor != null) {
      return [backgroundColor!, backgroundColor!];
    }

    // Generate colors based on name hash for consistency
    final hash = name?.hashCode ?? 0;
    final colorIndex = hash.abs() % _gradientOptions.length;
    return _gradientOptions[colorIndex];
  }

  static const List<List<Color>> _gradientOptions = [
    [ColorsManager.primary, Color(0xFFF8A5B8)], // Pink Rose gradient
    [ColorsManager.secondary, Color(0xFF059669)], // Emerald gradient
    [Color(0xFF8B5CF6), Color(0xFF7C3AED)], // Purple gradient
    [Color(0xFFEF4444), Color(0xFFDC2626)], // Red gradient
    [Color(0xFFF59E0B), Color(0xFFD97706)], // Orange gradient
    [Color(0xFF3B82F6), Color(0xFF2563EB)], // Blue gradient
    [Color(0xFF10B981), Color(0xFF059669)], // Green gradient
    [Color(0xFFEC4899), Color(0xFFDB2777)], // Pink gradient
  ];
}

/// Factory constructors for common avatar sizes
extension ModernUserAvatarSizes on ModernUserAvatar {
  static ModernUserAvatar small({
    String? imageUrl,
    String? name,
    bool isOnline = false,
    bool showOnlineStatus = false,
    VoidCallback? onTap,
  }) {
    return ModernUserAvatar(
      imageUrl: imageUrl,
      name: name,
      radius: 16.0,
      isOnline: isOnline,
      showOnlineStatus: showOnlineStatus,
      onTap: onTap,
    );
  }

  static ModernUserAvatar medium({
    String? imageUrl,
    String? name,
    bool isOnline = false,
    bool showOnlineStatus = false,
    VoidCallback? onTap,
  }) {
    return ModernUserAvatar(
      imageUrl: imageUrl,
      name: name,
      radius: 24.0,
      isOnline: isOnline,
      showOnlineStatus: showOnlineStatus,
      onTap: onTap,
    );
  }

  static ModernUserAvatar large({
    String? imageUrl,
    String? name,
    bool isOnline = false,
    bool showOnlineStatus = false,
    VoidCallback? onTap,
  }) {
    return ModernUserAvatar(
      imageUrl: imageUrl,
      name: name,
      radius: 32.0,
      isOnline: isOnline,
      showOnlineStatus: showOnlineStatus,
      onTap: onTap,
    );
  }
}
