import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // For launching the PayPal URL

class DonateDialog {
  static Future<void> showDonationDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Support AgriLog'),
          content: Text(
              'Thank you for using AgriLog! We rely on donations to help cover the costs of servers, maintenance, and future improvements. Your support helps us keep the app running smoothly for everyone.'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              onPressed: () {
                _launchPayPalDonation(); // Call the PayPal donation function
              },
              child: Text('Doniraj'),
            ),
          ],
        );
      },
    );
  }

  // Function to launch the PayPal donation URL
  static Future<void> _launchPayPalDonation() async {
    const url = 'https://www.paypal.com/donate?hosted_button_id=TVMH2QM5EZQYW';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch PayPal donation link';
    }
  }
}
