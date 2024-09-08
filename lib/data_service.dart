import 'package:http/http.dart' as http;
import 'dart:convert';
import 'database_helper.dart';

class DataService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> fetchDataAndSaveToDatabase(int inputNumber) async {
    try {
      // Modify the URL if needed to pass the inputNumber  http://10.0.2.2:5000/scrape/
      final response = await http.get(Uri.parse(
          /*'http://192.168.1.59:5000/scrape/'*/
          /*"http://10.0.2.2:5000/scrape/" */
          "https://lokic.si/scrape/" + inputNumber.toString())); // Example URL

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);

        // Clear existing data in the database
        //await _dbHelper.deleteAllKmgMids();

        // Save each item to the database
        for (var item in data) {
          // Insert parcel data
          Map<String, dynamic> parcelData = {
            'kmg_mid_id': inputNumber,
            'gerk_pid': item['GERK_PID'],
            'blok_id': item['BLOK_ID'],
            'm2': item['M2'],
            'is_gerk': true,
            'domace_ime': item['DOMACE_IME'],
          };
          int parcelId = await _dbHelper.insertOrUpdateParcel(parcelData);
          int kmgmidId = await _dbHelper.insertKmgMid(inputNumber);
        }

        print('Data saved to database successfully');
      } else {
        print('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  Future<int> insertKmgMid(int kmgMid) async {
    return await _dbHelper.insertKmgMid(kmgMid);
  }

  Future<List<Map<String, dynamic>>> getParcelsForKmgMid(int kmgMidId) async {
    return await _dbHelper.getParcelsForKmgMid(kmgMidId);
  }
}
