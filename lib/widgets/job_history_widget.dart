import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class JobHistoryWidget extends StatefulWidget {
  final String userId;
  final String kmgMidId;
  final String fieldId;

  JobHistoryWidget({
    Key? key, // Accept the key parameter
    required this.userId,
    required this.kmgMidId,
    required this.fieldId,
  }) : super(key: key); // Pass the key to the parent class

  @override
  _JobHistoryWidgetState createState() => _JobHistoryWidgetState();
}

class _JobHistoryWidgetState extends State<JobHistoryWidget> {
  List<Map<String, dynamic>> _jobLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchJobLogs();
  }

  Future<void> _fetchJobLogs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot jobSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('kmg_mid')
          .doc(widget.kmgMidId)
          .collection('parcels')
          .doc(widget.fieldId)
          .collection('jobs')
          .get();

      List<Map<String, dynamic>> jobs = jobSnapshot.docs.map((doc) {
        return {
          'job_id': doc.id,
          'detail_type': doc['detail_type'],
          'job_type': doc['job_type'],
          'culture': doc['culture'],
          'sorta': doc['sorta'],
          'seed_quantity': doc['seed_quantity'],
          'fert_quantity': doc['fert_quantity'],
          'fert_type': doc['fert_type'],
          'spray_quantity': doc['spray_quantity'],
          'spray_type': doc['spray_type'],
          'bales_on_field': doc['bales_on_field'],
          'date_time': doc['date_time'],
        };
      }).toList();

      setState(() {
        _jobLogs = jobs;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching job logs: $e');
    }
  }

  Future<void> _deleteJob(String jobId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('kmg_mid')
        .doc(widget.kmgMidId)
        .collection('parcels')
        .doc(widget.fieldId)
        .collection('jobs')
        .doc(jobId)
        .delete();
    _fetchJobLogs(); // Refresh job logs after deletion
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
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : _jobLogs.isEmpty
            ? Center(child: Text('No job history found.'))
            : ListView.builder(
                // Remove Expanded from here
                itemCount: _jobLogs.length,
                itemBuilder: (context, index) {
                  final job = _jobLogs[index];
                  return ListTile(
                    title: _buildJobTitle(job),
                    subtitle: _buildJobSubtitle(job),
                    trailing: IconButton(
                      icon: Icon(Icons.close),
                      color: Colors.red,
                      onPressed: () async {
                        bool? confirm = await _showDeleteConfirmation(context);
                        if (confirm == true) {
                          await _deleteJob(job['job_id']);
                        }
                      },
                    ),
                  );
                },
              );
  }

  // Build the title row based on the job type
  Widget _buildJobTitle(Map<String, dynamic> job) {
    return Row(
      children: [
        Expanded(
          child: Text(
            // Combine 'detail_type' and 'sorta' into a single string
            job['detail_type'] +
                (job['detail_type'] == 'Setev' ||
                        job['detail_type'] == 'Ozelenitev'
                    ? ' ${job['culture'] ?? 'N/A'}'
                    : ''),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black, // Set the color to black
            ),
          ),
        ),
      ],
    );
  }

  // Build the subtitle based on the job details
  Widget _buildJobSubtitle(Map<String, dynamic> job) {
    switch (job['detail_type']) {
      case 'Setev':
        return Text(
          '${job['sorta'] ?? 'N/A'}, Količina semena: ${job['seed_quantity']} kg/ha\n'
          //'Količina semena: ${job['seed_quantity']} kg/ha\n'
          'Gnojilo: ${job['fert_type'] ?? 'N/A'}, ${job['fert_quantity']} kg/ha\n'
          'Date: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.parse(job['date_time']))}',
        );
      case 'Ozelenitev':
        return Text(
          'Količina semena: ${job['seed_quantity']} kg/ha\n'
          //'Količina semena: ${job['seed_quantity']} kg/ha\n'
          'Gnojilo: ${job['fert_type'] ?? 'N/A'}, ${job['fert_quantity']} kg/ha\n'
          'Date: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.parse(job['date_time']))}',
        );
      case 'Dognojevanje':
        return Text(
          'Tip gnojila: ${job['fert_type'] ?? 'N/A'}\n'
          'Količina gnojila: ${job['fert_quantity']} kg/ha\n'
          'Date: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.parse(job['date_time']))}',
        );
      case 'Škropljenje':
        return Text(
          'Spray Type: ${job['spray_type'] ?? 'N/A'}\n'
          'Spray Quantity: ${job['spray_quantity']} L/ha\n'
          'Date: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.parse(job['date_time']))}',
        );
      case 'Baliranje':
        return Text(
          'Bales on Field: ${job['bales_on_field']}\n'
          'Date: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.parse(job['date_time']))}',
        );
      case 'Žetev':
        return Text(
          '${job['culture']}\n'
          'Date: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.parse(job['date_time']))}',
        );
      case 'Priprava Zemlje':
        return Text(
          'Način: ${job['job_type']}\n'
          'Date: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.parse(job['date_time']))}',
        );
      default:
        return Text(
          'Job Type: ${job['job_type']}\n'
          'Date: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.parse(job['date_time']))}',
        );
    }
  }
}
