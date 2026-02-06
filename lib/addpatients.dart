import 'package:flutter/material.dart';

class AddPatients extends StatefulWidget {
  const AddPatients({super.key});

  @override
  State<AddPatients> createState() => _AddPatientsState();
}

class _AddPatientsState extends State<AddPatients> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _conditionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _conditionController.dispose();
    super.dispose();
  }

  void _savePatient() {
    if (_formKey.currentState!.validate()) {
      // Form is valid, save the data
      final name = _nameController.text.trim();
      final age = _ageController.text.trim();
      final condition = _conditionController.text.trim();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Patient saved successfully!'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // Clear form
      _formKey.currentState!.reset();
      
      // Optional: Navigate back after saving
      // Navigator.pop(context);
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
      ),
      body: SingleChildScrollView(
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

              // Medical Condition Input
              _buildTextField(
                controller: _conditionController,
                label: 'Medical Condition',
                hint: 'Describe the medical condition',
                prefixIcon: Icons.medical_services_outlined,
                maxLines: 4,
                validator: (value) => _validateRequired(value, 'medical condition'),
              ),
              const SizedBox(height: 40),

              // Action Buttons
              _buildActionButtons(context),
            ],
          ),
        ),
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
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 10),
        Text(
          'Patient Registration',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Please fill in the patient details below',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
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
        hintText: hint,
        prefixIcon: Icon(prefixIcon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        // Cancel Button
        
        const SizedBox(width: 16),

        // Save Button
        Expanded(
          child: ElevatedButton(
            onPressed: _savePatient,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.save, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Save Patient',
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