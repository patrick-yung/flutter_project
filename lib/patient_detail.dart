// lib/patient_details.dart
import 'package:flutter/material.dart';
import 'Models/patients.dart';
import 'Models/patients_test.dart';
import 'Backend/patient_api_service.dart';

class PatientDetails extends StatefulWidget {
  final Patient patient;

  const PatientDetails({super.key, required this.patient});

  @override
  State<PatientDetails> createState() => _PatientDetailsState();
}

class _PatientDetailsState extends State<PatientDetails> {
  late Patient _patient;
  bool _isLoading = true; // Start with loading true
  String? _errorMessage;

  // Test types
  final List<String> _testTypes = [
    'Blood Type',
    'Blood Pressure',
    'Blood Sugar',
    'Blood Count',
  ];

  // Blood type options
  final List<String> _bloodTypes = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  // Selected values
  String? _selectedTestType;
  String? _selectedBloodType;
  final TextEditingController _bloodPressureController = TextEditingController();
  final TextEditingController _bloodSugarController = TextEditingController();
  final TextEditingController _bloodCountController = TextEditingController();
  
  // Critical checkbox state
  bool _isCriticalChecked = false;

  // Blood pressure thresholds
  static const int SYSTOLIC_HIGH_THRESHOLD = 180;
  static const int SYSTOLIC_LOW_THRESHOLD = 90;
  static const int DIASTOLIC_HIGH_THRESHOLD = 120;
  static const int DIASTOLIC_LOW_THRESHOLD = 60;

  @override
  void initState() {
    super.initState();
    _fetchPatientData(); // Fetch fresh data when screen opens
    // Add listener to blood pressure controller
    _bloodPressureController.addListener(_checkBloodPressureForCritical);
  }

  @override
  void dispose() {
    _bloodPressureController.removeListener(_checkBloodPressureForCritical);
    _bloodPressureController.dispose();
    _bloodSugarController.dispose();
    _bloodCountController.dispose();
    super.dispose();
  }

  // Check if blood pressure value is critical
  bool _isBloodPressureCritical(String bpValue) {
    // Parse blood pressure value (expected format: "systolic/diastolic")
    final parts = bpValue.split('/');
    if (parts.length != 2) return false;
    
    try {
      final systolic = int.tryParse(parts[0].trim());
      final diastolic = int.tryParse(parts[1].trim().split(' ')[0]); // Remove unit if present
      
      if (systolic == null || diastolic == null) return false;
      
      // Check if blood pressure is dangerously high or low
      return (systolic >= SYSTOLIC_HIGH_THRESHOLD || 
              systolic <= SYSTOLIC_LOW_THRESHOLD ||
              diastolic >= DIASTOLIC_HIGH_THRESHOLD || 
              diastolic <= DIASTOLIC_LOW_THRESHOLD);
    } catch (e) {
      return false;
    }
  }

  // Listener for blood pressure controller
  void _checkBloodPressureForCritical() {
    if (_selectedTestType == 'Blood Pressure') {
      final bpValue = _bloodPressureController.text.trim();
      setState(() {
        _isCriticalChecked = _isBloodPressureCritical(bpValue);
      });
    }
  }

