import 'package:flutter/material.dart';
import 'firebase_helper.dart'; // Use FirestoreHelper
import 'package:firebase_auth/firebase_auth.dart';
import 'add_job_screen.dart';
import 'widgets/job_history_widget.dart'; // Import JobHistoryWidget

class FieldDetailsScreen extends StatefulWidget {
  final String fieldId; // Firestore uses String IDs

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
  String? _kmgMidId; // Store kmgMidId here
  String _screenTitle = 'Details Screen'; // Default screen title
  final FirestoreHelper _firestoreHelper = FirestoreHelper(); // Use Firestore

  String? _selectedJob; // For dropdown job selection

  Key _jobHistoryKey = UniqueKey(); // Add this key to trigger a rebuild

  // Job types with corresponding colors
  final List<Map<String, dynamic>> _jobTypes = [
    {'job': 'Priprava Zemlje', 'color': Colors.brown},
    {'job': 'Predsetvena obdelava', 'color': Colors.deepOrangeAccent},
    {'job': 'Setev', 'color': Colors.green},
    {'job': 'Dognojevanje', 'color': Colors.orange},
    {'job': 'Škropljenje', 'color': Colors.blue},
    {'job': 'Žetev', 'color': Colors.red},
    {'job': 'Baliranje', 'color': Colors.yellow},
    {'job': 'Mulčanje', 'color': Colors.teal},
    {'job': 'Ozelenitev', 'color': Colors.lime},
    {'job': 'Košnja', 'color': Colors.lightGreen},
  ];

  @override
  void initState() {
    super.initState();
    _fetchFieldDetails(); // Fetch field data from Firestore
    _fetchKmgMidId(); // Fetch kmgMidId
  }

  /// Fetch kmgMidId and set the state once done
  Future<void> _fetchKmgMidId() async {
    final kmgMidId = await _firestoreHelper.getLastKmgMid();
    if (kmgMidId != null) {
      setState(() {
        _kmgMidId = kmgMidId.toString();
      });
    }
  }

  /// Fetch field details from Firestore
  Future<void> _fetchFieldDetails() async {
    setState(() {
      _isLoading = true;
    });

    int? kmgMidId = await _firestoreHelper.getLastKmgMid();
    if (kmgMidId == null) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No active KMG MID found for this user.')),
      );
      return;
    }

    var fieldData =
        await _firestoreHelper.getParcelById(kmgMidId, widget.fieldId);

    if (fieldData != null) {
      setState(() {
        _gerkPidController.text = fieldData['gerk_pid']?.toString() ?? '';
        _blokIdController.text = fieldData['blok_id']?.toString() ?? '';
        _m2Controller.text = fieldData['m2']?.toString() ?? '';
        _domaceImeController.text = fieldData['domace_ime']?.toString() ?? '';
        _screenTitle = _domaceImeController.text; // Update the screen title
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No data found for the provided field ID.')),
      );
    }
  }

  /// Save field details to Firestore
  Future<void> _saveFieldDetails() async {
    int? kmgMidId = await _firestoreHelper.getLastKmgMid();
    if (kmgMidId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No active KMG MID found.')),
      );
      return;
    }

    bool exists =
        await _firestoreHelper.checkParcelExists(kmgMidId, widget.fieldId);

    if (exists) {
      await _firestoreHelper.updateParcel(kmgMidId, widget.fieldId, {
        'gerk_pid': _gerkPidController.text,
        'blok_id': _blokIdController.text,
        'm2': double.tryParse(_m2Controller.text) ?? 0.0,
        'domace_ime': _domaceImeController.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data saved successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Document does not exist. Cannot update.')),
      );
    }
  }

  /// Navigate to Add Job Screen and pass the necessary parameters
  void _navigateToAddJobScreen(String actionType) async {
    String? userId = getUserId();
    int? kmgMidId = await _firestoreHelper.getLastKmgMid();

    if (kmgMidId == null || userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch KMG MID or User ID')),
      );
      return;
    }

    // Wait for the result from AddJobScreen
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddJobScreen(
          userId: userId,
          kmgMid: kmgMidId.toString(),
          parcelId: widget.fieldId,
          actionType: actionType,
        ),
      ),
    );

    // Check if the result indicates that a job was added, then refresh the job logs
    if (result == true) {
      setState(() {
        _jobHistoryKey =
            UniqueKey(); // Trigger a rebuild of the JobHistoryWidget
      });
    }
  }

  // Helper function to get the current user's userId from FirebaseAuth
  String? getUserId() {
    User? user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(true);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_screenTitle),
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
                      readOnly: true,
                    ),
                    TextField(
                      controller: _blokIdController,
                      decoration: InputDecoration(labelText: 'Blok ID'),
                      readOnly: true,
                    ),
                    TextField(
                      controller: _m2Controller,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'm²'),
                    ),
                    SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: _saveFieldDetails,
                        child: Text('Save'),
                      ),
                    ),
                    SizedBox(height: 20),
                    Divider(),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedJob,
                            decoration:
                                InputDecoration(labelText: 'Select Job'),
                            items: _jobTypes.map((job) {
                              return DropdownMenuItem<String>(
                                value: job['job'],
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 8,
                                      backgroundColor: job['color'],
                                    ),
                                    SizedBox(width: 10),
                                    Text(job['job']),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedJob = newValue;
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            if (_selectedJob != null) {
                              _navigateToAddJobScreen(_selectedJob!);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Please select a job')),
                              );
                            }
                          },
                          child: Text('ADD'),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    // FutureBuilder to handle async fetching of kmgMidId
                    _kmgMidId == null
                        ? CircularProgressIndicator() // Show loader while waiting
                        : Expanded(
                            child: JobHistoryWidget(
                              key:
                                  _jobHistoryKey, // Add the key here to trigger rebuilds
                              userId: getUserId()!,
                              kmgMidId: _kmgMidId!, // Pass the fetched kmgMidId
                              fieldId: widget.fieldId,
                            ),
                          ),
                  ],
                ),
              ),
      ),
    );
  }
}
