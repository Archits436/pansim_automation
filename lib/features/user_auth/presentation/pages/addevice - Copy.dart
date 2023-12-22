import 'package:flutter/material.dart';


class Addevice extends StatefulWidget {
  final Widget? child;
  const Addevice({super.key, this.child});

  @override
  State<Addevice> createState() => _AddeviceState();
}

class _AddeviceState extends State<Addevice> {

  @override
  void initState() {
    Future.delayed(
        Duration(seconds: 3),(){
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => widget.child!), (route) => false);
    }
    );
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          "ADD DEVICE ",
          style: TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
