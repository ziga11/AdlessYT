import 'package:adless_youtube/Utils/video_provider.dart';
import 'package:flutter/material.dart';
import 'package:adless_youtube/Pages/channel.dart';
import 'package:adless_youtube/Pages/library.dart';
import 'package:adless_youtube/Pages/login.dart';
import 'package:adless_youtube/Pages/search.dart';
import 'package:adless_youtube/Utils/globals.dart';
import 'package:adless_youtube/Utils/theme.dart';
import 'package:provider/provider.dart';

class NavPage extends StatefulWidget {
  static const String settings = '/nav';
  const NavPage({super.key});
  @override
  State<NavPage> createState() => _NavPageState();
}

class _NavPageState extends State<NavPage> with AutomaticKeepAliveClientMixin {
  int _selectedIndex = 0;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  bool get wantKeepAlive => true;

  Future<void> _onItemTapped(
      int index, VideoPlayerProvider videoProvider) async {
    if (_selectedIndex == index) return;
    videoProvider.setMainPage(false);
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        _navigatorKey.currentState?.pushReplacementNamed(SearchPage.settings);
        break;
      case 1:
        _navigatorKey.currentState?.pushReplacementNamed(Downloaded.settings);
        break;
      case 2:
        if (Globals.googleUser != null) {
          _navigatorKey.currentState
              ?.pushReplacementNamed(ChannelPage.settings);
        } else {
          await _navigatorKey.currentState
              ?.pushReplacementNamed(GoogleLogin.settings);
          setState(() {});
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var videoProvider = context.read<VideoPlayerProvider>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, result) async {
        if (didPop) {
          return;
        }

        final isFirstRouteInCurrentTab =
            !await _navigatorKey.currentState!.maybePop();

        if (isFirstRouteInCurrentTab) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: YTTheme.darkGray,
        body: ValueListenableBuilder(
            valueListenable: videoProvider.mainPage,
            builder: (context, mainPage, _) {
              return Stack(
                children: [
                  Positioned.fill(
                    child: Offstage(
                      offstage: mainPage != null && mainPage,
                      child: Navigator(
                        key: _navigatorKey,
                        initialRoute: SearchPage.settings,
                        onGenerateRoute: (RouteSettings settings) {
                          WidgetBuilder builder;
                          switch (videoProvider.lastRoute ?? settings.name) {
                            case SearchPage.settings:
                              builder = (_) => const SearchPage();
                              break;
                            case Downloaded.settings:
                              builder = (_) => const Downloaded();
                              break;
                            case ChannelPage.settings:
                              builder = (_) => Globals.googleUser != null
                                  ? const ChannelPage()
                                  : const SearchPage();
                              break;
                            case GoogleLogin.settings:
                              builder = (_) => const GoogleLogin();
                              break;
                            default:
                              builder = (_) => const SearchPage();
                          }
                          return MaterialPageRoute(
                            builder: builder,
                            settings: settings,
                          );
                        },
                      ),
                    ),
                  ),
                  if (videoProvider.mainPage.value != null)
                    Positioned(
                      bottom: mainPage == null || !mainPage ? 0 : null,
                      top: mainPage == true ? 0 : null,
                      left: 0,
                      right: 0,
                      height: mainPage == true
                          ? Globals.size(context).height
                          : Globals.size(context).height * 0.2,
                      child: GestureDetector(
                        onTap: () {
                          // Expand to full video view
                          videoProvider.mainPage.value = true;
                        },
                        child: videoProvider.videoPage,
                      ),
                    ),
                ],
              );
            }),
        bottomNavigationBar: Container(
          color: YTTheme.darkGray.withOpacity(0.9),
          child: Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => _onItemTapped(0, videoProvider),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search,
                        color:
                            _selectedIndex == 0 ? YTTheme.orange : YTTheme.blue,
                      ),
                      Text(
                        "Search",
                        style: TextStyle(
                          color: _selectedIndex == 0
                              ? YTTheme.orange
                              : YTTheme.blue,
                        ),
                      )
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () => _onItemTapped(1, videoProvider),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.library_music,
                        color:
                            _selectedIndex == 1 ? YTTheme.orange : YTTheme.blue,
                      ),
                      Text(
                        "Library",
                        style: TextStyle(
                          color: _selectedIndex == 1
                              ? YTTheme.orange
                              : YTTheme.blue,
                        ),
                      )
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () => _onItemTapped(2, videoProvider),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Globals.googleUser != null
                            ? Icons.library_music
                            : Icons.login_rounded,
                        color:
                            _selectedIndex == 2 ? YTTheme.orange : YTTheme.blue,
                      ),
                      Text(
                        Globals.googleUser != null ? "Channel" : "Login",
                        style: TextStyle(
                          color: _selectedIndex == 2
                              ? YTTheme.orange
                              : YTTheme.blue,
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
