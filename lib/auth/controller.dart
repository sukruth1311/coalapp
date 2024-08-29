import 'dart:math';
import 'package:coalapp/models/model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User model observable
  var userModel = UserModel(
    uid: '',
    email: '',
    role: '',
    employeeID: '',
  ).obs;

  // Observable list to store shifts
  var shifts = <Map<String, dynamic>>[].obs;
  var selectedShifts = <Map<String, dynamic>>[].obs;

  // Generate unique employee ID
  Future<String> generateUniqueEmployeeID() async {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const numbers = '0123456789';
    final random = Random();

    String generateID() {
      String randomLetters =
          List.generate(4, (index) => letters[random.nextInt(letters.length)])
              .join('');
      String randomNumbers =
          List.generate(4, (index) => numbers[random.nextInt(numbers.length)])
              .join('');
      return randomLetters + randomNumbers;
    }

    String employeeID = generateID();
    bool exists = await checkIfEmployeeIDExists(employeeID);

    // Regenerate ID until a unique one is found
    while (exists) {
      employeeID = generateID();
      exists = await checkIfEmployeeIDExists(employeeID);
    }

    return employeeID;
  }

  // Check if employee ID already exists in Firestore
  Future<bool> checkIfEmployeeIDExists(String employeeID) async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('employeeID', isEqualTo: employeeID)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  // Register a new user
  Future<void> register(String email, String password, String role) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Ensure user is not null
      final user = userCredential.user;
      if (user != null) {
        String employeeID = '';
        if (role == 'Employee') {
          employeeID =
              await generateUniqueEmployeeID(); // Ensure unique ID for employees
        }

        userModel.value = UserModel(
          uid: user.uid,
          email: email,
          role: role,
          employeeID: employeeID,
        );

        // Save user role and employee ID in Firestore
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.value.toFirestore());

        Get.snackbar(
            'Success', 'User registered successfully with ID: $employeeID');
        Get.offAllNamed('/login'); // Redirect to login after registration
      } else {
        Get.snackbar('Error', 'User registration failed, user is null.');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }

  // Login user
  Future<void> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Ensure user is not null
      final user = userCredential.user;
      if (user != null) {
        // Fetch user data from Firestore
        DocumentSnapshot doc =
            await _firestore.collection('users').doc(user.uid).get();

        if (doc.exists) {
          userModel.value =
              UserModel.fromFirestore(doc.data() as Map<String, dynamic>);
          navigateBasedOnRole(); // Navigate to respective dashboard
        } else {
          Get.snackbar('Error', 'User data not found in database.');
        }
      } else {
        Get.snackbar('Error', 'User login failed, user is null.');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }

  // Fetch the next 10 days of shifts
  Future<void> fetchNext10DaysShifts() async {
    try {
      if (userModel.value.employeeID.isNotEmpty) {
        DateTime now = DateTime.now();
        DateTime tenDaysLater = now.add(Duration(days: 10));

        QuerySnapshot snapshot = await _firestore
            .collection('shifts')
            .where('employeeID', isEqualTo: userModel.value.employeeID)
            .where('date', isGreaterThanOrEqualTo: now)
            .where('date', isLessThanOrEqualTo: tenDaysLater)
            .orderBy('date')
            .get();

        shifts.value = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch shifts: $e');
    }
  }

  // Filter shifts based on the selected date
  void filterShiftsByDate(DateTime date) {
    selectedShifts.value = shifts.where((shift) {
      DateTime shiftDate = (shift['date'] as Timestamp).toDate();
      return shiftDate.year == date.year &&
          shiftDate.month == date.month &&
          shiftDate.day == date.day;
    }).toList();
  }

  // Fetch shifts for a specific employee ID
  Future<void> fetchShiftsByEmployeeID(String employeeID) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('shifts')
          .where('employeeID', isEqualTo: employeeID)
          .orderBy('date')
          .get();

      selectedShifts.value = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      if (selectedShifts.isEmpty) {
        Get.snackbar('Notice', 'No shifts found for this employee ID.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch shifts: $e');
    }
  }

// Method to add a shift for an employee
  Future<void> addShift(
      String employeeID, String date, String shiftDetails) async {
    try {
      DateTime shiftDate = DateTime.parse(date);
      await _firestore.collection('shifts').add({
        'employeeID': employeeID,
        'date': Timestamp.fromDate(shiftDate),
        'shiftDetails': shiftDetails,
      });
      Get.snackbar('Success', 'Shift added successfully.');

      // Optionally, fetch the shifts again to update the UI
      fetchShiftsByEmployeeID(employeeID);
    } catch (e) {
      Get.snackbar('Error', 'Failed to add shift: $e');
    }
  }

  // Check role and navigate accordingly
  void navigateBasedOnRole() {
    switch (userModel.value.role) {
      case 'Employee':
        Get.offAllNamed('/employee');
        break;
      case 'Head':
        Get.offAllNamed('/head');
        break;
      case 'Supervisor':
        Get.offAllNamed('/supervisor');
        break;
      default:
        Get.snackbar('Error', 'Invalid role');
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
    userModel.value = UserModel(
      uid: '',
      email: '',
      role: '',
      employeeID: '',
    );
    Get.offAllNamed('/login');
    Future<void> fetchShiftsByEmployeeIDAndDate(
        String employeeID, DateTime date) async {
      try {
        DateTime startOfDay = DateTime(date.year, date.month, date.day);
        DateTime endOfDay =
            DateTime(date.year, date.month, date.day, 23, 59, 59);

        QuerySnapshot snapshot = await _firestore
            .collection('shifts')
            .where('employeeID', isEqualTo: employeeID)
            .where('date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
            .orderBy('date')
            .get();

        selectedShifts.value = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();

        if (selectedShifts.isEmpty) {
          Get.snackbar('Notice', 'No shifts found for this date.');
        }
      } catch (e) {
        Get.snackbar('Error', 'Failed to fetch shifts: $e');
      }
    }
  }
}
