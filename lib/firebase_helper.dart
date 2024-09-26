import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreHelper {
  static final FirestoreHelper _instance = FirestoreHelper._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth =
      FirebaseAuth.instance; // Initialize _auth with FirebaseAuth.instance

  factory FirestoreHelper() {
    return _instance;
  }

  FirestoreHelper._internal();

  /// Get the currently logged-in user's ID
  Future<String?> getUserId() async {
    User? user = _auth.currentUser;
    return user?.uid;
  }

  /// Helper to get the current user ID from Firebase Authentication
  String getCurrentUserId() {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("No user logged in");
    return user.uid;
  }

  /// Check if the current user is an admin
  Future<bool> isAdmin() async {
    final String userId = getCurrentUserId();
    final DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userId).get();

    if (userDoc.exists && userDoc.data() != null) {
      return userDoc.get('isAdmin') == true;
    }

    return false;
  }

  /// **KMG-MID Functions**

  // Check if a specific KMG-MID exists in Firestore
  Future<DocumentSnapshot<Map<String, dynamic>>?> getKmgMidById(
      int kmgMidId) async {
    final String userId = getCurrentUserId();
    final kmgMidRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('kmg_mid')
        .doc(kmgMidId.toString());

    DocumentSnapshot<Map<String, dynamic>> doc = await kmgMidRef.get();
    if (doc.exists) {
      return doc; // Return the document if it exists
    } else {
      return null; // Return null if the document does not exist
    }
  }

  Future<void> insertKmgMid(int kmgMid) async {
    final String userId = getCurrentUserId();
    final kmgMidRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('kmg_mid')
        .doc(kmgMid.toString());

    await kmgMidRef.set({'active': true});

    // Optionally, deactivate all other KMG-MID entries for this user
    QuerySnapshot snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('kmg_mid')
        .get();
    for (DocumentSnapshot doc in snapshot.docs) {
      if (doc.id != kmgMid.toString()) {
        await doc.reference.update({'active': false});
      }
    }
  }

  /// Get parcels for a specific KMG-MID
  Future<List<Map<String, dynamic>>> getParcelsForKmgMid(int kmgMidId) async {
    final String userId = getCurrentUserId();
    QuerySnapshot snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('kmg_mid')
        .doc(kmgMidId.toString())
        .collection('parcels')
        .get();

    // Ensure that the data returned is a list of Maps
    return snapshot.docs.map((doc) {
      var data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id; // Ensure the document ID is included as 'id'
      return data;
    }).toList();
  }

  /// Insert or update a parcel document
  Future<void> insertOrUpdateParcel(Map<String, dynamic> parcelData) async {
    final String userId = getCurrentUserId();
    final parcelRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('kmg_mid')
        .doc(parcelData['kmg_mid_id'].toString())
        .collection('parcels')
        .doc(); // Automatically generate a new parcel document ID

    await parcelRef.set(
      parcelData,
      SetOptions(merge: true), // Merge to update the parcel data if it exists
    );
  }

  /// Update an existing parcel
  Future<void> updateParcel(
      int kmgMidId, String parcelId, Map<String, dynamic> updates) async {
    final String userId = getCurrentUserId();
    final parcelRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('kmg_mid')
        .doc(kmgMidId.toString())
        .collection('parcels')
        .doc(parcelId);

    await parcelRef.update(updates); // Update only the provided fields
  }

  /// Get a specific parcel by its ID
  Future<Map<String, dynamic>?> getParcelById(
      int kmgMidId, String parcelId) async {
    final String userId = getCurrentUserId();
    print(
        "Getting parcel for user: $userId, kmgMidId: $kmgMidId, parcelId: $parcelId");
    final parcelRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('kmg_mid')
        .doc(kmgMidId.toString())
        .collection('parcels')
        .doc(parcelId);

    DocumentSnapshot doc = await parcelRef.get();
    if (doc.exists) {
      print("Parcel data found: ${doc.data()}");
      return doc.data() as Map<String, dynamic>?;
    } else {
      print("No parcel found for parcelId: $parcelId");
      return null;
    }
  }

  /// Delete a specific parcel from Firestore
  Future<void> deleteParcel(String parcelId, int kmgMidId) async {
    final String userId = getCurrentUserId();
    final parcelRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('kmg_mid')
        .doc(kmgMidId.toString())
        .collection('parcels')
        .doc(parcelId);

    // Delete the parcel
    await parcelRef.delete();
  }

  /// Get the last active KMG-MID
  Future<int?> getLastKmgMid() async {
    final String userId = getCurrentUserId();
    QuerySnapshot snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('kmg_mid')
        .where('active', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return int.tryParse(snapshot.docs.first.id); // Parse the ID to int
    } else {
      return null;
    }
  }

  /// Get the last job for a specific parcel (gerk_pid)

  Future<Map<String, dynamic>?> getLastJobForParcel(
      String userId, String kmgMid, String parcelId) async {
    try {
      QuerySnapshot jobSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('kmg_mid')
          .doc(kmgMid)
          .collection('parcels')
          .doc(parcelId)
          .collection('jobs')
          .orderBy('date_time', descending: true)
          .limit(1)
          .get();

      if (jobSnapshot.docs.isNotEmpty) {
        return jobSnapshot.docs.first.data() as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching last job for parcel: $e');
      return null;
    }
  }

  /// Get all jobs for a specific parcel (gerk_pid)
  Future<List<Map<String, dynamic>>> getJobsForParcel(String parcelId) async {
    final String userId = getCurrentUserId();

    QuerySnapshot snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('jobs')
        .where('parcel_id',
            isEqualTo: parcelId) // Assuming jobs link to parcel via parcel_id
        .orderBy('date_time', descending: true) // Order by the most recent
        .get();

    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  /// Delete a specific job from Firestore
  Future<void> deleteJob(String jobId) async {
    final String userId = getCurrentUserId();
    final jobRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('jobs')
        .doc(jobId);

    await jobRef.delete();
  }

  Future<bool> checkParcelExists(int kmgMidId, String parcelId) async {
    final String userId = getCurrentUserId();
    final parcelRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('kmg_mid')
        .doc(kmgMidId.toString())
        .collection('parcels')
        .doc(parcelId);

    DocumentSnapshot doc = await parcelRef.get();
    return doc.exists; // Return true if the document exists, false otherwise
  }
}
