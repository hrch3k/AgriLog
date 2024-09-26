import 'package:flutter/material.dart';
import 'data_service_firebase.dart';
import 'details_screen.dart';
import 'add_field_screen.dart';
import 'package:intl/intl.dart';
import 'export_screen.dart';
import 'services/auth_service.dart'; // Import AuthService for sign-out
import 'sign_in_screen.dart';
import 'firebase_helper.dart'; // Import Firestore helper
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/donate_dialog.dart'; // Import the DonateDialog
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Authentication
import 'admin_screen.dart';

class DataScreen extends StatefulWidget {
  final bool isAdmin;

  DataScreen({required this.isAdmin});

  @override
  _DataScreenState createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  final DataService _dataService = DataService();
  final TextEditingController _kmgController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final AuthService _authService = AuthService();
  final FirestoreHelper _firestoreHelper = FirestoreHelper();

  List<Map<String, dynamic>> _data = [];
  List<Map<String, dynamic>> _filteredData = [];
  bool _isLoading = false;
  bool? isAdmin; // Hold admin status

  @override
  void initState() {
    super.initState();
    _loadLastKmgMidData();
    _searchController.addListener(_filterFields);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _kmgController.dispose();
    super.dispose();
  }

  Future<void> _loadLastKmgMidData() async {
    int? lastKmgMid = await _firestoreHelper.getLastKmgMid();
    if (lastKmgMid != null && mounted) {
      setState(() {
        _kmgController.text = lastKmgMid.toString();
      });
      _loadDataFromFirestore(lastKmgMid);
    }
  }

  Future<void> _loadDataFromFirestore(int inputNumber) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    await _loadData(inputNumber);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchData(int inputNumber) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    await _dataService.fetchDataAndSaveToFirestore(inputNumber);
    await _loadData(inputNumber);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadData(int inputNumber) async {
    List<Map<String, dynamic>> data =
        await _firestoreHelper.getParcelsForKmgMid(inputNumber);

    if (!mounted) return;
    setState(() {
      _data = data;
      _filteredData = data;
    });
  }

