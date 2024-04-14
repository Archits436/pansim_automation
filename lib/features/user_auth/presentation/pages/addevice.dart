// ignore_for_file: body_might_complete_normally_catch_error, unnecessary_null_comparison

import 'dart:developer';
import 'dart:io';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_firebase/features/user_auth/presentation/pages/devices_fail.dart';
import 'package:flutter_firebase/features/user_auth/presentation/pages/devices_success.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_firebase/features/user_auth/models/user_model.dart';
import 'package:network_info_plus/network_info_plus.dart';
// import 'package:flutter_firebase/features/user_auth/models/user_model.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import 'package:flutter_firebase/global/common/toast.dart';

class Addevice extends StatefulWidget {
  const Addevice({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AddeviceState();
}

class _AddeviceState extends State<Addevice> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  // final _db = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;
  Box passBox = Hive.box('passBox');
  late FlutterBluePlus flutterBluePlus;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndEnableBluetooth();
  }

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

  Future<void> _checkPermissionsAndEnableBluetooth() async {
    PermissionStatus bluetoothStatus = await Permission.bluetooth.request();
    if (bluetoothStatus == PermissionStatus.granted) {
      await FlutterBluePlus.startScan(timeout: Duration(seconds: 4));
      await Future.delayed(Duration(seconds: 4));
      await FlutterBluePlus.stopScan();
    }
    if (bluetoothStatus == PermissionStatus.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bluetooth permission is denied.")));
    }
    if (bluetoothStatus == PermissionStatus.permanentlyDenied) {
      openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(flex: 3, child: _buildQrView(context)),
          Expanded(
            flex: 1,
            child: Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  SizedBox(height: 20),
                  _buildResultText(),
                  SizedBox(height: 40),
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
        : const Text(
            'Scan the QR code',
            style: TextStyle(fontSize: 30),
          );
  }

  Widget _buildButtons() {
    return SizedBox(
      height: 50,
      width: 120,
      child: ElevatedButton(
        onPressed: () async {
          await controller?.toggleFlash();
          setState(() {});
        },
        child: FutureBuilder<bool?>(
          future: controller?.getFlashStatus(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            }
            if (snapshot.hasError || snapshot.data == null) {
              return Text('Flash: Off', style: TextStyle(fontSize: 20));
            }
            return Text(
              'Flash: ${snapshot.data! ? 'On' : 'Off'}',
              style: TextStyle(fontSize: 20),
            );
          },
        ),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600),
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

  bool scanned = false;

  Future<void> _onQRViewCreated(QRViewController controller) async {
    setState(() {
      this.controller = controller;
    });
    final info = NetworkInfo();
    final wifiName = await info.getWifiName();
    print(wifiName);
    controller.scannedDataStream.listen((scanData) async {
      if (!scanned) {
        scanned = true;
        String macAddress = scanData.code as String;
        if (user != null) {
          await storeDeviceInFirebase(UserModel(
            userId: user!.uid,
            macAddress: macAddress,
            status: 'active',
            wifi: wifiName!,
          ));
        } else {
          showToast(message: "User not authenticated.");
        }
      }
    });
  }

  Future<void> storeDeviceInFirebase(UserModel userModel) async {
    try {
      FirebaseAuth auth = FirebaseAuth.instance;
      User? user = auth.currentUser;
      if (user == null) {
        showToast(message: "User not authenticated.");
        return;
      }
      String email = user.email ?? "";
      String password = passBox.get('pass') ?? "";
      String credentials = "$email,$password";
      FlutterBluePlus.scanResults.listen((results) async {
        for (ScanResult result in results) {
          if (result.device.name == "ESP32_BLE_Credentials") {
            if (result != null) {
              await result.device.connect();
              List<BluetoothService> services =
                  await result.device.discoverServices();
              for (BluetoothService service in services) {
                if (service.uuid ==
                    Guid('4fafc201-1fb5-459e-8fcc-c5c9c331914b')) {
                  BluetoothCharacteristic? characteristic =
                      service.characteristics.firstWhere(
                    (c) =>
                        c.uuid == Guid('beb5483e-36e1-4688-b7f5-ea07361b26a8'),
                  );
                  if (characteristic != null) {
                    // print("AAAAAAAAAAAAAAAAAAA");
                    List<int> dataToSend = utf8.encode("$credentials");
                    await characteristic.write(dataToSend,
                        withoutResponse: true);
                    print('Data sent to Arduino via BLE: $dataToSend');
                    showToast(message: "Data sent to Arduino via BLE !");
                    // print("YAY");
                  } else {
                    print('Characteristic not found');
                    showToast(message: "Characteristic not found");
                  }
                } else {
                  print('Service not found');
                  showToast(message: "Service not found");
                }
              }
              await result.device.disconnect();
            } else {
              print('BLE device not found');
              showToast(message: "BLE device not found");
            }
          }
        }
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userModel.macAddress.replaceAll('/', '-'))
          .set(userModel.toJson());
      print('Device linked successfully!');
      // showToast(message: "Device linked successfully !");
      if (mounted) {
        Navigator.pushNamed(context, '/home');
      }
    } catch (error) {
      print('Error linking device: $error');
      showToast(message: "Error linking device: $error");
      if (mounted) {
        Navigator.pushNamed(context, '/devices_fail');
      }
      rethrow;
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
