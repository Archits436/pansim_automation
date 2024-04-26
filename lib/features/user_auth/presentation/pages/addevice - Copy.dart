// ignore_for_file: body_might_complete_normally_catch_error, unnecessary_null_comparison, unused_import

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_firebase/features/user_auth/presentation/pages/devices_fail.dart';
import 'package:flutter_firebase/features/user_auth/presentation/pages/devices_success.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_firebase/features/user_auth/models/user_model.dart';
// import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_firebase/global/common/toast.dart';

class AddeviceCopy extends StatefulWidget {
  final Widget? child;
  const AddeviceCopy({super.key, this.child});

  @override
  State<AddeviceCopy> createState() => _AddeviceCopyState();
}

class _AddeviceCopyState extends State<AddeviceCopy> {
  // final String SERVICE_UUID = "f0dfbd21-6d67-408e-9c0f-6b358b8975a7";
  // final String CHARACTERISTIC_UUID = "612d7c4d-8a1b-41f7-9a56-df58d126b2c0";
  // final String TARGET_DEVICE_NAME = "ESP32_BLE_CREDENTIALS";
  Box passBox = Hive.box('passBox');
  // late StreamSubscription<ScanResult> scanSubscription;
  FlutterBlue flutterBlue = FlutterBlue.instance;
  late BluetoothDevice targetDevice;
  late BluetoothCharacteristic targetCharacteristic;
  List<BluetoothDevice> devicesList = [];

  @override
  void initState() {
    super.initState();
    startBluetoothScan();
  }

  void startBluetoothScan() {
    flutterBlue.startScan(timeout: Duration(seconds: 4));

    flutterBlue.scanResults.listen((List<ScanResult> results) {
      // Update the devices list with the new results
      setState(() {
        devicesList.clear();
        for (ScanResult result in results) {
          devicesList.add(result.device);
        }
      });
    });
  }

  // submitAction() {
  //   FirebaseAuth auth = FirebaseAuth.instance;
  //   User? user = auth.currentUser;
  //   if (user == null) {
  //     showToast(message: "User not authenticated.");
  //     return;
  //   }
  //   String email = user.email ?? "";
  //   String password = passBox.get('pass') ?? "";
  //   String credentials = "$email,$password";
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth Devices'),
      ),
      body: ListView.builder(
        itemCount: devicesList.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(devicesList[index].name),
            subtitle: Text(devicesList[index].id.toString()),
          );
        },
      ),
    );
  }
}