  void _filterFields() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredData = _data
          .where((field) =>
              (field['domace_ime'] as String?)
                  ?.toLowerCase()
                  .startsWith(query) ??
              false)
          .toList();
    });
  }

  Future<void> _deleteParcel(String parcelId, int kmgMidId) async {
    await _firestoreHelper.deleteParcel(parcelId, kmgMidId);

    final inputNumber = int.tryParse(_kmgController.text);
    if (inputNumber != null) {
      _loadDataFromFirestore(inputNumber);
    }
  }

  Color _getFieldColor(String? detailType) {
    switch (detailType) {
      case 'Priprava Zemlje':
        return Colors.brown;
      case 'Setev':
        return Colors.green;
      case 'Škropljenje':
        return Colors.blue;
      case 'Dognojevanje':
        return Colors.orange;
      case 'Baliranje':
        return Colors.yellow;
      case 'Žetev':
        return Colors.red;
      case 'Mulčanje':
        return Colors.teal;
      case 'Ozelenitev':
        return Colors.lime;
      case 'Košnja':
        return Colors.lightGreen;
      case 'Predsetvena obdelava':
        return Colors.deepOrangeAccent;
      default:
        return Colors.grey;
    }
  }

  void _onSelectedMenuOption(String option) {
    switch (option) {
      case 'Izvozi Podatke':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ExportScreen(),
          ),
        );
        break;
      case 'Donate':
        DonateDialog.showDonationDialog(context); // Show the donation dialog
        break;
      case 'Logout':
        _logout();
        break;
      case 'Admin Tools':
        if (widget.isAdmin) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  AdminToolsScreen(), // Navigate to the Admin Tools screen
            ),
          );
        }
        break;
      case 'Feedback':
        _showFeedbackDialog(); // Call the feedback dialog here
        break;
    }
  }

  void _showFeedbackDialog() {
    final TextEditingController _titleController = TextEditingController();
    final TextEditingController _messageController = TextEditingController();
    bool isSubmitted = false; // Flag to track if the feedback is submitted

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isSubmitted
                  ? 'Feedback Submitted'
                  : 'Submit Feedback or Bug Report'),
              content: isSubmitted
                  ? Text(
                      'Thank you for your feedback!') // Display this after submission
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: 'Title',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _messageController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            labelText: 'Message',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
              actions: [
                if (isSubmitted)
                  TextButton(
                    child: Text('Close'),
                    onPressed: () {
                      Navigator.of(context)
                          .pop(); // Close the dialog after confirmation
                    },
                  )
                else
                  TextButton(
                    child: Text('Cancel'),
                    onPressed: () {
                      Navigator.of(context)
                          .pop(); // Close the dialog without submission
                    },
                  ),
                if (!isSubmitted)
                  ElevatedButton(
                    child: Text('Submit'),
                    onPressed: () async {
                      String title = _titleController.text.trim();
                      String message = _messageController.text.trim();

                      if (title.isNotEmpty && message.isNotEmpty) {
                        await _submitFeedbackTicket(title, message);
                        setState(() {
                          isSubmitted =
                              true; // Update the state to show confirmation message
                        });
                      }
                    },
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitFeedbackTicket(String title, String message) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Reference to the user's feedback tickets subcollection
        DocumentReference userRef =
            FirebaseFirestore.instance.collection('users').doc(user.uid);

        // Add the feedback ticket to the feedback_tickets subcollection under the user's document
        await userRef.collection('feedback_tickets').add({
          'title': title,
          'message': message,
          'timestamp': Timestamp.now(),
        });

        print('Feedback successfully submitted to user: ${user.uid}');
      } else {
        print('No user is currently signed in');
      }
    } catch (e) {
      print('Error submitting feedback: $e');
    }
  }

  void _logout() async {
    await _authService.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => SignInPage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> gerkItems =
        _filteredData.where((item) => item['is_gerk'] == true).toList();
    List<Map<String, dynamic>> nonGerkItems =
        _filteredData.where((item) => item['is_gerk'] != true).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('AgriLog'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String value) {
              _onSelectedMenuOption(value);
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'Izvozi Podatke',
                  child: Row(
                    children: [
                      Icon(Icons.download, color: Colors.black54),
                      SizedBox(width: 8),
                      Text('Izvozi Podatke'),
                    ],
                  ),
                ),
                if (widget.isAdmin)
                  PopupMenuItem<String>(
                    value: 'Admin Tools',
                    child: Row(
                      children: [
                        Icon(Icons.admin_panel_settings, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Admin Tools'),
                      ],
                    ),
                  ),
                PopupMenuItem<String>(
                  value: 'Donate',
                  child: Row(
                    children: [
                      Icon(Icons.favorite, color: Colors.black54),
                      SizedBox(width: 8),
                      Text('Donate'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'Logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.black54),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'Feedback',
                  child: Row(
                    children: [
                      Icon(Icons.feedback, color: Colors.black54),
                      SizedBox(width: 8),
                      Text('Feedback, Bug Report'),
                    ],
                  ),
                ),
              ];
            },
            icon: Icon(Icons.menu),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSearchBar(),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : Expanded(
                    child: ListView(
                      children: [
                        if (gerkItems.isNotEmpty)
                          _buildItemsContainer(
                            items: gerkItems,
                            title: 'GERK',
                            borderColor: Colors.green,
                          ),
                        if (nonGerkItems.isNotEmpty)
                          _buildItemsContainer(
                            items: nonGerkItems,
                            title: 'Brez GERK-a',
                            borderColor: Colors.black,
                          ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => NewFieldScreen()))
              .then((_) {
            final inputNumber = int.tryParse(_kmgController.text);
            if (inputNumber != null) {
              _loadDataFromFirestore(inputNumber);
            }
          });
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _kmgController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Vnesi KMG-MID',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10),
            SizedBox(
              width: 100,
              child: ElevatedButton(
                onPressed: () {
                  final inputNumber = int.tryParse(_kmgController.text);
                  if (inputNumber != null) {
                    _fetchData(inputNumber);
                  }
                },
                child: Text('Pridobi GERK-e'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Search Fields',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsContainer({
    required List<Map<String, dynamic>> items,
    required String title,
    required Color borderColor,
  }) {
    return FutureBuilder<String?>(
      future: _firestoreHelper.getUserId(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (!snapshot.hasData || snapshot.hasError) {
          return Center(child: Text('Error loading user information'));
        } else {
          final userId = snapshot.data!;
          return Container(
            margin: EdgeInsets.only(bottom: 20.0),
            padding: EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: 2),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: borderColor,
                  ),
                ),
                SizedBox(height: 10),
                ...items.map((item) {
                  final String? parcelName = item['domace_ime'] as String?;
                  final String parcelId = item['id'] as String;
                  final String kmgMidId = item['kmg_mid_id'].toString();

                  final double parcelAreaInM2 =
                      double.tryParse(item['m2'].toString()) ?? 0.0;
                  final double parcelAreaInAr = parcelAreaInM2 / 100;

                  return FutureBuilder<Map<String, dynamic>?>(
                    future: _firestoreHelper.getLastJobForParcel(
                        userId, kmgMidId, parcelId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                          margin: EdgeInsets.symmetric(vertical: 4.0),
                          child: CircularProgressIndicator(),
                        );
                      } else if (snapshot.hasError) {
                        return Container(
                          margin: EdgeInsets.symmetric(vertical: 4.0),
                          child: Text('Error loading job data'),
                        );
                      } else {
                        final lastJob = snapshot.data;
                        String detailType =
                            lastJob?['detail_type'] ?? 'No job data';
                        String jobType =
                            lastJob?['job_type'] ?? 'Unknown job type';

                        DateTime? parsedDateTime;
                        if (lastJob?['date_time'] != null) {
                          parsedDateTime =
                              DateTime.tryParse(lastJob!['date_time']);
                        }

                        String dateTime = parsedDateTime != null
                            ? DateFormat('dd.MM.yyyy HH:mm')
                                .format(parsedDateTime)
                            : 'Unknown date/time';

                        Color backgroundColor = _getFieldColor(detailType);

                        return Container(
                          margin: EdgeInsets.symmetric(vertical: 4.0),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            border: Border.all(color: Colors.black),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.all(8.0),
                            title: Row(
                              children: [
                                Text(parcelName ?? 'Unknown Parcel',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black)),
                                SizedBox(width: 8),
                                Text('${parcelAreaInAr.toStringAsFixed(2)} ar',
                                    style: TextStyle(color: Colors.black)),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Opravilo: $detailType',
                                    style: TextStyle(color: Colors.black)),
                                Text('Tip: $jobType',
                                    style: TextStyle(color: Colors.black)),
                                Text('Datum: $dateTime',
                                    style: TextStyle(color: Colors.black)),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.close),
                              color: Colors.black,
                              onPressed: () async {
                                bool? confirm =
                                    await _showDeleteConfirmation(context);
                                if (confirm == true) {
                                  await _deleteParcel(
                                      parcelId, int.parse(kmgMidId));
                                }
                              },
                            ),
                            onTap: () {
                              Navigator.of(context)
                                  .push(MaterialPageRoute(
                                builder: (context) =>
                                    FieldDetailsScreen(fieldId: parcelId),
                              ))
                                  .then((dataChanged) {
                                if (dataChanged == true) {
                                  final inputNumber =
                                      int.tryParse(_kmgController.text);
                                  if (inputNumber != null) {
                                    _loadDataFromFirestore(inputNumber);
                                  }
                                }
                              });
                            },
                          ),
                        );
                      }
                    },
                  );
                }).toList(),
              ],
            ),
          );
        }
      },
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Odstrani Parcelo'),
          content: Text(
              'Ali ste prepričani? Odstranjena bo vsa zgodovina dela za parcelo.'),
          actions: <Widget>[
            TextButton(
              child: Text('Prekliči'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Izbriši'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }
}
