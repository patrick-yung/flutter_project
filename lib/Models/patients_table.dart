// lib/Models/patients_table.dart
import 'package:flutter/material.dart';
import 'patients.dart';
import '../Backend/patient_api_service.dart';
import '../patient_detail.dart';

class PatientsScreen extends StatefulWidget {
  final List<Patient> patients;
  final bool showOnlyCritical;

  const PatientsScreen({
    super.key, 
    required this.patients,
    this.showOnlyCritical = false,
  });

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  List<Patient> _patients = [];

  @override
  void initState() {
    super.initState();
    _patients = widget.patients;
  }

  @override
  void didUpdateWidget(PatientsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.patients != widget.patients) {
      setState(() {
        _patients = widget.patients;
      });
    }
  }

  Color _getBackgroundColor(Patient patient) {
    if (patient.critial) {
      return Colors.red.shade50;
    }
    return Colors.transparent;
  }

  Future<void> _deletePatient(String patientId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Patient'),
        content: const Text('Are you sure you want to delete this patient?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await PatientApiService.deletePatient(patientId);
      // Refresh the parent view
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Patient deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate back to refresh the list
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete patient: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_patients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.showOnlyCritical ? Icons.warning_amber : Icons.people_outline,
              size: 64,
              color: widget.showOnlyCritical ? Colors.red.shade300 : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              widget.showOnlyCritical 
                  ? 'No critical patients found' 
                  : 'No patients found',
              style: TextStyle(
                fontSize: 18,
                color: widget.showOnlyCritical ? Colors.red.shade700 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.showOnlyCritical
                  ? 'All patients are stable'
                  : 'Add a patient to get started',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _patients.length,
      itemBuilder: (context, index) {
        final patient = _patients[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: _getBackgroundColor(patient),
            border: patient.critial 
                ? Border.all(color: Colors.red.shade200, width: 1) 
                : null,
          ),
          child: Card(
            margin: EdgeInsets.zero,
            elevation: patient.critial ? 2 : 1,
            color: Colors.transparent,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: patient.critial 
                    ? Colors.red.shade100 
                    : Colors.blue.shade100,
                child: Text(
                  patient.name.isNotEmpty ? patient.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: patient.critial ? Colors.red.shade800 : Colors.blue.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      patient.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: patient.critial ? Colors.red.shade900 : null,
                      ),
                    ),
                  ),
                  if (patient.critial)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: const Text(
                        'CRITICAL',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Age: ${patient.age} | Dept: ${patient.department}',
                    style: TextStyle(
                      color: patient.critial ? Colors.red.shade800 : null,
                    ),
                  ),
                  if (patient.tests.isNotEmpty)
                    Text(
                      'Tests: ${patient.tests.length}',
                      style: TextStyle(
                        color: patient.critial ? Colors.red.shade700 : Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              trailing: IconButton(
                icon: Icon(
                  Icons.delete,
                  color: patient.critial ? Colors.red : Colors.grey.shade600,
                ),
                onPressed: () => _deletePatient(patient.id),
              ),
              onTap: () {
                // Navigate to PatientDetails screen instead of showing bottom sheet
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PatientDetails(patient: patient),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}