import 'package:flutter/material.dart';

class Downloaded extends StatefulWidget {
  static const String settings = "/downloaded";
  const Downloaded({super.key});

  @override
  State<Downloaded> createState() => _DownloadedState();
}

class _DownloadedState extends State<Downloaded>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [],
    );
  }

  @override
  bool get wantKeepAlive => true;
}