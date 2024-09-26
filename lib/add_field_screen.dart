import 'package:flutter/material.dart';
import 'firebase_helper.dart'; // Import FirestoreHelper

class NewFieldScreen extends StatefulWidget {
  @override
  _NewFieldScreenState createState() => _NewFieldScreenState();
}

class _NewFieldScreenState extends State<NewFieldScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  final FirestoreHelper _firestoreHelper =
      FirestoreHelper(); // FirestoreHelper instance

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dodaj novo parcelo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Domače ime',
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _typeController,
              decoration: InputDecoration(
                labelText: 'Tip',
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _sizeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Površina v arih',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                String name = _nameController.text;
                String type = _typeController.text;
                double? size = double.tryParse(_sizeController.text);

                if (name.isNotEmpty && type.isNotEmpty && size != null) {
                  // Get the user's current KMG MID
                  int? kmgMidId = await _firestoreHelper.getLastKmgMid();
                  if (kmgMidId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('No active KMG MID found')),
                    );
                    return;
                  }

                  // Construct the new field (parcel) data
                  Map<String, dynamic> parcelData = {
                    'domace_ime': name,
                    'type': type,
                    'm2': size * 100, // Convert 'ar' to 'm²'
                    'kmg_mid_id': kmgMidId,
                    'created_at': DateTime.now().toIso8601String(),
                  };

                  // Save the parcel data to Firestore
                  await _firestoreHelper.insertOrUpdateParcel(parcelData);

                  // Navigate back after successful save
                  Navigator.of(context).pop();
                } else {
                  // Show an error message if any field is empty or invalid
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please fill all fields correctly')),
                  );
                }
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
