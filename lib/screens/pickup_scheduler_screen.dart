import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class PickupSchedulerScreen extends StatefulWidget {
  const PickupSchedulerScreen({Key? key}) : super(key: key);

  @override
  State<PickupSchedulerScreen> createState() => _PickupSchedulerScreenState();
}

class _PickupSchedulerScreenState extends State<PickupSchedulerScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<String> wasteTypes = ['Plastic', 'Metal', 'Organic', 'Electronic', 'Glass', 'Paper'];
  String selectedWasteType = 'Plastic';
  double quantity = 0;
  String location = '';
  DateTime? selectedDate;
  String selectedTime = '';

  Future<void> _schedulePickup() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('pickups').add({
      'userId': user.uid,
      'wasteType': selectedWasteType,
      'quantity': quantity,
      'location': location,
      'date': Timestamp.fromDate(selectedDate!),
      'time': selectedTime,
      'status': 'received',
      'createdAt': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Pickup scheduled successfully!")),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Schedule Pickup"),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 8,
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
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildWasteDropdown(),
                  const SizedBox(height: 15),
                  _buildNumberField('Quantity (kg)', (val) => quantity = double.parse(val!)),
                  const SizedBox(height: 15),
                  _buildTextField('Location', (val) => location = val!),
                  const SizedBox(height: 20),
                  _buildDatePicker(),
                  const SizedBox(height: 20),
                  _buildTimePicker(),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _schedulePickup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: Text(
                      "Schedule Pickup",
                      style: GoogleFonts.raleway(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWasteDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedWasteType,
      dropdownColor: Colors.black87,
      decoration: InputDecoration(
        labelText: 'Waste Type',
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
      style: const TextStyle(color: Colors.white, fontSize: 16),
      items: wasteTypes.map((type) {
        return DropdownMenuItem(value: type, child: Text(type, style: const TextStyle(color: Colors.white)));
      }).toList(),
      onChanged: (val) {
        setState(() {
          selectedWasteType = val!;
        });
      },
    );
  }

  Widget _buildTextField(String label, Function(String?) onSaved) {
    return TextFormField(
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
      validator: (val) => val!.isEmpty ? 'Enter $label' : null,
      onSaved: onSaved,
    );
  }

  Widget _buildNumberField(String label, Function(String?) onSaved) {
    return TextFormField(
      style: const TextStyle(color: Colors.white),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
      validator: (val) => val!.isEmpty ? 'Enter $label' : null,
      onSaved: onSaved,
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Select Date", style: TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            DateTime? date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime(2100),
            );
            if (date != null) {
              setState(() {
                selectedDate = date;
              });
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.orangeAccent,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                selectedDate == null ? "Choose Date" : DateFormat('dd MMM yyyy').format(selectedDate!),
                style: GoogleFonts.raleway(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Select Time", style: TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            TimeOfDay? time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
            if (time != null) {
              setState(() {
                selectedTime = time.format(context);
              });
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.orangeAccent,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                selectedTime.isEmpty ? "Choose Time" : selectedTime,
                style: GoogleFonts.raleway(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
