import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:utangku_app/screens/home/home_screen.dart';
import 'package:utangku_app/screens/lock/lock_screen.dart';
import 'package:utangku_app/services/auth_service.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      final auth = context.read<AuthService>();
      if (auth.hasPin) {
        auth.lock();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, child) {
        // First time PIN is set → skip lock screen (user just set it in Settings)
        if (auth.hasPin && auth.isLocked && auth.hasUnlockedOnce) {
          return LockScreen(
            mode: LockScreenMode.verify,
            onSuccess: () {
              // unlock triggers notifyListeners → rebuilds without lock screen
            },
          );
        }

        return const HomeScreen();
      },
    );
  }
}
