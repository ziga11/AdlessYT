import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:adless_youtube/Utils/globals.dart';
import 'package:adless_youtube/Utils/theme.dart';

class GoogleLogin extends StatefulWidget {
  static const String settings = "/login";
  const GoogleLogin({super.key});
  @override
  GoogleLoginState createState() => GoogleLoginState();
}

class GoogleLoginState extends State<GoogleLogin> {
  Timer? _refreshTimer;
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    Globals.googleSignIn.onCurrentUserChanged
        .listen((GoogleSignInAccount? account) {
      setState(() {
        Globals.googleUser = account;
        if (account != null) {
          _fetchAndStoreAccessToken();
          _setupRefreshTimer();
        }
      });
    });
    try {
      Globals.googleSignIn.signInSilently();
    } catch (e) {
      print(e);
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _setupRefreshTimer() {
    _refreshTimer?.cancel();

    _refreshTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      if (Globals.googleUser != null) {
        _refreshToken();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _refreshToken() async {
    try {
      if (Globals.googleUser != null) {
        final GoogleSignInAuthentication auth =
            await Globals.googleUser!.authentication;
        final String accessToken = auth.accessToken ?? '';

        if (accessToken.isNotEmpty) {
          await storage.write(key: "youtubeToken", value: accessToken);
          print('Access token refreshed successfully');
        }
      }
    } catch (e) {
      print('Error refreshing token: $e');
      try {
        await Globals.googleSignIn.signInSilently();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Silent Sign In Failed, Log in Again")));
        print('Silent sign-in failed: $e');
      }
    }
  }

  Future<void> _handleSignIn() async {
    try {
      final account = await Globals.googleSignIn.signIn();
      if (account != null) {
        await _fetchAndStoreAccessToken();
        _setupRefreshTimer();
      }
    } catch (error) {
      print('Error signing in: $error');
    }
  }

  Future<void> _handleSignOut() async {
    _refreshTimer?.cancel();
    await Globals.googleSignIn.disconnect();
    await storage.delete(key: "youtubeToken");
    setState(() {
      Globals.googleUser = null;
    });
  }

  Future<void> _fetchAndStoreAccessToken() async {
    try {
      if (Globals.googleUser != null) {
        final GoogleSignInAuthentication auth =
            await Globals.googleUser!.authentication;
        final String accessToken = auth.accessToken ?? '';
        if (accessToken.isNotEmpty) {
          await storage.write(key: "youtubeToken", value: accessToken);
          print('Access token stored successfully');
        }
      }
    } catch (e) {
      print('Error fetching access token: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YTTheme.darkGray,
      appBar: AppBar(
        leading: BackButton(
          color: YTTheme.white,
        ),
        backgroundColor: YTTheme.darkGray,
        title: Text(
          'Google Sign-In',
          style: TextStyle(color: YTTheme.white),
        ),
      ),
      body: Center(
        child: Globals.googleUser != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Signed in as ${Globals.googleUser?.displayName}',
                    style: TextStyle(color: YTTheme.white),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _handleSignOut,
                    child: const Text('Sign Out'),
                  ),
                ],
              )
            : ElevatedButton(
                onPressed: () async {
                  await _handleSignIn();
                  if (Globals.googleUser != null) {
                    Navigator.pushNamed(context, '/nav');
                  }
                },
                child: const Text('Sign in with Google'),
              ),
      ),
    );
  }
}
