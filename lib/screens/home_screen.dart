import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:garbage_scheduler_app/screens/rewards_screen.dart';
import 'package:garbage_scheduler_app/screens/profile_screen.dart';
import 'package:garbage_scheduler_app/screens/pickup_scheduler_screen.dart';
import 'package:garbage_scheduler_app/screens/feedback_screen.dart';
import 'package:garbage_scheduler_app/screens/login_screen.dart';
import 'package:garbage_scheduler_app/screens/Pickup_Status_Detail_Screen.dart';
import 'package:garbage_scheduler_app/screens/history_screen.dart';
import 'package:garbage_scheduler_app/screens/game_screen.dart';
import 'package:garbage_scheduler_app/screens/enquiry_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String username = 'User';
  String userEmail = '';
  String profilePic = 'assets/profile.png';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userData =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        username = userData['name']?.toString() ?? 'User';
        userEmail = user.email?.toString() ?? 'user@example.com';
        profilePic = userData['profilePic']?.toString() ?? 'assets/profile.png';
      });
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _screens = [
    const HomeScreenContent(),
    const GameScreen(),
    const RewardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'TrackWise',
          style: GoogleFonts.raleway(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 0,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.deepPurpleAccent),
              accountName: Text(username, style: GoogleFonts.raleway(color: Colors.white)),
              accountEmail: Text(userEmail, style: GoogleFonts.raleway(color: Colors.white)),
              currentAccountPicture: CircleAvatar(
                backgroundImage: NetworkImage(profilePic),
              ),
            ),
            _buildDrawerItem(FeatherIcons.user, 'Profile', const ProfileScreen()),
            _buildDrawerItem(FeatherIcons.clock, 'History', const HistoryScreen()),
            _buildDrawerItem(FeatherIcons.messageCircle, 'Feedback', const FeedbackScreen()),
            _buildDrawerItem(Icons.help_outline, 'Enquiry', const EnquiryScreen()),
            ListTile(
              leading: const Icon(FeatherIcons.logOut, color: Colors.red),
              title: const Text('Log Out', style: TextStyle(color: Colors.red)),
              onTap: _signOut,
            ),
          ],
        ),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.deepPurpleAccent,
        unselectedItemColor: Colors.white70,
        backgroundColor: Colors.black,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(FeatherIcons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(FeatherIcons.play),
            label: 'Game',
          ),
          BottomNavigationBarItem(
            icon: Icon(FeatherIcons.award),
            label: 'Rewards',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, Widget screen) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurpleAccent),
      title: Text(title, style: GoogleFonts.raleway()),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
      },
    );
  }
}

class HomeScreenContent extends StatelessWidget {
  const HomeScreenContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Container(
      color: Colors.grey[100],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 20),
            _buildCard(
              context,
              'Schedule Pickup',
              'assets/lottie/schedule.json',
              const PickupSchedulerScreen(),
            ),
            const SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('pickups')
                  .where('userId', isEqualTo: user?.uid)
                  .orderBy('createdAt', descending: true)
                  .limit(1)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return _buildCard(
                    context,
                    'No Scheduled Pickup',
                    'assets/lottie/status.json',
                    const PickupSchedulerScreen(),
                  );
                }

                var pickup = snapshot.data!.docs.first;
                String pickupId = pickup.id;

                return _buildCard(
                  context,
                  'View Pickup Status',
                  'assets/lottie/status.json',
                  PickupStatusDetailScreen(pickupId: pickupId),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(30),
      ),
      child: const TextField(
        decoration: InputDecoration(
          prefixIcon: Icon(FeatherIcons.search, color: Colors.deepPurpleAccent),
          hintText: 'Search...',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, String assetPath, Widget screen) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 5,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Colors.deepPurpleAccent, Colors.black],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Lottie.asset(assetPath, width: 300, height: 150),
              const SizedBox(height: 10),
              Text(
                title,
                style: GoogleFonts.raleway(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
