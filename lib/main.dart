import 'package:adless_youtube/Pages/video_player.dart';
import 'package:adless_youtube/Utils/video_provider.dart';
import 'package:flutter/material.dart';
import 'package:adless_youtube/Pages/channel.dart';
import 'package:adless_youtube/Pages/library.dart';
import 'package:adless_youtube/Pages/nav_page.dart';
import 'package:adless_youtube/Pages/search.dart';
import 'package:adless_youtube/Utils/globals.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(ChangeNotifierProvider<VideoPlayerProvider>(
      create: (context) => VideoPlayerProvider(),
      child: MaterialApp(
        initialRoute: NavPage.settings,
        routes: {
          NavPage.settings: (context) => const NavPage(),
          SearchPage.settings: (context) => const SearchPage(),
          Downloaded.settings: (context) => const Downloaded(),
          VideoPage.settings: (context) => const VideoPage(),
          ChannelPage.settings: (context) {
            if (Globals.channel != null) {
              return const ChannelPage();
            }
            return const SearchPage();
          },
        },
        home: const NavPage(),
      )));
}
