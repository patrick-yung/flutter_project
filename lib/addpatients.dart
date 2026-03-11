// lib/addpatients.dart
import 'package:flutter/material.dart';
import '/Backend/patient_api_service.dart';

class AddPatients extends StatefulWidget {
  const AddPatients({super.key});

  @override
  State<AddPatients> createState() => _AddPatientsState();
}

class _AddPatientsState extends State<AddPatients> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  
  bool _isLoading = false;
  bool _isCritical = false; // NEW: Critical status checkbox

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _savePatient() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final name = _nameController.text.trim();
        final age = _ageController.text.trim();
        final department = _departmentController.text.trim();

        // Call the API service with critical parameter
        final patient = await PatientApiService.addPatient(
          name: name,
          age: age,
          department: department,
          critical: _isCritical, // NEW: Pass critical status
        );

        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Patient ${patient.name} added successfully!'),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

          // Clear form
          _formKey.currentState!.reset();
          _nameController.clear();
          _ageController.clear();
          _departmentController.clear();
          
          // Reset critical checkbox
          setState(() {
            _isCritical = false;
          });
          
          // Optional: Navigate back after saving
          // Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding patient: $e'),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }

  String? _validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter age';
    }
    final age = int.tryParse(value);
    if (age == null || age <= 0 || age > 150) {
      return 'Please enter a valid age (1-150)';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Patient'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: _isCritical ? Colors.red : Theme.of(context).primaryColor, // Dynamic app bar color
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  _buildHeader(),
                  const SizedBox(height: 30),

                  // Patient Name Input
                  _buildTextField(
                    controller: _nameController,
                    label: 'Patient Name',
                    hint: 'Enter patient full name',
                    prefixIcon: Icons.person_outline,
                    validator: (value) => _validateRequired(value, 'patient name'),
                  ),
                  const SizedBox(height: 20),

                  // Age Input
                  _buildTextField(
                    controller: _ageController,
                    label: 'Age',
                    hint: 'Enter patient age',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.calendar_today_outlined,
                    validator: _validateAge,
                  ),
                  const SizedBox(height: 20),

                  // Department Input
                  _buildTextField(
                    controller: _departmentController,
                    label: 'Department',
                    hint: 'Enter department (e.g., Cardiology, Neurology)',
                    prefixIcon: Icons.business_outlined,
                    validator: (value) => _validateRequired(value, 'department'),
                  ),
                  const SizedBox(height: 20),

                  // NEW: Critical Status Checkbox
                  Container(
                    decoration: BoxDecoration(
                      color: _isCritical ? Colors.red.shade50 : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isCritical ? Colors.red.shade400 : Colors.grey.shade400,
                        width: 1.5,
                      ),
                    ),
                    child: CheckboxListTile(
                      title: Text(
                        'Critical Condition',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _isCritical ? Colors.red.shade800 : Colors.grey.shade800,
                        ),
                      ),
                      subtitle: Text(
                        _isCritical 
                            ? 'Patient requires immediate attention' 
                            : 'Check if patient is in critical condition',
                        style: TextStyle(
                          color: _isCritical ? Colors.red.shade600 : Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      value: _isCritical,
                      onChanged: (value) {
                        setState(() {
                          _isCritical = value ?? false;
                        });
                      },
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _isCritical ? Colors.red.shade100 : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.warning,
                          color: _isCritical ? Colors.red : Colors.grey,
                          size: 24,
                        ),
                      ),
                      activeColor: Colors.red,
                      checkColor: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Critical Warning Banner (appears when critical is checked)
                  if (_isCritical)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.red.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'This patient will be marked as CRITICAL and will appear with a red background in the patient list.',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Action Buttons
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.person_add_alt_1,
          size: 60,
          color: _isCritical ? Colors.red : Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 10),
        Text(
          'Patient Registration',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _isCritical ? Colors.red.shade800 : Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          _isCritical 
              ? '⚠️ Adding patient in CRITICAL condition' 
              : 'Please fill in the patient details below',
          style: TextStyle(
            fontSize: 14,
            color: _isCritical ? Colors.red.shade600 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: _isCritical ? Colors.red.shade700 : null,
        ),
        hintText: hint,
        prefixIcon: Icon(
          prefixIcon,
          color: _isCritical ? Colors.red.shade700 : null,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _isCritical ? Colors.red.shade300 : Colors.grey.shade400,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _isCritical ? Colors.red : Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: _isCritical ? Colors.red.shade50 : Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Cancel Button
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(
                color: _isCritical ? Colors.red.shade300 : Colors.grey.shade400,
              ),
              foregroundColor: _isCritical ? Colors.red.shade700 : null,
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 16,
                color: _isCritical ? Colors.red.shade700 : Colors.grey.shade700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Save Button
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _savePatient,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: _isCritical ? Colors.red : Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isLoading ? Icons.hourglass_empty : Icons.save,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  _isLoading ? 'Saving...' : 'Save Patient',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}