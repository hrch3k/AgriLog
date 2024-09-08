import 'package:flutter/material.dart';
import 'data_service.dart'; // Import DataService
import 'details_screen.dart';
import 'database_helper.dart';
import 'add_field_screen.dart';
import 'package:intl/intl.dart';
import 'export_screen.dart';
import 'package:firebase_core/firebase_core.dart'; // Import Firebase core

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  print('Firebase Initialized Successfully');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Farmer SI',
      home: DataScreen(),
    );
  }
}

class DataScreen extends StatefulWidget {
  @override
  _DataScreenState createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  final DataService _dataService = DataService();
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _data = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLastKmgMidData(); // Load parcels for the last added kmg_mid on startup
  }

  Future<void> _loadLastKmgMidData() async {
    DatabaseHelper dbHelper = DatabaseHelper();

    // Fetch the last kmg_mid
    int? lastKmgMid = await dbHelper.getLastKmgMid();

    if (lastKmgMid != null) {
      _controller.text =
          lastKmgMid.toString(); // Update the controller with the last kmg_mid
      _loadDataFromDatabase(lastKmgMid);
    }
  }

  Future<void> _loadDataFromDatabase(int inputNumber) async {
    setState(() {
      _isLoading = true;
    });

    await _loadData(inputNumber);

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.text.isNotEmpty) {
      final inputNumber = int.tryParse(_controller.text);
      if (inputNumber != null) {
        _loadDataFromDatabase(inputNumber);
      }
    }
  }

  Future<void> _fetchData(int inputNumber) async {
    setState(() {
      _isLoading = true;
    });

    await _dataService.fetchDataAndSaveToDatabase(inputNumber);
    await _loadData(inputNumber);

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadData(int inputNumber) async {
    List<Map<String, dynamic>> data =
        await _dataService.getParcelsForKmgMid(inputNumber);
    setState(() {
      _data = data;
    });
  }

  Future<Map<String, dynamic>?> _getLastJobForParcel(int parcelId) async {
    DatabaseHelper dbHelper = DatabaseHelper();
    return await dbHelper.getLastJobForParcel(parcelId);
  }

  Future<void> _deleteParcel(int parcelId) async {
    DatabaseHelper dbHelper = DatabaseHelper();
    await dbHelper.deleteParcel(parcelId);
    setState(() {
      // Reload the data after deletion
      final inputNumber = int.tryParse(_controller.text);
      if (inputNumber != null) {
        _loadDataFromDatabase(inputNumber);
      }
    });
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
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> gerkItems =
        _data.where((item) => item['is_gerk'] == 1).toList();
    List<Map<String, dynamic>> nonGerkItems =
        _data.where((item) => item['is_gerk'] != 1).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Farmer SI'),
        actions: [
          PopupMenuButton<String>(
            onSelected: _onSelectedMenuOption,
            itemBuilder: (BuildContext context) {
              return {'Izvozi Podatke'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
            icon: Icon(Icons.settings),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Vnesi KMG-MID',
                    ),
                  ),
                ),
                SizedBox(width: 10),
                SizedBox(
                  width: 100,
                  child: ElevatedButton(
                    onPressed: () {
                      final inputNumber = int.tryParse(_controller.text);
                      if (inputNumber != null) {
                        _fetchData(inputNumber);
                      }
                    },
                    child: Text('Pridobi GERK-e'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : Expanded(
                    child: ListView(
                      children: [
                        if (gerkItems.isNotEmpty) ...[
                          _buildItemsContainer(
                              items: gerkItems,
                              title: 'GERK',
                              borderColor: Colors.green),
                        ],
                        if (nonGerkItems.isNotEmpty) ...[
                          _buildItemsContainer(
                              items: nonGerkItems,
                              title: 'Brez GERK-a',
                              borderColor: Colors.black),
                        ],
                      ],
                    ),
                  ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context)
              .push(
            MaterialPageRoute(
              builder: (context) => NewFieldScreen(),
            ),
          )
              .then((_) {
            setState(() {
              final inputNumber = int.tryParse(_controller.text);
              if (inputNumber != null) {
                _loadDataFromDatabase(inputNumber);
              }
            });
          });
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildItemsContainer({
    required List<Map<String, dynamic>> items,
    required String title,
    required Color borderColor,
  }) {
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
            return FutureBuilder<Map<String, dynamic>?>(
              future: _getLastJobForParcel(item['id']),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 4.0),
                    height: 100.0,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                var lastJob = snapshot.data;
                String detailType = lastJob?['detail_type'] ?? 'No job data';
                String jobType = lastJob?['job_type'] ?? 'Unknown job type';

                DateTime? parsedDateTime;
                if (lastJob?['date_time'] != null) {
                  parsedDateTime = DateTime.parse(lastJob!['date_time']);
                }

                String dateTime = parsedDateTime != null
                    ? DateFormat('dd.MM.yyyy HH:mm').format(parsedDateTime)
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
                    title: Text(
                      item['domace_ime'],
                      style: TextStyle(color: Colors.black),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Opravilo: $detailType',
                          style: TextStyle(color: Colors.black),
                        ),
                        Text(
                          'Tip: $jobType',
                          style: TextStyle(color: Colors.black),
                        ),
                        Text(
                          'Datum: $dateTime',
                          style: TextStyle(color: Colors.black),
                        ),
                        Text(
                          'Površina: ${item['m2'] / 100} ar',
                          style: TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.close),
                      color: Colors.black,
                      onPressed: () async {
                        bool? confirm = await _showDeleteConfirmation(context);
                        if (confirm == true) {
                          await _deleteParcel(item['id']);
                        }
                      },
                    ),
                    onTap: () {
                      Navigator.of(context)
                          .push(
                        MaterialPageRoute(
                          builder: (context) =>
                              FieldDetailsScreen(fieldId: item['id']),
                        ),
                      )
                          .then((dataChanged) {
                        if (dataChanged == true) {
                          final inputNumber = int.tryParse(_controller.text);
                          if (inputNumber != null) {
                            _loadDataFromDatabase(inputNumber);
                          }
                        }
                      });
                    },
                  ),
                );
              },
            );
          }).toList(),
        ],
      ),
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
