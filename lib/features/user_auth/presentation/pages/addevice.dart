// ignore_for_file: body_might_complete_normally_catch_error

import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase/features/user_auth/models/user_model.dart';
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
        await controller?.toggleFlash();
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

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) async {
      String macAddress = scanData.code as String;
      if (user != null) {
        await storeDeviceInFirebase(UserModel(
          email: user!.email!,
          macAddress: macAddress,
          status: 'active',
        ));
        print('userId = $user');
        print('macAddress = $macAddress');
      } else {
        showToast(message: "User not authenticated.");
      }
    });
  }

  Future<void> storeDeviceInFirebase(UserModel userModel) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userModel.macAddress.replaceAll('/', '-'))
          .set(userModel.toJson());
      print('userId = $user!.email');
      print("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
      showToast(message: "Device linked successfully !");
      // Navigate to the home page upon successful linking
      Navigator.pushReplacementNamed(context, '/home');
    } catch (error) {
      showToast(message: "Error linking device: $error");
      print('Error = $error');
    }
  }

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
