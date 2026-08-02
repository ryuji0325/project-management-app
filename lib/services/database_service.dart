import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // Dapatkan User ID semasa
  String? get currentUid => FirebaseAuth.instance.currentUser?.uid;

  // --- PROJECT METHODS ---

  // UBAH SINI: Dari 'getMyProjects' ke 'getAllProjects'
  // Kita buang filter .where('createdBy') supaya semua staff nampak semua projek.
  Stream<QuerySnapshot> getAllProjects() {
    return _db.collection('projects')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Future: Update Vendor Projek
  Future<void> updateProjectVendors(String projectId, List<Map<String, dynamic>> vendors) async {
    await _db.collection('projects').doc(projectId).update({
      'vendors': vendors,
    });
  }

  // Future: Update Org Chart
  Future<void> updateOrgChart(String projectId, Map<String, dynamic> orgChart) async {
    await _db.collection('projects').doc(projectId).update({
      'orgChart': orgChart,
    });
  }

  // --- USER METHODS ---
  
  // Future: Dapatkan data user untuk dropdown
  Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    try {
      final snapshot = await _db.collection('users').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          "uid": doc.id,
          "username": data['username'] ?? '',
          "displayName": data['displayName'] ?? data['email'] ?? doc.id,
          "email": data['email'] ?? '',
        };
      }).toList();
    } catch (e) {
      print("Error fetching users: $e");
      return [];
    }
  }

  // Future: Update Profile Picture URL
  Future<void> updateUserPhoto(String url) async {
    if (currentUid == null) return;
    await _db.collection('users').doc(currentUid).update({
      'photoUrl': url,
    });
    // Update juga dalam Auth cache
    await FirebaseAuth.instance.currentUser?.updatePhotoURL(url);
  }
}