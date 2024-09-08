import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'package:intl/intl.dart';
import 'add_job_screen.dart';

class FieldDetailsScreen extends StatefulWidget {
  final int fieldId; // Pass the field's ID to this screen

  FieldDetailsScreen({required this.fieldId});

  @override
  _FieldDetailsScreenState createState() => _FieldDetailsScreenState();
}

class _FieldDetailsScreenState extends State<FieldDetailsScreen> {
  final TextEditingController _gerkPidController = TextEditingController();
  final TextEditingController _blokIdController = TextEditingController();
  final TextEditingController _m2Controller = TextEditingController();
  final TextEditingController _domaceImeController = TextEditingController();

  bool _isLoading = true;
  List<Map<String, dynamic>> _jobLogs = [];
  String _screenTitle = 'Details Screen'; // Default screen title

  @override
  void initState() {
    super.initState();
    _fetchFieldDetails();
    _fetchJobLogs(); // Fetch job logs when screen initializes
  }

  Future<void> _fetchFieldDetails() async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    // Fetch the field data by ID
    final fieldData = await db.query(
      'parcels',
      where: 'id = ?',
      whereArgs: [widget.fieldId],
    );

    if (fieldData.isNotEmpty) {
      setState(() {
        _gerkPidController.text = fieldData[0]['gerk_pid'] as String? ?? '';
        _blokIdController.text = fieldData[0]['blok_id'] as String? ?? '';
        _m2Controller.text = (fieldData[0]['m2'] as double?).toString() ?? '';
        _domaceImeController.text = fieldData[0]['domace_ime'] as String? ?? '';
        _screenTitle = _domaceImeController.text; // Update the screen title
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false; // Stop loading even if no data is found
      });
      // Optionally, show a message if no data is found
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No data found for the provided field ID.')),
      );
    }
  }

  Future<void> _saveFieldDetails() async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    await db.update(
      'parcels',
      {
        'gerk_pid': _gerkPidController.text,
        'blok_id': _blokIdController.text,
        'm2': double.tryParse(_m2Controller.text) ?? 0.0,
        'domace_ime': _domaceImeController.text,
      },
      where: 'id = ?',
      whereArgs: [widget.fieldId],
    );

    // Show a SnackBar with a confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Podatki so shranjeni!')),
    );
  }

  Future<void> _fetchJobLogs() async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    // Fetch job details for the specific parcel
    final jobLogs = await db.rawQuery('''
      SELECT job_details.*, jobs.job_type 
      FROM job_details 
      INNER JOIN jobs ON job_details.job_id = jobs.id
      WHERE jobs.parcel_id = ?
      ORDER BY job_details.date_time DESC
    ''', [widget.fieldId]);

    setState(() {
      _jobLogs = jobLogs;
    });
  }

  Future<void> _deleteJob(int jobId) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.deleteJob(jobId);
    _fetchJobLogs(); // Refresh job logs after deletion
  }

  // Navigate to Add Job Screen and pass the action type
  void _navigateToAddJobScreen(String actionType) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddJobScreen(
          parcelId: widget.fieldId,
          actionType: actionType,
        ),
      ),
    );
    _fetchJobLogs(); // Refresh job logs after returning
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Job'),
          content: Text('Are you sure you want to delete this job?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Custom back button logic
        Navigator.of(context).pop(true);
        return false; // Prevent default back button behavior (let custom logic handle it)
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_screenTitle), // Use the dynamic screen title
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _gerkPidController,
                      decoration: InputDecoration(labelText: 'GERK PID'),
                      readOnly: true, // Makes the TextField read-only
                    ),
                    TextField(
                      controller: _blokIdController,
                      decoration: InputDecoration(labelText: 'Blok ID'),
                      readOnly: true, // Makes the TextField read-only
                    ),
                    TextField(
                      controller: _m2Controller,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'm²'),
                      //readOnly: true, // Makes the TextField read-only
                    ),
                    SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: _saveFieldDetails,
                        child: Text('Shrani'),
                      ),
                    ),
                    SizedBox(height: 20),
                    // Optional: Add some space between the button and the divider
                    Divider(
                      color: Colors.grey, // Customize the color
                      thickness: 1.0, // Customize the thickness
                    ),
                    SizedBox(height: 20),
                    // Optional: Add some space after the divider
                    Wrap(
                      spacing: 20, // Horizontal spacing between buttons
                      runSpacing:
                          20, // Vertical spacing between lines of buttons
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown, // Background color
                            foregroundColor: Colors.black, // Text color
                          ),
                          onPressed: () =>
                              _navigateToAddJobScreen('Priprava Zemlje'),
                          child: Text('Priprava Zemlje'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green, // Background color
                            foregroundColor: Colors.black, // Text color
                          ),
                          onPressed: () => _navigateToAddJobScreen('Setev'),
                          child: Text('Setev'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue, // Background color
                            foregroundColor: Colors.black, // Text color
                          ),
                          onPressed: () =>
                              _navigateToAddJobScreen('Škropljenje'),
                          child: Text('Škropljenje'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red, // Background color
                            foregroundColor: Colors.black, // Text color
                          ),
                          onPressed: () => _navigateToAddJobScreen('Žetev'),
                          child: Text('Žetev'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow, // Background color
                            foregroundColor: Colors.black, // Text color
                          ),
                          onPressed: () => _navigateToAddJobScreen('Baliranje'),
                          child: Text('Baliranje'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange, // Background color
                            foregroundColor: Colors.black, // Text color
                          ),
                          onPressed: () =>
                              _navigateToAddJobScreen('Dognojevanje'),
                          child: Text('Dognojevanje'),
                        ),
                        // Add more buttons here if needed
                      ],
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Zgodovina',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _jobLogs.length,
                        itemBuilder: (context, index) {
                          final job = _jobLogs[index];
                          return ListTile(
                            title: Text(
                              job['detail_type'],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              job['job_type'] +
                                  (job['detail_type'] == "Setev"
                                      ? ' ' +
                                          ((job['seed_quantity']?.toString() ??
                                                  '') +
                                              "kg")
                                      : job['detail_type'] == "Dognojevanje"
                                          ? ' ' +
                                              ((job['fert_quantity']
                                                          ?.toString() ??
                                                      '') +
                                                  "kg")
                                          : job['detail_type'] == "Škropljenje"
                                              ? ' ' +
                                                  ((job['spray_quantity']
                                                              ?.toString() ??
                                                          '') +
                                                      "L")
                                              : job['detail_type'] ==
                                                      "Baliranje"
                                                  ? ' ' +
                                                      ((job['bales_on_field']
                                                                  ?.toString() ??
                                                              '') +
                                                          " kom")
                                                  : '') + // Add more conditions as needed
                                  '\n' +
                                  'Datum: ' +
                                  DateFormat('dd.MM.yyyy HH:mm').format(
                                    DateTime.parse(
                                      job['date_time'] as String,
                                    ),
                                  ),
                            ),
                            isThreeLine: true,
                            trailing: IconButton(
                              icon: Icon(Icons.close),
                              color: Colors.red,
                              onPressed: () async {
                                bool? confirm =
                                    await _showDeleteConfirmation(context);
                                if (confirm == true) {
                                  await _deleteJob(job['job_id']);
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
