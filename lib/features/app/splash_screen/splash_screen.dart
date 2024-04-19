import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase/features/user_auth/presentation/pages/login_page.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  final Widget? child;
  const SplashScreen({super.key, this.child});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    Future.delayed(Duration(milliseconds: 2700), () {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => widget.child!),
          (route) => false);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      splash: Column(
        children: [
          Center(
            child: Lottie.asset("assets/Lottie/Fox.json"),
          ),
          Text("PANSIM SMARTFOX",
              style: TextStyle(
                color: Colors.green.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 30,
              ))
        ],
      ),
      nextScreen: const LoginPage(),
      splashIconSize: 400,
      backgroundColor: Colors.white,
    );
    // child: Text(
    //   "PANSIM HOME AUTOMATION ",
    //   style: TextStyle(
    //     color: Colors.green.shade600,
    //     fontWeight: FontWeight.bold,
    //     fontSize: 20,
    //   ),
    // ),
  }
}
