import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EnquiryScreen extends StatefulWidget {
  const EnquiryScreen({super.key});

  @override
  State<EnquiryScreen> createState() => _EnquiryScreenState();
}

class _EnquiryScreenState extends State<EnquiryScreen> {
  final _formKey = GlobalKey<FormState>();
  String name = '', email = '', phone = '', message = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enquiry', style: GoogleFonts.raleway(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text('How can we help you?', style: GoogleFonts.raleway(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField('Full Name', (val) => name = val!),
                  _buildTextField('Email', (val) => email = val!, keyboardType: TextInputType.emailAddress),
                  _buildTextField('Phone', (val) => phone = val!, keyboardType: TextInputType.phone),
                  _buildTextField('Your Message', (val) => message = val!, maxLines: 4),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        // TODO: Handle Enquiry submission logic (Firebase / email)
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enquiry Submitted')));
                      }
                    },
                    child: Text('Submit', style: GoogleFonts.raleway(fontSize: 16,color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, Function(String?) onSaved, {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        keyboardType: keyboardType,
        maxLines: maxLines,
        onSaved: onSaved,
        validator: (value) => value == null || value.isEmpty ? 'Please enter $hint' : null,
        style: GoogleFonts.raleway(),
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
        ),
      ),
    );
  }
}
