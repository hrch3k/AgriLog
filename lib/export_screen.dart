import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'database_helper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert'; // Import the dart:convert for utf8 encoding
import 'package:intl/intl.dart'; // Import for date formatting

class ExportScreen extends StatefulWidget {
  @override
  _ExportScreenState createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  String? _selectedJobType;
  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> _jobTypes = [
    'Priprava Zemlje',
    'Setev',
    'Škropljenje',
    'Žetev',
    'Dognojevanje',
    'Baliranje',
  ];

  // Define job-specific headers and data keys
  final Map<String, List<String>> jobSpecificHeaders = {
    'Setev': ['Kultura', 'Količina semena', 'Količina gnojila'],
    'Priprava Zemlje': ['Tip'],
    'Žetev': [],
    'Baliranje': ['St.Bal'],
    'Dognojevanje': ['Tip', 'Količina Gnojila'],
    'Škropljenje': ['Tip', 'Količina Škropiva'],
  };

  // Define job-specific data keys
  final Map<String, List<String>> jobSpecificDataKeys = {
    'Setev': ['type', 'seed_quantity', 'fert_quantity'],
    'Priprava Zemlje': ['type'],
    'Žetev': [],
    'Baliranje': ['bales_on_field'],
    'Dognojevanje': ['type', 'fert_quantity'],
    'Škropljenje': ['type', 'spray_quantity'],
  };

  Future<void> _exportData() async {
    // Request permission first
    if (!await _requestPermissions()) {
      return; // Exit if permission is not granted
    }

    if (_selectedJobType == null || _startDate == null || _endDate == null) {
      _showSnackbar('Izberite opravilo in interval datumov');
      return;
    }

    DatabaseHelper dbHelper = DatabaseHelper();
    List<Map<String, dynamic>> jobDetails =
        await dbHelper.getJobDetailsByType(_selectedJobType!);

    // Filter jobs by the selected date range (including boundary dates)
    jobDetails = jobDetails.where((jobDetail) {
      String? dateTimeString = jobDetail['date_time']?.toString();
      if (dateTimeString != null && dateTimeString.isNotEmpty) {
        DateTime jobDate = DateTime.parse(dateTimeString);
        return (jobDate.isAtSameMomentAs(_startDate!) ||
                jobDate.isAfter(_startDate!)) &&
            (jobDate.isBefore(_endDate!.add(Duration(days: 1))));
      }
      return false;
    }).toList();

    if (jobDetails.isEmpty) {
      _showSnackbar('Ni podatkov za izbrani interval');
      return;
    }

    // Prepare CSV data with initial headers
    List<String> headers = ['Domace ime', 'GERK-pid', 'M2', 'Opravilo'];
    if (jobSpecificHeaders[_selectedJobType] != null) {
      headers.addAll(jobSpecificHeaders[_selectedJobType]!);
    }
    headers.add('Datum'); // Add common "Datum" header

    List<List<String>> csvData = [headers];

    // Prepare CSV rows
    for (var jobDetail in jobDetails) {
      List<String> row = [
        jobDetail['domace_ime'] ?? '',
        jobDetail['gerk_pid']?.toString() ?? '',
        jobDetail['m2']?.toString() ?? '',
        jobDetail['detail_type'] ?? '',
      ];

      // Add job-specific data
      List<String>? dataKeys = jobSpecificDataKeys[_selectedJobType];
      if (dataKeys != null) {
        for (String key in dataKeys) {
          row.add(jobDetail[key]?.toString() ?? '');
        }
      }

      // Format the date and add it to the row
      String? dateTimeString = jobDetail['date_time']?.toString();
      if (dateTimeString != null && dateTimeString.isNotEmpty) {
        // Parse and format the date
        DateTime parsedDate = DateTime.parse(dateTimeString);
        String formattedDate =
            DateFormat('dd.MM.yyyy HH:mm').format(parsedDate);
        row.add(formattedDate); // Add formatted date
      } else {
        row.add(''); // Add empty value if no date is available
      }

      csvData.add(row);
    }

    // Convert CSV data to a CSV string
    String csv = const ListToCsvConverter().convert(csvData);

    // Save the file in the Downloads folder
    Directory? downloadsDirectory = Directory('/storage/emulated/0/Download');
    if (!downloadsDirectory.existsSync()) {
      downloadsDirectory =
          await getExternalStorageDirectory(); // Fallback to internal directory
    }

    if (downloadsDirectory == null) {
      _showSnackbar('Ni mogoče dostopati do shrambe');
      return;
    }

    String fileName = 'export_${_selectedJobType!.replaceAll(' ', '_')}.csv';
    File file = File('${downloadsDirectory.path}/$fileName');

    // Add UTF-8 BOM to ensure correct encoding in software like Excel
    List<int> bom = [0xEF, 0xBB, 0xBF]; // UTF-8 BOM
    await file.writeAsBytes(bom, mode: FileMode.write); // Write BOM
    await file.writeAsString(csv,
        mode: FileMode.append, encoding: utf8); // Write CSV content

    _showSnackbar('Podatki izvoženi $fileName v ${downloadsDirectory.path}');
  }

  Future<bool> _requestPermissions() async {
    if (await Permission.storage.request().isGranted ||
        await Permission.manageExternalStorage.request().isGranted) {
      return true;
    } else {
      _showSnackbar('Dostop do shrambe je potreben za izvoz podatkov.');
      return false;
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        if (isStart) {
          _startDate = pickedDate;
        } else {
          _endDate = pickedDate;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Izvozi Podatke'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Izberite opravilo in interval datumov za izvoz v .csv',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            DropdownButton<String>(
              value: _selectedJobType,
              hint: Text('Izberi Opravilo'),
              isExpanded: true,
              items: _jobTypes.map((String jobType) {
                return DropdownMenuItem<String>(
                  value: jobType,
                  child: Text(jobType),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedJobType = newValue;
                });
              },
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _selectDate(context, true),
                    child: Text(_startDate == null
                        ? 'Izberite začetni datum'
                        : DateFormat('dd.MM.yyyy').format(_startDate!)),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _selectDate(context, false),
                    child: Text(_endDate == null
                        ? 'Izberite končni datum'
                        : DateFormat('dd.MM.yyyy').format(_endDate!)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                onPressed: _exportData,
                child: Text('Izvozi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
