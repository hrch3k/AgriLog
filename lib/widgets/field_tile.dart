import 'package:flutter/material.dart';
import '../firebase_helper.dart';

class FieldTile extends StatelessWidget {
  final String parcelName;
  final double parcelAreaInAr;
  final String kmgMidId;
  final String parcelId;
  final String userId;
  final FirestoreHelper firestoreHelper;
  final VoidCallback onDelete;

  FieldTile({
    required this.parcelName,
    required this.parcelAreaInAr,
    required this.kmgMidId,
    required this.parcelId,
    required this.userId,
    required this.firestoreHelper,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: firestoreHelper.getLastJobForParcel(userId, kmgMidId, parcelId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error loading job data');
        } else {
          final lastJob = snapshot.data;
          String detailType = lastJob?['detail_type'] ?? 'No job data';
          String jobType = lastJob?['job_type'] ?? 'Unknown job type';
          String dateTime = lastJob?['date_time'] ?? 'Unknown date/time';

          return ListTile(
            contentPadding: EdgeInsets.all(8.0),
            title: Row(
              children: [
                Text(parcelName, style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                Text('${parcelAreaInAr.toStringAsFixed(2)} ar'),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Opravilo: $detailType'),
                Text('Tip: $jobType'),
                Text('Datum: $dateTime'),
              ],
            ),
            trailing: IconButton(
              icon: Icon(Icons.close),
              onPressed: onDelete,
            ),
          );
        }
      },
    );
  }
}
