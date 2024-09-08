import 'package:flutter/material.dart';
import 'database_helper.dart';

class NewFieldScreen extends StatefulWidget {
  @override
  _NewFieldScreenState createState() => _NewFieldScreenState();
}

class _NewFieldScreenState extends State<NewFieldScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();

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

                if (name.isNotEmpty && size != null) {
                  await _dbHelper.insertField(name, size);
                  Navigator.of(context).pop();
                } else {
                  // Show an error message if any field is empty
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
