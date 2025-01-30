import 'package:flutter/material.dart';

class AddBagPopup extends StatefulWidget {
  final Function(String bagName, String ownerName) onSave;

  const AddBagPopup({super.key, required this.onSave});

  @override
  State<AddBagPopup> createState() => _AddBagPopupState();
}

class _AddBagPopupState extends State<AddBagPopup> {
  final TextEditingController bagNameController = TextEditingController();
  final TextEditingController ownerNameController = TextEditingController();

  @override
  void dispose() {
    bagNameController.dispose();
    ownerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      title: const Text('Add New Bag'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: bagNameController,
            decoration: const InputDecoration(labelText: 'Name of the Bag'),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: ownerNameController,
            decoration: const InputDecoration(labelText: "Owner's Name"),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            String bagName = bagNameController.text.trim();
            String ownerName = ownerNameController.text.trim();

            if (bagName.isNotEmpty && ownerName.isNotEmpty) {
              widget.onSave(bagName, ownerName);
              Navigator.pop(context); // Close popup
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please fill in all fields')),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
