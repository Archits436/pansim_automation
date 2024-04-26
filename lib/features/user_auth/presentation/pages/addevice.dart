// ignore_for_file: body_might_complete_normally_catch_error, unnecessary_null_comparison, non_constant_identifier_names, unused_import, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_firebase/features/user_auth/presentation/pages/devices_fail.dart';
import 'package:flutter_firebase/features/user_auth/presentation/pages/devices_success.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:flutter_firebase/global/common/toast.dart';

class Addevice extends StatefulWidget {
  const Addevice({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AddeviceState();
}

class _AddeviceState extends State<Addevice> {
  final User? user = FirebaseAuth.instance.currentUser;
  Box passBox = Hive.box('passBox');
  List<BluetoothDevice> devicesList = [];
  late BluetoothDevice targetDevice;
  final String SERVICE_UUID = "fff0";
  final String CHARACTERISTIC_UUID = "fff1";

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndEnableBluetooth();
    startBluetoothScan();
  }

  Future<void> _checkPermissionsAndEnableBluetooth() async {
    PermissionStatus bluetoothStatus = await Permission.bluetooth.request();
    if (bluetoothStatus == PermissionStatus.granted) {
      bool isBluetoothOn =
          await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;
      if (!isBluetoothOn) {
        // Bluetooth is off, turn it on
        if (Platform.isAndroid) {
          await FlutterBluePlus.turnOn();
        }
      }
      print("WE HAVE BLUETOOTH");
    }
    if (bluetoothStatus == PermissionStatus.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bluetooth permission is denied.")));
    }
    if (bluetoothStatus == PermissionStatus.permanentlyDenied) {
      openAppSettings();
    }
  }

  void startBluetoothScan() {
    FlutterBluePlus.startScan(timeout: Duration(seconds: 4));

    FlutterBluePlus.scanResults.listen((List<ScanResult> results) {
      // Update the devices list with the new results
      setState(() {
        devicesList.clear();
        for (ScanResult result in results) {
          devicesList.add(result.device);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    if (user == null) {
      showToast(message: "User not authenticated.");
    }
    String email = user!.email ?? "";
    String password = passBox.get('pass') ?? "";
    String credentials = "$email,$password";

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
            trailing: ElevatedButton(
                onPressed: () async {
                  targetDevice = devicesList[index];
                  await targetDevice.connect();
                  List<BluetoothService> services =
                      await targetDevice.discoverServices();
                  for (BluetoothService service in services) {
                    if (service.uuid.toString().toLowerCase() ==
                        SERVICE_UUID.toLowerCase()) {
                      BluetoothCharacteristic? characteristic =
                          service.characteristics.firstWhere(
                        (c) =>
                            c.uuid.toString().toLowerCase() ==
                            CHARACTERISTIC_UUID.toLowerCase(),
                      );
                      if (characteristic != null) {
                        bool isWritten = false;
                        List<int> dataToSend = utf8.encode("$credentials");
                        try {
                          await characteristic.write(dataToSend,
                              withoutResponse: true);
                          isWritten = true;
                        } catch (error) {
                          print('ERROR: $error');
                          showToast(message: "ERROR");
                        }
                        if (isWritten) {
                          print('Data sent to Arduino via BLE: $dataToSend');
                          showToast(message: "Data sent to Arduino via BLE !");
                          print('Device linked successfully!');
                          if (mounted) {
                            Navigator.pushNamed(context, '/home');
                          }
                        } else {
                          showToast(message: "Could not write");
                        }
                      } else {
                        print('Characteristic not found');
                        showToast(message: "Characteristic not found");
                      }
                    }
                  }
                },
                child: Text("Connect")),
          );
        },
      ),
    );
  }

  // Future<void> storeDeviceInFirebase() async {
  //   try {
  // await result.device.disconnect();
  //   } catch (error) {
  //     print('Error linking device: $error');
  //     showToast(message: "Error linking device: $error");
  //     if (mounted) {
  //       Navigator.pushNamed(context, '/devices_fail');
  //     }
  //     rethrow;
  //   }
  // }
}
