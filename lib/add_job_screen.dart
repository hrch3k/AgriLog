import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'package:intl/intl.dart';

class AddJobScreen extends StatefulWidget {
  final int parcelId;
  final String actionType;

  AddJobScreen({required this.parcelId, required this.actionType});

  @override
  _AddJobScreenState createState() => _AddJobScreenState();
}

class _AddJobScreenState extends State<AddJobScreen> {
  final List<String> _jobTypes = ['Plug', 'Tiler', 'Riper', 'Disk', 'Mulčanje'];
  String? _selectedJobType;
  DateTime _selectedDateTime = DateTime.now();
  final TextEditingController _cultureController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _seedQuantityController = TextEditingController();
  final TextEditingController _fertQuantityController = TextEditingController();
  final TextEditingController _sprayQuantityController =
      TextEditingController();
  final TextEditingController _typeController = TextEditingController();

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
          // Fix the order of arguments in DateTime constructor
          _selectedDateTime = DateTime(
            pickedDate.year, // year first
            pickedDate.month, // month second
            pickedDate.day, // day third
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

    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    final isPripravaZemlje = widget.actionType == 'Priprava Zemlje';
    final isSetevOrSimilar = widget.actionType == 'Setev' ||
        widget.actionType == 'Dognojevanje' ||
        widget.actionType == 'Škropljenje';

    final jobType = isPripravaZemlje
        ? _selectedJobType
        : (widget.actionType == 'Baliranje' || widget.actionType == 'Žetev')
            ? widget.actionType
            : _typeController.text;

    int jobId = await db.insert('jobs', {
      'parcel_id': widget.parcelId,
      'detail_type': widget.actionType,
      'job_type': jobType,
      'date_time': _selectedDateTime.toIso8601String(),
    });

    await db.insert('job_details', {
      'job_id': jobId,
      'detail_type': widget.actionType,
      'type': jobType,
      'culture': _cultureController.text,
      'seed_quantity': isSetevOrSimilar
          ? int.tryParse(_seedQuantityController.text) ?? 0
          : 0,
      'fert_quantity': isSetevOrSimilar
          ? int.tryParse(_fertQuantityController.text) ?? 0
          : 0,
      'spray_quantity': isSetevOrSimilar
          ? int.tryParse(_sprayQuantityController.text) ?? 0
          : 0,
      'bales_on_field': widget.actionType == 'Baliranje'
          ? int.tryParse(_quantityController.text) ?? 0
          : 0,
      'date_time': _selectedDateTime.toIso8601String(),
    });

    Navigator.of(context).pop(true);
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
          key: _formKey, // Add the Form widget with a GlobalKey
          child: Column(
            children: [
              if (widget.actionType == 'Setev') ...[
                _buildTextField('Kultura', '', _typeController,
                    isMandatory: true),
                _buildTextField(
                    'Količina semena', 'kg/ha', _seedQuantityController,
                    isMandatory: true),
                _buildTextField('Dodano gnojilo', 'NPK, Orea, KAN',
                    TextEditingController()),
                _buildTextField(
                    'Količina Gnojila', 'kg/ha', _fertQuantityController),
              ],
              if (widget.actionType == 'Dognojevanje') ...[
                _buildTextField('Gnojilo', 'NPK, Orea, KAN', _typeController,
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
                _buildTextField('Tip Škropiva', '', _typeController,
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
