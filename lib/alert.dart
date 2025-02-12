import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

class BulbControl extends StatefulWidget {
  const BulbControl({super.key});

  @override
  State<BulbControl> createState() => _BulbControlState();
}

class _BulbControlState extends State<BulbControl> {
  bool bulbState = false;
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _loadBulbState();
  }

  // Fetch initial state from Firebase
  void _loadBulbState() {
    dbRef.child("light/switch").onValue.listen((event) {
      final bool state = event.snapshot.value as bool? ?? false;
      setState(() {
        bulbState = state;
      });
    });
  }

  // Toggle bulb state in Firebase
  void _toggleBulb() {
    dbRef.child("light").set({"switch": !bulbState});
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Alert LED Bulb",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Icon(
            Icons.lightbulb,
            color: bulbState ? Colors.yellow : Colors.black,
            size: 60,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _toggleBulb,
            child: Text(bulbState ? "Turn OFF" : "Turn ON"),
          ),
        ],
      ),
    );
  }
}
