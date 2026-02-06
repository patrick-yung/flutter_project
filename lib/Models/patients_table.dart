import 'package:flutter/material.dart';
import 'patients.dart';

class PatientsScreen extends StatelessWidget {

  const PatientsScreen({super.key, required this.patients});
  
  final List<Patient> patients;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patients'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Table(
            border: TableBorder.all(),
            children: [
            
              // Data rows
              for (var patient in patients)
                TableRow(
                  children: [
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(patient.id),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(patient.name),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(patient.age.toString()),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}