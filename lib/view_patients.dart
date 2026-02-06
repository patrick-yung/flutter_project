import 'package:flutter/material.dart';
import 'Models/patients_table.dart';
import 'Models/patients.dart';
import 'Models/button.dart';
import 'addpatients.dart';


class Viewpatients extends StatelessWidget {

  final List<Patient> patients = [
    Patient(id: "001", name: "John Doe", age: 30),
    Patient(id: "002", name: "Jane Smith", age: 25),
    Patient(id: "003", name: "Bob Wilson", age: 232),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Patients Management System',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Patients Management System'),
        ),
        body: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Table takes most space
              Expanded(
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: PatientsScreen(patients: patients),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min, 
                  children: [
                    ReusableButton(
                      text: "Filter",
                      onPressed: () {
                        print("Export Data button pressed!");
                      },
                      icon: Icons.download,
                    ),
                    const SizedBox(width: 10), 
                    ReusableButton(
                      text: "Add Patient",
                      onPressed: () {
                        print("Add Patient button pressed!");
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Addpatients()),
                        );
                      },
                      icon: Icons.person_add,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}