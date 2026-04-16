// lib/patient_details.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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
  bool _isLoading = true;
  String? _errorMessage;
  
  // Filter state
  String? _selectedFilterType;
  List<PatientsTest> _filteredTests = [];
  
  // Graph view state
  bool _showGraph = false;

  // Test types for filter
  final List<String> _filterTypes = [
    'All',
    'Blood Type',
    'Blood Pressure',
    'Blood Sugar',
    'Blood Count',
  ];

  // Test types for adding new test
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

  // Edit form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  // Blood pressure thresholds
  static const int SYSTOLIC_HIGH_THRESHOLD = 180;
  static const int SYSTOLIC_LOW_THRESHOLD = 90;
  static const int DIASTOLIC_HIGH_THRESHOLD = 120;
  static const int DIASTOLIC_LOW_THRESHOLD = 60;

  @override
  void initState() {
    super.initState();
    _patient = widget.patient;
    _filteredTests = _patient.tests;
    _selectedFilterType = 'All';
    _fetchPatientData();
    _bloodPressureController.addListener(_checkBloodPressureForCritical);
  }

  @override
  void dispose() {
    _bloodPressureController.removeListener(_checkBloodPressureForCritical);
    _bloodPressureController.dispose();
    _bloodSugarController.dispose();
    _bloodCountController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _applyFilter(String? filterType) {
    setState(() {
      _selectedFilterType = filterType;
      _showGraph = false; // Reset graph view when filter changes
      if (filterType == null || filterType == 'All') {
        _filteredTests = _patient.tests;
      } else {
        _filteredTests = _patient.tests.where((test) => test.testType == filterType).toList();
      }
    });
  }

  void _toggleGraphView() {
    setState(() {
      _showGraph = !_showGraph;
    });
  }

  bool _isBloodPressureCritical(String bpValue) {
    final parts = bpValue.split('/');
    if (parts.length != 2) return false;
    
    try {
      final systolic = int.tryParse(parts[0].trim());
      final diastolic = int.tryParse(parts[1].trim().split(' ')[0]);
      
      if (systolic == null || diastolic == null) return false;
      
      return (systolic >= SYSTOLIC_HIGH_THRESHOLD || 
              systolic <= SYSTOLIC_LOW_THRESHOLD ||
              diastolic >= DIASTOLIC_HIGH_THRESHOLD || 
              diastolic <= DIASTOLIC_LOW_THRESHOLD);
    } catch (e) {
      return false;
    }
  }

  void _checkBloodPressureForCritical() {
    if (_selectedTestType == 'Blood Pressure') {
      final bpValue = _bloodPressureController.text.trim();
      setState(() {
        _isCriticalChecked = _isBloodPressureCritical(bpValue);
      });
    }
  }

  Future<void> _fetchPatientData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final updatedPatient = await PatientApiService.getPatient(widget.patient.id);
      if (mounted) {
        setState(() {
          _patient = updatedPatient;
          _applyFilter(_selectedFilterType);
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

  // NEW METHOD: Toggle critical status
  Future<void> _toggleCriticalStatus() async {
    final newCriticalStatus = !_patient.critial;
    
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(newCriticalStatus ? 'Mark as Critical?' : 'Remove Critical Status?'),
        content: Text(
          newCriticalStatus 
              ? 'Are you sure you want to mark ${_patient.name} as critical?'
              : 'Are you sure you want to remove the critical status from ${_patient.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: newCriticalStatus ? Colors.red : Colors.green,
            ),
            child: Text(newCriticalStatus ? 'Yes, Mark Critical' : 'Yes, Remove'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final updatedPatient = await PatientApiService.updatePatientCriticalStatus(
        patientId: _patient.id,
        critical: newCriticalStatus,
      );
      
      if (mounted) {
        setState(() {
          _patient = updatedPatient;
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newCriticalStatus 
                  ? '${_patient.name} has been marked as CRITICAL!'
                  : 'Critical status removed from ${_patient.name}',
            ),
            backgroundColor: newCriticalStatus ? Colors.red : Colors.green,
            duration: const Duration(seconds: 3),
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
            content: Text('Failed to update critical status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // NEW METHOD: Edit patient details
  Future<void> _editPatientDetails() async {
    // Populate controllers with current values
    _nameController.text = _patient.name;
    _ageController.text = _patient.age.toString();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Patient Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ageController,
              decoration: const InputDecoration(
                labelText: 'Age',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              keyboardType: TextInputType.text,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    
    if (result != true) return;
    
    // Validate inputs
    final newName = _nameController.text.trim();
    final newAge = _ageController.text.trim();
    
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (newAge.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Age cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final updatedPatient = await PatientApiService.updatePatientDetails(
        patientId: _patient.id,
        name: newName,
        age: newAge,
      );
      
      if (mounted) {
        setState(() {
          _patient = updatedPatient;
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Patient details updated successfully'),
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
            content: Text('Failed to update patient details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
      final newTest = PatientsTest(
        id: '',
        testType: _selectedTestType!,
        testResult: testResult,
        testDate: DateTime.now(),
      );

      final bool finalCriticalStatus = _patient.critial || _isCriticalChecked || shouldUpdateCritical;

      await PatientApiService.addPatientTests(
        patientId: _patient.id,
        tests: [newTest],
        critial: finalCriticalStatus,
      );

      final updatedPatient = await PatientApiService.getPatient(_patient.id);
      
      if (mounted) {
        setState(() {
          _patient = updatedPatient;
          _applyFilter(_selectedFilterType);
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              finalCriticalStatus && !widget.patient.critial 
                  ? 'Test added successfully. Patient marked as CRITICAL!' 
                  : 'Test added successfully'
            ),
            backgroundColor: finalCriticalStatus ? Colors.orange : Colors.green,
          ),
        );
      }

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

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

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

  // Parse numeric value from test result
  double _parseNumericValue(String result, String testType) {
    try {
      if (testType == 'Blood Pressure') {
        // For blood pressure, we'll use systolic value for the graph
        final parts = result.split('/');
        if (parts.isNotEmpty) {
          return double.tryParse(parts[0].trim()) ?? 0;
        }
      } else {
        // For blood sugar and blood count, extract the first number
        final match = RegExp(r'(\d+\.?\d*)').firstMatch(result);
        if (match != null) {
          return double.tryParse(match.group(1) ?? '0') ?? 0;
        }
      }
    } catch (e) {
      return 0;
    }
    return 0;
  }

  // Build graph for numeric test types
  Widget _buildGraph() {
    if (_filteredTests.isEmpty) {
      return const Center(
        child: Text('No data to display'),
      );
    }

    // Sort tests by date
    final sortedTests = List<PatientsTest>.from(_filteredTests)
      ..sort((a, b) => a.testDate.compareTo(b.testDate));

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: _getYInterval(),
            verticalInterval: 1,
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value >= 0 && value < sortedTests.length) {
                    final date = sortedTests[value.toInt()].testDate;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${date.month}/${date.day}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: _getYInterval(),
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(value.toInt().toString());
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.shade300),
          ),
          minX: 0,
          maxX: (sortedTests.length - 1).toDouble(),
          minY: _getMinYValue(),
          maxY: _getMaxYValue(),
          lineBarsData: [
            LineChartBarData(
              spots: _generateSpots(sortedTests),
              isCurved: true,
              color: _getTestColor(_selectedFilterType!),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: _getTestColor(_selectedFilterType!),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: _getTestColor(_selectedFilterType!).withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _generateSpots(List<PatientsTest> tests) {
    List<FlSpot> spots = [];
    for (int i = 0; i < tests.length; i++) {
      final value = _parseNumericValue(tests[i].testResult, _selectedFilterType!);
      spots.add(FlSpot(i.toDouble(), value));
    }
    return spots;
  }

  double _getMinYValue() {
    if (_filteredTests.isEmpty) return 0;
    
    double min = double.infinity;
    for (var test in _filteredTests) {
      final value = _parseNumericValue(test.testResult, _selectedFilterType!);
      if (value < min) min = value;
    }
    return (min - 10).clamp(0, double.infinity);
  }

  double _getMaxYValue() {
    if (_filteredTests.isEmpty) return 100;
    
    double max = 0;
    for (var test in _filteredTests) {
      final value = _parseNumericValue(test.testResult, _selectedFilterType!);
      if (value > max) max = value;
    }
    return max + 10;
  }

  double _getYInterval() {
    final range = _getMaxYValue() - _getMinYValue();
    if (range <= 20) return 5;
    if (range <= 50) return 10;
    if (range <= 100) return 20;
    return 50;
  }

  // Check if current filter type supports graph
  bool _canShowGraph() {
    return _selectedFilterType == 'Blood Pressure' ||
           _selectedFilterType == 'Blood Sugar' ||
           _selectedFilterType == 'Blood Count';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _patient.tests.isEmpty && _errorMessage == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loading...'),
          backgroundColor: _patient.critial ? Colors.red : Colors.blue,
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

    final canShowGraph = _canShowGraph();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _patient.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _patient.critial ? Colors.red : Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // Edit button
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Patient Details',
            onPressed: _editPatientDetails,
          ),
          // Toggle critical status button
          IconButton(
            icon: Icon(
              _patient.critial ? Icons.medical_services : Icons.warning,
              color: Colors.white,
            ),
            tooltip: _patient.critial ? 'Remove Critical Status' : 'Mark as Critical',
            onPressed: _toggleCriticalStatus,
          ),
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
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Edit button in card
                          OutlinedButton.icon(
                            onPressed: _editPatientDetails,
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit Details'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _patient.critial ? Colors.red : Colors.blue,
                              side: BorderSide(
                                color: _patient.critial ? Colors.red : Colors.blue,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Critical toggle button in card
                          _patient.critial
                              ? OutlinedButton.icon(
                                  onPressed: _toggleCriticalStatus,
                                  icon: const Icon(Icons.check_circle, size: 18),
                                  label: const Text('Non-Critical'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.green,
                                    side: const BorderSide(color: Colors.green),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                )
                              : OutlinedButton.icon(
                                  onPressed: _toggleCriticalStatus,
                                  icon: const Icon(Icons.warning, size: 18),
                                  label: const Text('Mark Critical'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                        ],
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

                // Filter Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Test History',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _patient.critial ? Colors.red.shade800 : Colors.blue.shade800,
                            ),
                          ),
                          Row(
                            children: [
                              if (canShowGraph && _filteredTests.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _showGraph 
                                          ? _getTestColor(_selectedFilterType!).withOpacity(0.2)
                                          : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: _showGraph 
                                            ? _getTestColor(_selectedFilterType!)
                                            : Colors.grey.shade400,
                                      ),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _toggleGraphView,
                                        borderRadius: BorderRadius.circular(20),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                _showGraph ? Icons.list : Icons.show_chart,
                                                size: 16,
                                                color: _showGraph 
                                                    ? _getTestColor(_selectedFilterType!)
                                                    : Colors.grey.shade700,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _showGraph ? 'List' : 'Graph',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: _showGraph 
                                                      ? _getTestColor(_selectedFilterType!)
                                                      : Colors.grey.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_filteredTests.length}/${_patient.tests.length}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _filterTypes.map((type) {
                            final isSelected = _selectedFilterType == type;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(type),
                                selected: isSelected,
                                onSelected: (selected) {
                                  _applyFilter(selected ? type : 'All');
                                },
                                backgroundColor: Colors.grey.shade100,
                                selectedColor: type == 'All' 
                                    ? Colors.blue.shade100 
                                    : _getTestColor(type).withOpacity(0.2),
                                checkmarkColor: type == 'All' 
                                    ? Colors.blue 
                                    : _getTestColor(type),
                                labelStyle: TextStyle(
                                  color: isSelected 
                                      ? (type == 'All' ? Colors.blue : _getTestColor(type))
                                      : Colors.grey.shade700,
                                  fontWeight: isSelected ? FontWeight.bold : null,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Graph or List View
                Expanded(
                  child: _filteredTests.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.filter_list,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _selectedFilterType == 'All' 
                                    ? 'No tests recorded'
                                    : 'No $_selectedFilterType tests found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              if (_selectedFilterType != 'All')
                                TextButton(
                                  onPressed: () => _applyFilter('All'),
                                  child: const Text('Show all tests'),
                                ),
                            ],
                          ),
                        )
                      : _showGraph && canShowGraph
                          ? _buildGraph()
                          : ListView.builder(
                              key: ValueKey('${_selectedFilterType}_${_filteredTests.length}'),
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredTests.length,
                              itemBuilder: (context, index) {
                                final test = _filteredTests[index];
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
                                    trailing: const IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red, size: 20),
                                      onPressed: null, // Disabled
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