import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class PickupStatusDetailScreen extends StatefulWidget {
  final String pickupId;
  const PickupStatusDetailScreen({super.key, required this.pickupId});

  @override
  State<PickupStatusDetailScreen> createState() => _PickupStatusDetailScreenState();
}

class _PickupStatusDetailScreenState extends State<PickupStatusDetailScreen> {
  bool isLoading = true;

  Future<void> updateStatusBasedOnTime(DocumentSnapshot snapshot) async {
    try {
      Timestamp pickupDate = snapshot['date'];
      DateTime scheduledTime = pickupDate.toDate();
      DateTime now = DateTime.now();
      Duration diff = now.difference(scheduledTime);
      String status = snapshot['status'];

      if (diff.inHours >= 5 && status == 'out for pickup') {
        await FirebaseFirestore.instance
            .collection('pickups')
            .doc(widget.pickupId)
            .update({'status': 'collected'});
      } else if (diff.inHours >= 3 && status == 'in progress') {
        await FirebaseFirestore.instance
            .collection('pickups')
            .doc(widget.pickupId)
            .update({'status': 'out for pickup'});
      } else if (diff.inHours >= 1 && status == 'received') {
        await FirebaseFirestore.instance
            .collection('pickups')
            .doc(widget.pickupId)
            .update({'status': 'in progress'});
      }
    } catch (e) {
      debugPrint('Error in status update logic: $e');
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'received':
        return Colors.orange;
      case 'in progress':
        return Colors.blue;
      case 'out for pickup':
        return Colors.deepPurple;
      case 'collected':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> cancelPickup() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Pickup'),
        content: const Text('Are you sure you want to cancel this pickup?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
        ],
      ),
    );

    if (confirm) {
      await FirebaseFirestore.instance
          .collection('pickups')
          .doc(widget.pickupId)
          .update({'status': 'cancelled'});
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pickup Cancelled')),
      );
    }
  }

  Future<void> markAsCollected() async {
    await FirebaseFirestore.instance
        .collection('pickups')
        .doc(widget.pickupId)
        .update({'status': 'collected'});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: const Text('Pickup Details'), backgroundColor: Colors.deepPurpleAccent),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('pickups').doc(widget.pickupId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final pickupData = snapshot.data!;
          if (!pickupData.exists) return const Center(child: Text('No details found'));

          updateStatusBasedOnTime(pickupData); // Auto status update

          String wasteType = pickupData['wasteType'] ?? 'N/A';
          double quantity = pickupData['quantity'] ?? 0;
          String location = pickupData['location'] ?? 'N/A';
          Timestamp date = pickupData['date'] ?? Timestamp.now();
          String time = pickupData['time'] ?? 'N/A';
          String status = pickupData['status'] ?? 'N/A';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildCard(wasteType, quantity, location, date, time, status),
                const SizedBox(height: 20),
                Lottie.asset('assets/lottie/status.json', width: 300, height: 180),
                const SizedBox(height: 20),
                _cancelButton(status),
                const SizedBox(height: 10),
                _manualCollectedButton(status),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(String wasteType, double quantity, String location, Timestamp date, String time, String status) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Colors.deepPurpleAccent, Colors.black],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Waste Type: $wasteType", style: GoogleFonts.raleway(fontSize: 20, color: Colors.white)),
            const SizedBox(height: 10),
            Text("Quantity: $quantity kg", style: GoogleFonts.raleway(fontSize: 18, color: Colors.white70)),
            const SizedBox(height: 10),
            Text("Location: $location", style: GoogleFonts.raleway(fontSize: 18, color: Colors.white70)),
            const SizedBox(height: 10),
            Text("Date: ${date.toDate().toLocal().toString().split(' ')[0]}",
                style: GoogleFonts.raleway(fontSize: 18, color: Colors.white70)),
            const SizedBox(height: 10),
            Text("Time: $time", style: GoogleFonts.raleway(fontSize: 18, color: Colors.white70)),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text("Status: ", style: TextStyle(fontSize: 18, color: Colors.white)),
                Chip(
                  label: Text(
                    status.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: getStatusColor(status),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cancelButton(String status) {
    // Only allow cancel if status is 'received' or 'in progress'
    if (status == 'received' || status == 'in progress') {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        onPressed: cancelPickup,
        child: const Text('Cancel Pickup', style: TextStyle(color: Colors.white)),
      );
    } else {
      return const SizedBox(); 
    }
  }

  Widget _manualCollectedButton(String status) {
    if(status == 'received' || status == 'in progress' || status == 'out for pickup'){
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
      onPressed: markAsCollected,
      child: const Text('Mark as Collected', style: TextStyle(color: Colors.white)),
    );
  }else{
    return const SizedBox();
  }
}
}