  Future<void> _fetchPatientData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final updatedPatient = await PatientApiService.getPatient(widget.patient.id);
      if (mounted) {
        setState(() {
          _patient = updatedPatient;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load patient data: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshPatient() async {
    await _fetchPatientData();
  }

  void _resetForm() {
    setState(() {
      _selectedTestType = null;
      _selectedBloodType = null;
      _bloodPressureController.clear();
      _bloodSugarController.clear();
      _bloodCountController.clear();
      _isCriticalChecked = false;
    });
  }

  Future<void> _addTest() async {
    if (_selectedTestType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a test type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate based on test type
    String testResult = '';
    bool shouldUpdateCritical = false;
    
    switch (_selectedTestType) {
      case 'Blood Type':
        if (_selectedBloodType == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a blood type'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        testResult = _selectedBloodType!;
        break;
      
      case 'Blood Pressure':
        if (_bloodPressureController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter blood pressure'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        testResult = _bloodPressureController.text.trim();
        
        // Check if we should update critical status based on blood pressure
        if (_isBloodPressureCritical(testResult)) {
          shouldUpdateCritical = true;
        }
        break;
      
      case 'Blood Sugar':
        if (_bloodSugarController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter blood sugar level'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        testResult = _bloodSugarController.text.trim();
        break;
      
      case 'Blood Count':
        if (_bloodCountController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter blood count'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        testResult = _bloodCountController.text.trim();
        break;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create test object
      final newTest = PatientsTest(
        id: '', // Will be assigned by backend
        testType: _selectedTestType!,
        testResult: testResult,
        testDate: DateTime.now(),
      );

      // Determine final critical status
      // If user manually checked the box or blood pressure indicates critical, set to true
      final bool finalCriticalStatus = _patient.critial || _isCriticalChecked || shouldUpdateCritical;

      // Call API to add test
      await PatientApiService.addPatientTests(
        patientId: _patient.id,
        tests: [newTest],
        critial: finalCriticalStatus,
      );

      // Refresh patient data to show the new test
      await _fetchPatientData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              finalCriticalStatus && !_patient.critial 
                  ? 'Test added successfully. Patient marked as CRITICAL!' 
                  : 'Test added successfully'
            ),
            backgroundColor: finalCriticalStatus ? Colors.orange : Colors.green,
          ),
        );
      }

      // Reset form
      _resetForm();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add test: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteTest(String testId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Test'),
        content: const Text('Are you sure you want to delete this test?'),
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

    setState(() {
      _isLoading = true;
    });

    try {
      await PatientApiService.deletePatientTest(_patient.id, testId);
      await _fetchPatientData(); // Refresh after delete

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete test: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Get icon for test type
  IconData _getTestIcon(String testType) {
    switch (testType) {
      case 'Blood Type':
        return Icons.bloodtype;
      case 'Blood Pressure':
        return Icons.monitor_heart;
      case 'Blood Sugar':
        return Icons.water_drop;
      case 'Blood Count':
        return Icons.science;
      default:
        return Icons.medical_services;
    }
  }

  // Get color for test type
  Color _getTestColor(String testType) {
    switch (testType) {
      case 'Blood Type':
        return Colors.red;
      case 'Blood Pressure':
        return Colors.blue;
      case 'Blood Sugar':
        return Colors.green;
      case 'Blood Count':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loading...'),
          backgroundColor: widget.patient.critial ? Colors.red : Colors.blue,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: Colors.red,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchPatientData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _patient.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _patient.critial ? Colors.red : Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshPatient,
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _patient.critial ? Colors.red.shade50 : Colors.blue.shade50,
                  Colors.white,
                ],
              ),
            ),
            child: Column(
              children: [
                // Patient Info Card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: Border.all(
                      color: _patient.critial ? Colors.red.shade200 : Colors.blue.shade200,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Patient Avatar
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: _patient.critial ? Colors.red.shade100 : Colors.blue.shade100,
                        child: Text(
                          _patient.name.isNotEmpty ? _patient.name[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: _patient.critial ? Colors.red.shade800 : Colors.blue.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Patient Details
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Age: ${_patient.age}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Icon(
                            Icons.business,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Dept: ${_patient.department}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Critical Status
                      if (_patient.critial)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning, color: Colors.red, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'CRITICAL CONDITION',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Add Test Section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add New Test',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Test Type Dropdown
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedTestType,
                          hint: const Text('Select Test Type'),
                          isExpanded: true,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          items: _testTypes.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Row(
                                children: [
                                  Icon(
                                    _getTestIcon(type),
                                    size: 20,
                                    color: _getTestColor(type),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(type),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedTestType = value;
                              // Clear previous selections
                              _selectedBloodType = null;
                              _bloodPressureController.clear();
                              _bloodSugarController.clear();
                              _bloodCountController.clear();
                              _isCriticalChecked = false;
                            });
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Dynamic Input based on test type
                      if (_selectedTestType != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getTestColor(_selectedTestType!).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getTestColor(_selectedTestType!).withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _getTestIcon(_selectedTestType!),
                                    color: _getTestColor(_selectedTestType!),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _selectedTestType!,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _getTestColor(_selectedTestType!),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // Blood Type Selection
                              if (_selectedTestType == 'Blood Type')
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _bloodTypes.map((type) {
                                    final isSelected = _selectedBloodType == type;
                                    return FilterChip(
                                      label: Text(type),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        setState(() {
                                          _selectedBloodType = selected ? type : null;
                                        });
                                      },
                                      selectedColor: Colors.red.shade100,
                                      checkmarkColor: Colors.red,
                                      labelStyle: TextStyle(
                                        color: isSelected ? Colors.red : null,
                                        fontWeight: isSelected ? FontWeight.bold : null,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              
                              // Blood Pressure Input
                              if (_selectedTestType == 'Blood Pressure')
                                Column(
                                  children: [
                                    TextField(
                                      controller: _bloodPressureController,
                                      keyboardType: TextInputType.text,
                                      decoration: InputDecoration(
                                        hintText: 'e.g., 120/80 mmHg',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        prefixIcon: const Icon(Icons.monitor_heart),
                                      ),
                                    ),
                                    
                                    // Critical Checkbox (only shown for blood pressure)
                                    if (_bloodPressureController.text.trim().isNotEmpty)
                                      Container(
                                        margin: const EdgeInsets.only(top: 12),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _isCriticalChecked 
                                              ? Colors.red.shade50 
                                              : Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: _isCriticalChecked 
                                                ? Colors.red.shade200 
                                                : Colors.grey.shade300,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Checkbox(
                                              value: _isCriticalChecked,
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  _isCriticalChecked = value ?? false;
                                                });
                                              },
                                              activeColor: Colors.red,
                                              checkColor: Colors.white,
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Critical Condition',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: _isCriticalChecked 
                                                          ? Colors.red 
                                                          : Colors.grey.shade700,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Blood pressure above $SYSTOLIC_HIGH_THRESHOLD/$DIASTOLIC_HIGH_THRESHOLD '
                                                    'or below $SYSTOLIC_LOW_THRESHOLD/$DIASTOLIC_LOW_THRESHOLD '
                                                    'will auto-check this box',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              
                              // Blood Sugar Input
                              if (_selectedTestType == 'Blood Sugar')
                                TextField(
                                  controller: _bloodSugarController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: 'e.g., 95 mg/dL',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    prefixIcon: const Icon(Icons.water_drop),
                                  ),
                                ),
                              
                              // Blood Count Input
                              if (_selectedTestType == 'Blood Count')
                                TextField(
                                  controller: _bloodCountController,
                                  keyboardType: TextInputType.text,
                                  decoration: InputDecoration(
                                    hintText: 'e.g., 5.2 million cells/mcL',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    prefixIcon: const Icon(Icons.science),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Add Test Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _addTest,
                            icon: const Icon(Icons.add),
                            label: Text(
                              _isCriticalChecked ? 'Add Test (Critical)' : 'Add Test',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isCriticalChecked 
                                  ? Colors.red 
                                  : (_patient.critial ? Colors.red : Colors.blue),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Tests Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        'Test History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _patient.critial ? Colors.red.shade800 : Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_patient.tests.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tests List
                Expanded(
                  child: _patient.tests.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.science,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No tests recorded',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add a test using the form above',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _patient.tests.length,
                          itemBuilder: (context, index) {
                            final test = _patient.tests[index];
                            final testColor = _getTestColor(test.testType);
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: testColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                leading: CircleAvatar(
                                  backgroundColor: testColor.withOpacity(0.2),
                                  child: Icon(
                                    _getTestIcon(test.testType),
                                    color: testColor,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  test.testType,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: testColor,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      'Result: ${test.testResult}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatDate(test.testDate),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                  onPressed: () => _deleteTest(test.id),
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Return Button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text(
                        'Return to Patient List',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _patient.critial ? Colors.red : Colors.blue,
                        side: BorderSide(
                          color: _patient.critial ? Colors.red : Colors.blue,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}