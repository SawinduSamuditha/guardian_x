import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConnectButtonPopup extends StatefulWidget {
  final String bagName;
  final Function(String deviceId) onSave;

  const ConnectButtonPopup({
    super.key,
    required this.bagName,
    required this.onSave,
  });

  @override
  State<ConnectButtonPopup> createState() => _ConnectButtonPopupState();
}

class _ConnectButtonPopupState extends State<ConnectButtonPopup> {
  final TextEditingController deviceIdController = TextEditingController();
  bool isSaving = false; // Save Loading Indicator

  @override
  void dispose() {
    deviceIdController.dispose();
    super.dispose();
  }

  Future<void> saveToFirebase(String deviceId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User Login නොවේ')),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('bags').add({
        'email': user.email,
        'bagName': widget.bagName,
        'deviceId': deviceId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully saved to Firebase.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter Device ID'),
      content: TextField(
        controller: deviceIdController,
        decoration: const InputDecoration(labelText: 'Device ID'),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isSaving
              ? null
              : () async {
                  String deviceId = deviceIdController.text.trim();
                  if (deviceId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter the Device ID.')),
                    );
                    return;
                  }
                  setState(() {
                    isSaving = true;
                  });

                  await saveToFirebase(deviceId);
                  setState(() {
                    isSaving = false;
                  });
                  widget.onSave(deviceId);
                  Navigator.pop(context);
                },
          child: isSaving
              ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
