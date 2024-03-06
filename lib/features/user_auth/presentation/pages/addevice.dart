// ignore_for_file: body_might_complete_normally_catch_error

import 'dart:developer';
import 'dart:io';
import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase/features/user_auth/models/user_model.dart';
import 'package:network_info_plus/network_info_plus.dart';
// import 'package:flutter_firebase/features/user_auth/models/user_model.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import 'package:flutter_firebase/global/common/toast.dart';

void main() => runApp(const MaterialApp(home: Addevice()));

class Addevice extends StatefulWidget {
  const Addevice({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AddeviceState();
}

class _AddeviceState extends State<Addevice> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  final _db = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;
  Box passBox = Hive.box('passBox');

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  String capitalize(String input) {
    return input.isEmpty ? input : input[0].toUpperCase() + input.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(flex: 3, child: _buildQrView(context)),
          Expanded(
            flex: 1,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  _buildResultText(),
                  _buildButtons(),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildResultText() {
    return result != null
        ? Text(
            'Barcode Type: ${describeEnum(result!.format)}   Data: ${result!.code}',
          )
        : const Text('Scan the QR code');
  }

  Widget _buildButtons() {
    return ElevatedButton(
      onPressed: () async {
        // await controller?.toggleFlash();
        // final info = NetworkInfo();
        // final wifiName =
        //     await info.getWifiName().then((value) => {print(value)});
        setState(() {});
      },
      child: FutureBuilder<bool?>(
        future: controller?.getFlashStatus(),
        builder: (context, snapshot) {
          return Text('Flash: ${snapshot.data! ? 'On' : 'Off'}');
        },
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {

    var scanArea = (MediaQuery.of(context).size.width < 300 ||
            MediaQuery.of(context).size.height < 300)
        ? 150.0
        : 150.0;
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
        borderColor: Colors.red,
        borderRadius: 10,
        borderLength: 30,
        borderWidth: 10,
        cutOutSize: scanArea,
      ),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  Future<void> _onQRViewCreated(QRViewController controller) async {
    setState(() {
      this.controller = controller;
    });
    final info = NetworkInfo();
    final wifiName = await info.getWifiName();
    controller.scannedDataStream.listen((scanData) async {
      String macAddress = scanData.code as String;
      print(macAddress);
      
      if (user != null) {
        await storeDeviceInFirebase(UserModel(
          userId: user!.uid,
          macAddress: macAddress,
          status: 'active',
          wifi: wifiName!,
        ));
        print('userId = $user');
        print('macAddress = $macAddress');
      } else {
        print(
            "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
        showToast(message: "User not authenticated.");
      }
    });
  }

  Future<void> storeDeviceInFirebase(UserModel userModel) async {
    try {
      FirebaseAuth auth = FirebaseAuth.instance;
      User? user = auth.currentUser;
      String email = user?.email ?? "";
      String password = passBox.get('pass');
       print(password);
      // String password = await _enterPassword();
      // String credentials = "$email,password";
      final Uri url = Uri.parse('http://192.168.1.16:80/receive-email');
      Map<String, String> headers = {"Content-type": "application/json"};
      String jsonBody = json.encode({"email": email});
      try {
        final response = await http.post(url, headers: headers, body: jsonBody);
        if (response.statusCode == 200) {
          print("Email sent successfully to ESP32");
          showToast(message: "Email sent successfully to ESP32");
        } else {
          print("Failed to send email to ESP32: ${response.statusCode}");
          // showToast(message: "Failed to send email to ESP32");
        }
      } catch (e) {
        print("Error sending request: $e");
        showToast(message: "Failed to send email to ESP32");
      }
      // await http.post(url,
      //     body: email); // Store other details in Firestore as before
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userModel.macAddress.replaceAll('/', '-'))
          .set(userModel.toJson());
      print('userId = ${user?.email}');
      print('Device linked successfully!');
      showToast(message: "Device linked successfully !");
      // Navigate to the home page upon successful linking
      Navigator.pushReplacementNamed(context, '/home');
    } catch (error) {
      print('Error linking device: $error');
      showToast(message: "Error linking device: $error");
      // Rethrow the error to propagate it further.
      rethrow;
    }
  }

  // Future<String> _enterPassword() async {
  //   String? enteredPassword = await showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text('Enter Password'),
  //         content: TextField(
  //           obscureText: true,
  //           decoration: InputDecoration(
  //             labelText: 'Password',
  //           ),
  //           onChanged: (value) {
  //             // You can add validation logic here if needed
  //           },
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //             child: Text('Cancel'),
  //           ),
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //             child: Text('OK'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  //   print(enteredPassword);
  //   return enteredPassword ?? '';
  // }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No camera permission')),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
