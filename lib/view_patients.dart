// lib/view_patients.dart
import 'package:flutter/material.dart';
import 'Models/patients_table.dart';
import 'Models/patients.dart';
import 'Models/button.dart';
import 'addpatients.dart';
import 'Backend/patient_api_service.dart';

class ViewPatients extends StatefulWidget {
  const ViewPatients({super.key});

  @override
  State<ViewPatients> createState() => _ViewPatientsState();
}

class _ViewPatientsState extends State<ViewPatients> {
  List<Patient> allPatients = []; // Store all patients
  List<Patient> displayedPatients = []; // Store filtered patients
  bool _isLoading = true;
  String? _errorMessage;
  bool _showOnlyCritical = false; // Filter state

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fetchedPatients = await PatientApiService.getPatients();
      setState(() {
        allPatients = fetchedPatients;
        _applyFilter(); // Apply filter after fetching
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load patients: $e';
        _isLoading = false;
      });
    }
  }

  // Toggle filter and update displayed patients
  void _toggleFilter() {
    setState(() {
      _showOnlyCritical = !_showOnlyCritical;
      _applyFilter();
    });
  }

  // Apply the current filter to the patient list
  void _applyFilter() {
    if (_showOnlyCritical) {
      displayedPatients = allPatients.where((patient) => patient.critial).toList();
    } else {
      displayedPatients = List.from(allPatients); // Show all patients
    }
  }

  // Get the count text based on filter
  String _getPatientCountText() {
    if (_showOnlyCritical) {
      return '${displayedPatients.length} Critical Patients';
    } else {
      return '${allPatients.length} Total Patients';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Patients Management System',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue.shade800,
        // Removed the filter button from AppBar
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey.shade50,
              Colors.grey.shade100,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with refresh button
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Patient Records',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.blue.shade900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (_showOnlyCritical)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: const Text(
                              'FILTER: CRITICAL ONLY',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _fetchPatients,
                    color: Colors.blue.shade800,
                  ),
                ],
              ),
            ),

            // Patient count badge with filter button RIGHT NEXT TO IT
            Row(
              children: [
                // Patient count badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _showOnlyCritical ? Colors.red.shade50 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _showOnlyCritical ? Colors.red.shade100 : Colors.blue.shade100,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showOnlyCritical ? Icons.warning : Icons.people,
                        size: 16,
                        color: _showOnlyCritical ? Colors.red.shade700 : Colors.blue.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getPatientCountText(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _showOnlyCritical ? Colors.red.shade800 : Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 12), // Space between badge and filter button
                
                // Filter button right next to patient count
                Container(
                  decoration: BoxDecoration(
                    color: _showOnlyCritical ? Colors.red.shade50 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _showOnlyCritical ? Colors.red.shade200 : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _toggleFilter,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _showOnlyCritical ? Icons.filter_list_off : Icons.filter_list,
                              size: 16,
                              color: _showOnlyCritical ? Colors.red.shade700 : Colors.grey.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _showOnlyCritical ? 'Show All' : 'Critical Only',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _showOnlyCritical ? Colors.red.shade800 : Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                const Spacer(), // Push everything to the left
              ],
            ),

            const SizedBox(height: 20), // Space after filter row

            // Table Card
            Expanded(
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _errorMessage != null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 48,
                                      color: Colors.red.shade300,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _errorMessage!,
                                      style: TextStyle(color: Colors.red.shade700),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _fetchPatients,
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              )
                            : PatientsScreen(
                                patients: displayedPatients,
                                showOnlyCritical: _showOnlyCritical,
                              ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}