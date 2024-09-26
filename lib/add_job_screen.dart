import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AddJobScreen extends StatefulWidget {
  final String userId; // User ID of the logged-in user
  final String kmgMid; // Dynamic kmg_mid field
  final String parcelId; // The ID of the specific parcel
  final String actionType; // The action type for the job

  AddJobScreen({
    required this.userId,
    required this.kmgMid,
    required this.parcelId,
    required this.actionType,
  });

  @override
  _AddJobScreenState createState() => _AddJobScreenState();
}

class _AddJobScreenState extends State<AddJobScreen> {
  final List<String> _jobTypes = ['Plug', 'Tiler', 'Riper', 'Disk'];
  String? _selectedJobType;
  DateTime _selectedDateTime = DateTime.now();
  final TextEditingController _cultureController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _seedQuantityController = TextEditingController();
  final TextEditingController _fertQuantityController = TextEditingController();
  final TextEditingController _sprayQuantityController =
      TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _sortaController =
      TextEditingController(); // Add this for Sorta

  final TextEditingController _fertTypeController = TextEditingController();
  final TextEditingController _sprayTypeController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _saveJobDetails() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final isPripravaZemlje = widget.actionType == 'Priprava Zemlje';
    final isSetevOrSimilar = widget.actionType == 'Setev' ||
        widget.actionType == 'Dognojevanje' ||
        widget.actionType == 'Škropljenje' ||
        widget.actionType == 'Ozelenitev';

    final jobType = isPripravaZemlje
        ? _selectedJobType
        : (widget.actionType == 'Baliranje' || widget.actionType == 'Žetev')
            ? widget.actionType
            : _typeController.text;

    try {
      // Firestore reference to the correct path
      final firestore = FirebaseFirestore.instance;

      // Reference the path: /users/{userId}/kmg_mid/{kmgMid}/parcels/{parcelId}/jobs
      DocumentReference parcelRef = firestore
          .collection('users')
          .doc(widget.userId)
          .collection('kmg_mid')
          .doc(widget.kmgMid)
          .collection('parcels')
          .doc(widget.parcelId);

      // Consolidate all job details into one document in the "jobs" subcollection
      await parcelRef.collection('jobs').add({
        'parcel_id': widget.parcelId,
        'detail_type': widget.actionType,
        'job_type': jobType,
        'culture': _cultureController.text,
        'sorta': _sortaController.text,
        'seed_quantity': isSetevOrSimilar
            ? int.tryParse(_seedQuantityController.text) ?? 0
            : 0,
        'fert_quantity': isSetevOrSimilar
            ? int.tryParse(_fertQuantityController.text) ?? 0
            : 0,
        'fert_type': isSetevOrSimilar ? _fertTypeController.text ?? 0 : 0,
        'spray_quantity': isSetevOrSimilar
            ? int.tryParse(_sprayQuantityController.text) ?? 0
            : 0,
        'spray_type': isSetevOrSimilar ? _sprayTypeController.text ?? 0 : 0,
        'bales_on_field': widget.actionType == 'Baliranje'
            ? int.tryParse(_quantityController.text) ?? 0
            : 0,
        'date_time': _selectedDateTime.toIso8601String(),
      });

      // After successful job creation, return true to signal success
      Navigator.of(context)
          .pop(true); // This signals back to details_screen.dart
    } catch (e) {
      print('Error saving job details: $e');
    }
  }

  Widget _buildTextField(
      String label, String hint, TextEditingController controller,
      {bool isMandatory = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
      validator: isMandatory
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Polje je obvezno';
              }
              return null;
            }
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.actionType),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (widget.actionType == 'Setev' ||
                  widget.actionType == 'Ozelenitev') ...[
                _buildTextField('Kultura', '', _cultureController,
                    isMandatory: true),
                _buildTextField('Sorta', '', _sortaController,
                    isMandatory: false),
                // New Sorta field
                _buildTextField(
                    'Količina semena', 'kg/ha', _seedQuantityController,
                    isMandatory: true),
                _buildTextField(
                    'Dodano gnojilo', 'NPK, Orea, KAN', _fertTypeController),
                _buildTextField(
                    'Količina Gnojila', 'kg/ha', _fertQuantityController),
              ],
              if (widget.actionType == 'Dognojevanje') ...[
                _buildTextField(
                    'Gnojilo', 'NPK, Orea, KAN', _fertTypeController,
                    isMandatory: true),
                _buildTextField(
                    'Količina gnojila', 'kg/ha', _fertQuantityController,
                    isMandatory: true),
              ],
              if (widget.actionType == 'Baliranje') ...[
                _buildTextField('Št. Bal', 'kom', _quantityController,
                    isMandatory: true),
              ],
              if (widget.actionType == 'Škropljenje') ...[
                _buildTextField('Tip Škropiva', '', _sprayTypeController,
                    isMandatory: true),
                _buildTextField(
                    'Količina škropiva', 'L/L', _sprayQuantityController,
                    isMandatory: true),
              ],
              if (widget.actionType == 'Priprava Zemlje') ...[
                DropdownButtonFormField<String>(
                  value: _selectedJobType,
                  decoration: InputDecoration(labelText: 'Opravilo'),
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
                  validator: (value) =>
                      value == null ? 'Izberite opravilo' : null,
                ),
              ],
              SizedBox(height: 20),
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Date/Time',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () => _selectDateTime(context),
                  ),
                ),
                controller: TextEditingController(
                  text:
                      DateFormat('dd.MM.yyyy HH:mm').format(_selectedDateTime),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveJobDetails,
                child: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
