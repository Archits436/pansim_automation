import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../../../global/common/toast.dart';

class DevicesSuccess extends StatefulWidget {
  const DevicesSuccess({Key? key});

  @override
  State<DevicesSuccess> createState() => _DevicesSuccessState();
}

class _DevicesSuccessState extends State<DevicesSuccess> {
  Box passBox = Hive.box('passBox');
  late DatabaseReference _databaseReference;
  late List<dynamic> _appliances;

  @override
  void initState() {
    super.initState();
    _databaseReference = FirebaseDatabase.instance.ref();
    _loadAppliancesData();
  }

  Future<void> _loadAppliancesData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DataSnapshot snapshot = await FirebaseDatabase.instance
            .ref()
            .child('UsersData/${user.uid}/Appliances')
            .once() as DataSnapshot;

        List<dynamic> appliancesList = [];

        if (snapshot.value != null && snapshot.value is Map) {
          (snapshot.value as Map).forEach((key, value) {
            // Extract the value of each child and add it to the list
            appliancesList.add(value);
          });
        }

        setState(() {
          _appliances = appliancesList;
        });
      } catch (error) {
        print("Error fetching data: $error");
        showToast(message: "Error fetching data");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
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
                    SizedBox(
                      height: 50,
                    ),
                    Container(
                      child: Text(
                        "Here are all the switches you can control.",
                        style: TextStyle(fontSize: 20, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      margin: EdgeInsets.only(bottom: 50),
                    ),
                    if (_appliances != null)
                      ..._appliances.map<Widget>((appliance) {
                        return GestureDetector(
                          onTap: () {
                            // Perform action when button is tapped
                          },
                          child: Container(
                            height: 45,
                            width: 150,
                            decoration: BoxDecoration(
                              color: appliance['status'] == 'on'
                                  ? Colors.green.shade600
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.green.shade600,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                appliance['name'],
                                style: TextStyle(
                                  color: appliance['status'] == 'on'
                                      ? Colors.white
                                      : Colors.green.shade600,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
              SizedBox(
                height: 200,
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
    );
  }
}
