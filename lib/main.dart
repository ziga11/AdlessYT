import 'package:flutter/material.dart';
import 'package:adless_youtube/Pages/channel.dart';
import 'package:adless_youtube/Pages/downloaded.dart';
import 'package:adless_youtube/Pages/nav_page.dart';
import 'package:adless_youtube/Pages/search.dart';
import 'package:adless_youtube/Utils/globals.dart';

void main() {
  runApp(MaterialApp(
    initialRoute: NavPage.settings,
    routes: {
      NavPage.settings: (context) => const NavPage(),
      SearchPage.settings: (context) => const SearchPage(),
      Downloaded.settings: (context) => const Downloaded(),
      ChannelPage.settings: (context) {
        if (Globals.channel != null) {
          return const ChannelPage();
        }
        return const SearchPage();
      }
    },
    home: const NavPage(),
  ));
}
