import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pickup_status_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String selectedStatus = 'All';
  final List<String> statusOptions = ['All', 'received', 'in progress', 'collected', 'cancelled'];

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Pickup History"),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          _buildAttractiveDropdown(),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('pickups')
                  .where('userId', isEqualTo: user!.uid)
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                var pickups = snapshot.data!.docs;
                if (selectedStatus != 'All') {
                  pickups = pickups.where((doc) => doc['status'] == selectedStatus).toList();
                }

                if (pickups.isEmpty) {
                  return const Center(child: Text("No pickup history found", style: TextStyle(fontSize: 16)));
                }

                return ListView.builder(
                  itemCount: pickups.length,
                  itemBuilder: (context, index) {
                    var data = pickups[index].data() as Map<String, dynamic>;
                    DateTime date = (data['date'] as Timestamp).toDate();

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PickupStatusDetailScreen(pickupId: pickups[index].id),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            gradient: const LinearGradient(
                              colors: [Colors.deepPurpleAccent, Colors.black],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Waste: ${data['wasteType']} (${data['quantity']} kg)",
                                style: GoogleFonts.raleway(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Date: ${DateFormat('dd MMM yyyy').format(date)}",
                                style: GoogleFonts.raleway(fontSize: 14, color: Colors.white70),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Status: ${data['status'].toString().toUpperCase()}",
                                style: GoogleFonts.raleway(
                                  fontSize: 14,
                                  color: _statusColor(data['status']),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 🚀 Stylish Gradient Dropdown
  Widget _buildAttractiveDropdown() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.deepPurpleAccent, Colors.black87],
          begin: Alignment.topRight,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedStatus,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          dropdownColor: Colors.deepPurple[300],
          style: GoogleFonts.raleway(color: Colors.white, fontSize: 16),
          items: statusOptions.map((status) {
            return DropdownMenuItem(
              value: status,
              child: Text(status, style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
          onChanged: (val) => setState(() => selectedStatus = val!),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'received':
        return Colors.orangeAccent;
      case 'in progress':
        return Colors.blueAccent;
      case 'collected':
        return Colors.green;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }
}
