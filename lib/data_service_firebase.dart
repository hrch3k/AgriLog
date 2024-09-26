import 'package:http/http.dart' as http;
import 'dart:convert';
import 'firebase_helper.dart'; // Import Firestore helper

class DataService {
  final FirestoreHelper _firestoreHelper =
      FirestoreHelper(); // Use FirestoreHelper

  Future<void> fetchDataAndSaveToFirestore(int inputNumber) async {
    // Check if kmg_mid already exists in Firestore
    final existingKmgMid = await _firestoreHelper.getKmgMidById(inputNumber);

    // If KMG-MID exists, no need to fetch new data from API
    if (existingKmgMid != null) {
      print('KMG-MID already exists in Firestore. Skipping API fetch.');
      return;
    }

    try {
      // Fetch data from API if KMG-MID does not exist
      final response = await http.get(Uri.parse(
          "https://lokic.si/scrape/" + inputNumber.toString())); // Example URL

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);

        // Insert KMG-MID to Firestore
        await _firestoreHelper.insertKmgMid(inputNumber);

        // Save each parcel to Firestore
        for (var item in data) {
          Map<String, dynamic> parcelData = {
            'kmg_mid_id': inputNumber,
            'gerk_pid': item['GERK_PID'],
            'blok_id': item['BLOK_ID'],
            'm2': item['M2'],
            'is_gerk': true,
            'domace_ime': item['DOMACE_IME'],
          };

          // Insert or update the parcel in Firestore
          await _firestoreHelper.insertOrUpdateParcel(parcelData);
        }

        print('Data saved to Firestore successfully');
      } else {
        print('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getParcelsForKmgMid(int kmgMidId) async {
    // Retrieve parcels for the specific kmg_mid from Firestore
    return await _firestoreHelper.getParcelsForKmgMid(kmgMidId);
  }
}
