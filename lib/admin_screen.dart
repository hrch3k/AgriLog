import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminToolsScreen extends StatefulWidget {
  @override
  _AdminToolsScreenState createState() => _AdminToolsScreenState();
}

class _AdminToolsScreenState extends State<AdminToolsScreen> {
  @override
  void initState() {
    super.initState();
    _fetchAllTickets();
  }

  Future<List<Map<String, dynamic>>> _fetchAllTickets() async {
    List<Map<String, dynamic>> allTickets = [];

    try {
      QuerySnapshot usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      for (var userDoc in usersSnapshot.docs) {
        String userId = userDoc.id;
        String userEmail = userDoc['email'] ?? 'No email';

        QuerySnapshot feedbackSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('feedback_tickets')
            .get();

        for (var ticketDoc in feedbackSnapshot.docs) {
          allTickets.add({
            'userId': userId,
            'ticketId': ticketDoc.id,
            'email': userEmail,
            'title': ticketDoc['title'],
            'message': ticketDoc['message'],
            'timestamp': ticketDoc['timestamp'],
          });
        }
      }

      // Sort by timestamp before returning the list
      allTickets.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
    } catch (e) {
      print('Error fetching feedback tickets: $e');
    }

    return allTickets;
  }

  // Function to delete a feedback ticket
  Future<void> _deleteTicket(String userId, String ticketId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('feedback_tickets')
          .doc(ticketId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Ticket deleted successfully!'),
      ));

      // Reload the tickets after deletion
      setState(() {
        _fetchAllTickets();
      });
    } catch (e) {
      print('Error deleting ticket: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error deleting ticket. Please try again.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Tools - Feedback Tickets'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchAllTickets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No feedback tickets found.'));
          }

          List<Map<String, dynamic>> tickets = snapshot.data!;

          return ListView.builder(
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> ticket = tickets[index];
              return Card(
                margin: EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(ticket['title']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email: ${ticket['email']}'),
                      Text('Message: ${ticket['message']}'),
                      Text('Timestamp: ${ticket['timestamp'].toDate()}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      bool? confirm = await _showDeleteConfirmation(context);
                      if (confirm == true) {
                        _deleteTicket(ticket['userId'], ticket['ticketId']);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Show confirmation dialog before deleting a ticket
  Future<bool?> _showDeleteConfirmation(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Ticket'),
          content: Text('Are you sure you want to delete this ticket?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false); // Cancel deletion
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop(true); // Confirm deletion
              },
            ),
          ],
        );
      },
    );
  }
}
