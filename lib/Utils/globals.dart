import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class Globals {
  static GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/youtube.force-ssl',
    ],
  );
  static GoogleSignInAccount? googleUser;
  static Channel? channel;
  static TextEditingController searchController = TextEditingController();
  static YoutubeExplode youtubeExplode = YoutubeExplode();
  static GlobalKey videoKey = GlobalKey();

  static Size size(BuildContext context) {
    return MediaQuery.of(context).size;
  }

  static String formatNumber(int number) {
    if (number >= 1000000000) {
      return '${(number / 1000000000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}B';
    } else if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}K';
    } else {
      return number.toString();
    }
  }

  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours =
        duration.inHours > 0 ? '${twoDigits(duration.inHours)}:' : '';
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours$minutes:$seconds';
  }

  static String formatDateWeekDay(DateTime? date) {
    if (date == null) return "";
    String formattedDate = "${date.day}.${date.month}.${date.year}";
    DateTime now = DateTime.now();
    DateTime startOfToday = DateTime(now.year, now.month, now.day);
    DateTime startOfYesterday = startOfToday.subtract(const Duration(days: 1));

    DateTime startOfWeek =
        startOfToday.subtract(Duration(days: startOfToday.weekday - 1));
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
    if (date.isAfter(startOfYesterday) && date.isBefore(startOfToday)) {
      return "Yesterday";
    } else if (date.isAfter(startOfToday) &&
        date.isBefore(startOfToday.add(const Duration(days: 1)))) {
      return "Today";
    } else if (date.isAfter(startOfWeek) && date.isBefore(endOfWeek)) {
      return DateFormat('EEEE').format(date);
    } else {
      return formattedDate;
    }
  }
}
