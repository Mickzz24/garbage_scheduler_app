import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class RewardScreen extends StatefulWidget {
  const RewardScreen({Key? key}) : super(key: key);

  @override
  _RewardScreenState createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen> {
  int totalPoints = 0;
  int level = 1;
  double progress = 0.0;

  final Map<String, int> wasteRewards = {
    'Metal': 15,
    'Electronics': 13,
    'Plastic': 10,
    'Glass': 8,
    'Organic': 5,
    'Others': 5,
  };

  @override
  void initState() {
    super.initState();
    _calculateRewards();
  }

  Future<void> _calculateRewards() async {
    User? user = FirebaseAuth.instance.currentUser;
    int points = 0;

    if (user != null) {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('pickups')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'collected') // Only collected pickups
          .get();

      for (var doc in snapshot.docs) {
        String wasteType = doc['wasteType'] ?? 'Others';
        points += wasteRewards[wasteType] ?? 5;
      }

      // Optional: Update total points back to user profile (for tracking)
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'rewardPoints': points,
      });

      setState(() {
        totalPoints = points;
        level = (totalPoints ~/ 100) + 1;
        progress = (totalPoints % 100) / 100;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLevelCard(),
              const SizedBox(height: 20),
              Text("Your Progress", style: GoogleFonts.raleway(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildProgressBar(),
              const SizedBox(height: 20),
              _buildPointsSummary(),
              const SizedBox(height: 30),
              _buildLevelUpInfo(),
              const SizedBox(height: 20),
              _refreshButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.deepPurple, Colors.blueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Level $level",
              style: GoogleFonts.raleway(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              "$totalPoints Points",
              style: GoogleFonts.raleway(fontSize: 20, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: progress),
          duration: const Duration(seconds: 1),
          builder: (context, value, _) => LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.grey[300],
            color: Colors.deepPurple,
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 5),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            "${(progress * 100).toInt()}% to next level",
            style: GoogleFonts.raleway(fontSize: 14, color: Colors.black54),
          ),
        ),
      ],
    );
  }

  Widget _buildPointsSummary() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total Points", style: GoogleFonts.raleway(fontWeight: FontWeight.bold)),
                Text("$totalPoints", style: GoogleFonts.raleway()),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Points to Next Level", style: GoogleFonts.raleway(fontWeight: FontWeight.bold)),
                Text("${100 - (totalPoints % 100)}", style: GoogleFonts.raleway()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelUpInfo() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.stars, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(
                  "Level Up Info",
                  style: GoogleFonts.raleway(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "Earn 100 points to level up!\nKeep scheduling pickups to earn more.",
              style: GoogleFonts.raleway(fontSize: 16, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _refreshButton() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: _calculateRewards,
        icon: const Icon(Icons.refresh),
        label: Text('Refresh Rewards', style: GoogleFonts.raleway(fontSize: 18,color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        ),
      ),
    );
  }
}
