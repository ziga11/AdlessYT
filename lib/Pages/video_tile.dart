import 'package:adless_youtube/Utils/globals.dart';
import 'package:adless_youtube/Utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class VideoListTile extends StatelessWidget {
  final Video video;
  final VoidCallback? onTap;

  const VideoListTile({
    super.key,
    required this.video,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: Colors.blue,
      leading: SizedBox(
        width: Globals.size(context).width / 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Image.network(
                video.thumbnails.mediumResUrl,
                width: 120,
                height: 70,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
                right: 0,
                bottom: 0,
                child: Text(
                  _formatDuration(video.duration),
                  style: TextStyle(color: YTTheme.white),
                ))
          ],
        ),
      ),
      title: Text(
        video.title,
        style: TextStyle(color: YTTheme.white),
      ),
      subtitle: Text(
        '${video.engagement.viewCount} views',
      ),
      onTap: onTap,
    );
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
