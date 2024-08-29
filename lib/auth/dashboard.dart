import 'package:coalapp/auth/controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';

class EmployeeDashboard extends StatelessWidget {
  final AuthController authController = Get.find();

  // Add state management for focused and selected day
  final Rx<DateTime> _focusedDay = DateTime.now().obs;
  final Rx<DateTime?> _selectedDay = DateTime.now().obs;

  // Initialize the dashboard and fetch shifts
  EmployeeDashboard() {
    authController.fetchNext10DaysShifts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Employee Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => authController.logout(),
          ),
        ],
      ),
      body: Obx(() {
        final user = authController.userModel.value;
        final selectedShifts = authController.selectedShifts;

        return Column(
          children: [
            // Display the user's name
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Welcome, ${user.email}!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10), // Add some spacing

                  // Display the employee ID if available
                  if (user.employeeID.isNotEmpty)
                    Text(
                      'Your Employee ID: ${user.employeeID}',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                ],
              ),
            ),

            // Calendar to select dates
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay.value,
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (day) {
                // Highlight the selected date
                return isSameDay(_selectedDay.value, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                _selectedDay.value = selectedDay;
                _focusedDay.value = focusedDay;

                // Fetch shifts for the selected date
                authController.filterShiftsByDate(selectedDay);
              },
              onPageChanged: (focusedDay) {
                _focusedDay.value =
                    focusedDay; // Update the focused day when the calendar page changes
              },
            ),

            // Display the selected shifts
            Expanded(
              child: selectedShifts.isEmpty
                  ? Center(
                      child: Text('No shifts available for the selected date.'))
                  : ListView.builder(
                      itemCount: selectedShifts.length,
                      itemBuilder: (context, index) {
                        final shift = selectedShifts[index];
                        return ListTile(
                          leading: Icon(Icons.event),
                          title: Text(
                              'Date: ${shift['date'].toDate().toLocal().toString().split(' ')[0]}'),
                          subtitle:
                              Text('Shift Details: ${shift['shiftDetails']}'),
                        );
                      },
                    ),
            ),
          ],
        );
      }),
    );
  }
}

class HeadDashboard extends StatelessWidget {
  final AuthController authController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Head Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => authController.logout(),
          ),
        ],
      ),
      body: Center(child: Text('Welcome, Head!')),
    );
  }
}

class SupervisorDashboard extends StatelessWidget {
  final AuthController authController = Get.find();
  final TextEditingController empIdController =
      TextEditingController(); // Controller for employee ID input

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Supervisor Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => authController.logout(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Input field to search shifts by employee ID
            TextField(
              controller: empIdController,
              decoration: InputDecoration(
                labelText: 'Enter Employee ID',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    // Fetch shifts by employee ID when search is pressed
                    authController
                        .fetchShiftsByEmployeeID(empIdController.text);
                  },
                ),
              ),
            ),
            SizedBox(height: 20), // Add spacing

            // Display the fetched shifts or show an option to add a shift
            Expanded(
              child: Obx(() {
                final shifts = authController.selectedShifts;
                return shifts.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('No shifts found for the entered Employee ID.'),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              // Show the shift adding form
                              showAddShiftDialog(context, empIdController.text);
                            },
                            child: Text('Add Shift'),
                          ),
                        ],
                      )
                    : ListView.builder(
                        itemCount: shifts.length,
                        itemBuilder: (context, index) {
                          final shift = shifts[index];
                          return ListTile(
                            leading: Icon(Icons.event),
                            title: Text(
                                'Date: ${shift['date'].toDate().toLocal().toString().split(' ')[0]}'),
                            subtitle:
                                Text('Shift Details: ${shift['shiftDetails']}'),
                            trailing: IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                // Implement edit functionality if needed
                                // For example, navigate to a shift editing screen
                              },
                            ),
                          );
                        },
                      );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // Method to show the Add Shift dialog
  void showAddShiftDialog(BuildContext context, String employeeID) {
    final TextEditingController dateController = TextEditingController();
    final TextEditingController detailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Shift'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dateController,
                decoration: InputDecoration(
                  labelText: 'Date (YYYY-MM-DD)',
                ),
              ),
              TextField(
                controller: detailsController,
                decoration: InputDecoration(
                  labelText: 'Shift Details',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Add the new shift to Firestore
                authController.addShift(
                    employeeID, dateController.text, detailsController.text);
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Add Shift'),
            ),
          ],
        );
      },
    );
  }
}
