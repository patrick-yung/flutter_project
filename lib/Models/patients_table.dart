import 'package:flutter/material.dart';
import 'patients.dart';

class PatientsScreen extends StatelessWidget {
  const PatientsScreen({super.key, required this.patients});
  
  final List<Patient> patients;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header Row
          _buildTableHeader(),
          
          // Data Rows
          Expanded(
            child: _buildTableBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Row(
        children: [
          _buildHeaderColumn('ID', flex: 1),
          _buildVerticalDivider(),
          _buildHeaderColumn('Patient Name', flex: 3),
          _buildVerticalDivider(),
          _buildHeaderColumn('Age', flex: 1),
        ],
      ),
    );
  }

  Widget _buildTableBody() {
    return ListView.separated(
      itemCount: patients.length,
      separatorBuilder: (context, index) => Divider(
        height: 0,
        color: Colors.grey.shade400,
        thickness: 1,
      ),
      itemBuilder: (context, index) {
        final patient = patients[index];
        return Container(
          color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
          child: Row(
            children: [
              _buildDataColumn(patient.id, flex: 1),
              _buildVerticalDivider(),
              _buildDataColumn(patient.name, flex: 3),
              _buildVerticalDivider(),
              _buildDataColumn(patient.age.toString(), flex: 1),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderColumn(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.blue.shade800,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildDataColumn(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      color: Colors.grey.shade400,
    );
  }
}