import 'package:flutter/material.dart';
import '../../data/models/feed_model.dart';
import 'video_player_widget.dart';

class FeedCard extends StatelessWidget {
  final FeedModel feed;
  final bool isActive;
  final VoidCallback onPlay;

  const FeedCard({
    super.key,
    required this.feed,
    required this.isActive,
    required this.onPlay,
  });

  String _timeAgo(String? dateString) {
    if (dateString == null) return '';
    final date = DateTime.tryParse(dateString);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 30) return '${diff.inDays ~/ 30} months ago';
    if (diff.inDays > 0) return '${diff.inDays} days ago';
    if (diff.inHours > 0) return '${diff.inHours} hours ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} minutes ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildUserRow(),
        const SizedBox(height: 10),
        VideoPlayerWidget(
          videoUrl: feed.videoUrl,
          thumbnailUrl: feed.thumbnailUrl,
          isActive: isActive,
          onPlay: onPlay,
        ),
        if (feed.description != null && feed.description!.isNotEmpty)
          _buildDescription(),
      ],
    );
  }

  Widget _buildUserRow() {
    final user = feed.user;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF2E2E2E),
            backgroundImage: user?.profileImage != null
                ? NetworkImage(user!.profileImage!)
                : null,
            child: user?.profileImage == null
                ? const Icon(Icons.person, color: Colors.white54, size: 20)
                : null,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.name ?? 'Unknown',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (feed.createdAt != null)
                Text(
                  _timeAgo(feed.createdAt),
                  style: const TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Text(
        feed.description!,
        style: const TextStyle(
          color: Color(0xFFCCCCCC),
          fontSize: 13,
          height: 1.5,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
