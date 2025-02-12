import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_bag_popup.dart';
import 'bag_details_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> bags = []; // List to store bag details
  String? userEmail;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _getUserEmail(); // Fetch user email
    _fetchBagsFromFirestore();
  }

  // Fetch user email
  void _getUserEmail() {
    final User? user = FirebaseAuth.instance.currentUser;
    setState(() {
      userEmail = user?.email ?? 'User';
    });
  }

  // Fetch bags
  Future<void> _fetchBagsFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        final snapshot = await FirebaseService.fetchBags(user.email!);
        setState(() {
          bags = snapshot;
        });
      } catch (e) {
        _showSnackBar('Failed to fetch bags: $e');
      }
    }
  }

  Future<void> _addBagToFirestore(String bagName, String ownerName) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        await FirebaseService.addBag(user.email!, bagName, ownerName);
        await _fetchBagsFromFirestore();
        _showSnackBar('Bag added successfully!');
      } catch (e) {
        _showSnackBar('Failed to add bag: $e');
      }
    }
  }

  Future<void> _removeBagFromFirestore(String bagId) async {
    try {
      await FirebaseService.removeBag(bagId);
      await _fetchBagsFromFirestore();
      _showSnackBar('Bag removed successfully!');
    } catch (e) {
      _showSnackBar('Failed to remove bag: $e');
    }
  }

  // Show a snack bar for messages
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC1E4E9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC1E4E9),
        elevation: 0,
        leading: const CircleAvatar(
          backgroundImage: AssetImage('assets/images/schoolbag_logo.png'),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications),
            color: Colors.black,
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _fetchBagsFromFirestore,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, ${userEmail ?? 'Loading...'}',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: bags.isEmpty
                    ? const Center(
                        child: Text(
                          'No bags added yet.',
                          style: TextStyle(fontSize: 18),
                        ),
                      )
                    : ListView.builder(
                        itemCount: bags.length,
                        itemBuilder: (context, index) {
                          final bag = bags[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            color: const Color(0xFFFFF9E6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: ListTile(
                              title: Text('Bag: ${bag['name']}'),
                              subtitle: Text("Owner: ${bag['owner']}"),
                              trailing: const Icon(Icons.delete),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BagDetailsPage(
                                      bagName: bag['name']!,
                                      ownerName: bag['owner']!,
                                      onRemoveBag: () {
                                        Navigator.pop(context);
                                        _removeBagFromFirestore(bag['id']!);
                                      },
                                    ),
                                  ),
                                );
                              },
                              onLongPress: () {
                                _removeBagFromFirestore(bag['id']!);
                              },
                            ),
                          );
                        },
                      ),
              ),
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AddBagPopup(
                        onSave: (bagName, ownerName) {
                          _addBagToFirestore(bagName, ownerName);
                        },
                      );
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFF9E6),
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                ),
                child: const Text(
                  'Add Bag',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Firebase operations
class FirebaseService {
  static Future<List<Map<String, dynamic>>> fetchBags(String userEmail) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('bags')
        .where('userEmail', isEqualTo: userEmail)
        .get();
    return snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        'name': doc['name'],
        'owner': doc['owner'],
      };
    }).toList();
  }

  static Future<void> addBag(
      String userEmail, String bagName, String ownerName) async {
    await FirebaseFirestore.instance.collection('bags').add({
      'name': bagName,
      'owner': ownerName,
      'userEmail': userEmail,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> removeBag(String bagId) async {
    await FirebaseFirestore.instance.collection('bags').doc(bagId).delete();
  }
}
