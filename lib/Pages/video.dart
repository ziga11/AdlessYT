import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class VideoPage extends StatefulWidget {
  final List<Video> videos;
  const VideoPage({super.key, required this.videos});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [],
    );
  }
}