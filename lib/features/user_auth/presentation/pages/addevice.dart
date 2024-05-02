// ignore_for_file: body_might_complete_normally_catch_error, unnecessary_null_comparison, non_constant_identifier_names, unused_import, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_firebase/features/user_auth/presentation/pages/devices_fail.dart';
import 'package:flutter_firebase/features/user_auth/presentation/pages/devices_success.dart';
import 'package:geolocator/geolocator.dart';
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
    _checkPermissionsAndEnableServices();
    startBluetoothScan();
  }

  Future<void> _checkPermissionsAndEnableServices() async {
    // Bluetooth permission handling
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

    // Location permission handling
    PermissionStatus locationStatus = await Permission.location.request();
    if (locationStatus == PermissionStatus.denied ||
        locationStatus == PermissionStatus.permanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission is denied.")));
    }
    if (locationStatus == PermissionStatus.permanentlyDenied) {
      openAppSettings();
    }

    // Check if location service is enabled
    bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationServiceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Location service is disabled. Please enable it.")));
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

    void connectWithESP(int index) async {
      try {
        targetDevice = devicesList[index];
        await targetDevice.connect();
        await Future.delayed(Duration(seconds: 1)); // Delay for stability
        List<BluetoothService> services = await targetDevice.discoverServices();
        // Locate the appropriate characteristic and write credentials
        for (BluetoothService service in services) {
          // Replace with your service and characteristic UUIDs
          if (service.uuid.toString().toLowerCase() ==
              SERVICE_UUID.toLowerCase()) {
            BluetoothCharacteristic? characteristic =
                service.characteristics.firstWhere(
              (c) =>
                  c.uuid.toString().toLowerCase() ==
                  CHARACTERISTIC_UUID.toLowerCase(),
            );
            if (characteristic != null) {
              // Write credentials to the characteristic
              await characteristic.write(utf8.encode("$email,$password"),
                  withoutResponse: true);
              showToast(message: "Credentials sent to ESP32 successfully!");
              Navigator.pushNamed(context, '/devices_success');
            } else {
              showToast(message: "Characteristic not found");
            }
            break; // Exit loop after finding the characteristic
          }
        }
      } catch (error) {
        showToast(message: "Failed to connect to ESP32 or write credentials");
        print('Error connecting to ESP32: $error');
      }
    }

    bool _isLoading = false;

    void _setLoading(bool isLoading) {
      setState(() {
        _isLoading = isLoading;
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Nearby Bluetooth Devices'),
        backgroundColor: Colors.green.shade600,
      ),
      body: RefreshIndicator(
        color: Colors.green.shade600,
        onRefresh: () async {
          // Put your refresh logic here, like re-fetching Bluetooth devices
          // or resetting the state.
          await Future.delayed(
              Duration(milliseconds: 1500)); // Simulate some delay
          startBluetoothScan();
          setState(() {}); // Refresh the UI
        },
        child: ListView.builder(
          physics:
              AlwaysScrollableScrollPhysics(), // Allow for pulling to refresh
          itemCount: devicesList.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(devicesList[index].name),
              subtitle: Text(devicesList[index].id.toString()),
              trailing: ElevatedButton(
                onPressed: _isLoading
                      ? null
                      : () async {
                          _setLoading(true);
                          connectWithESP(index);
                          _setLoading(false);
                        },
                child: Text("Connect"),
                style: ElevatedButton.styleFrom(primary: Colors.green.shade600),
              ),
            );
          },
        ),
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
