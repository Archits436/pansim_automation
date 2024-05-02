import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:lottie/lottie.dart';

import '../../../../global/common/toast.dart';

class DevicesSuccess extends StatefulWidget {
  const DevicesSuccess({Key? key});

  @override
  State<DevicesSuccess> createState() => _DevicesSuccessState();
}

class _DevicesSuccessState extends State<DevicesSuccess> {
  Box passBox = Hive.box('passBox');
  late DatabaseReference _databaseReference;
  late List<dynamic> _appliances = [];

  StreamSubscription<DatabaseEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    _databaseReference = FirebaseDatabase.instance.ref();
    _subscribeToAppliancesData();
  }

  void _subscribeToAppliancesData() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _subscription = FirebaseDatabase.instance
          .ref()
          .child('UsersData/${user.uid}/Appliances')
          .onValue
          .listen((event) {
        if (event.snapshot.value != null && event.snapshot.value is Map) {
          List<dynamic> appliancesList = [];
          if (event.snapshot.value != null &&
              event.snapshot.value is Map<Object?, Object?>) {
            final Map<Object?, Object?>? dataMap =
                event.snapshot.value as Map<Object?, Object?>?;
            final appliancesMap = dataMap?.cast<String, String>();
            if (appliancesMap != null) {
              final List<dynamic> appliancesList = [];
              appliancesMap.forEach((key, value) {
                appliancesList.add({
                  'name': key,
                  'status': value == "1"
                      ? 'on'
                      : 'off', // Assuming 1 represents 'on' and 0 represents 'off'
                });
              });
              // print(appliancesList);
              setState(() {
                _appliances = appliancesList;
              });
              print("Appliances = $_appliances");
            }
          }
        } else {
          setState(() {
            _appliances = [];
          });
        }
      }, onError: (error) {
        print("Error fetching data: $error");
        showToast(message: "Error fetching data");
      });
    }
  }

  void _toggleSwitchStatus(Map<String, dynamic> appliance) async {
    final status = appliance['status'];
    final newStatus = (status == 'on' || status == 1) ? '0' : '1';

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userId = currentUser.uid;
        final DatabaseReference ref = FirebaseDatabase.instance.reference();
        final appliancePath =
            'UsersData/$userId/Appliances/${appliance['name']}';
        await ref.child(appliancePath).set(newStatus);
        setState(() {
          appliance['status'] = newStatus;
        });
        print('Status updated successfully to: $newStatus');
      } else {
        print('Current user not found');
      }
    } catch (error) {
      print('Error updating status: $error');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Exit the app when back button is pressed
        return true;
      },
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/home.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            ),
            _appliances.isEmpty // Check if appliances list is empty
                ? Center(
                    child: CircularProgressIndicator(
                        color: Colors.green
                            .shade600), // Show circular progress indicator
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: Container(
                          margin: EdgeInsets.only(top: 50),
                          child: Center(
                            child: Text(
                              " PANSIM HOME AUTOMATION ",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 30,
                                  color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          padding: EdgeInsets.all(20.0),
                          children:
                              _appliances.asMap().entries.map<Widget>((entry) {
                            final index = entry.key;
                            final appliance = entry.value;
                            final switchName = 'Switch ${index + 1}';
                            return GestureDetector(
                              onTap: () async {
                                _toggleSwitchStatus(appliance);
                                setState(() {
                                  appliance['playAnimation'] =
                                      true; // Set to true to play animation
                                });
                                // Delay to allow animation to play
                                await Future.delayed(
                                    Duration(milliseconds: 500));
                                setState(() {
                                  appliance['playAnimation'] =
                                      false; // Set back to false
                                });
                              },
                              child: Container(
                                alignment: Alignment.center,
                                child: Container(
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: appliance['status'] == 'on' ||
                                              appliance['status'] == 1
                                          ? Colors.green.shade600
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.green.shade600,
                                      ),
                                    ),
                                    margin: EdgeInsets.all(10),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Center(
                                          child: Text(
                                            switchName,
                                            style: TextStyle(
                                              color: appliance['status'] ==
                                                          'on' ||
                                                      appliance['status'] == 1
                                                  ? Colors.white
                                                  : Colors.green.shade600,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                        Lottie.asset(
                                          'assets/Lottie/switch.json', // Path to your animation file
                                          height: 70, // Adjust height as needed
                                          width: 70, // Adjust width as needed
                                          fit: BoxFit.cover,
                                          animate: appliance['playAnimation'] ??
                                              false,
                                          repeat:
                                              false, // Play the animation only once
                                        ),
                                      ],
                                    )),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      GestureDetector(
                        onTap: () async {
                          FirebaseAuth.instance.signOut();
                          await passBox.delete('pass');
                          Navigator.pushNamed(context, "/login");
                          showToast(message: "Successfully signed out");
                        },
                        child: Container(
                          height: 45,
                          width: 150,
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              "Logout",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
