// lib/widgets/address_picker_dialog.dart

import 'package:flutter/material.dart';

class AddressPickerDialog extends StatefulWidget {
  final String currentAddress;
  final Function(String) onAddressSelected;

  const AddressPickerDialog({
    Key? key,
    required this.currentAddress,
    required this.onAddressSelected,
  }) : super(key: key);

  @override
  State<AddressPickerDialog> createState() => _AddressPickerDialogState();
}

class _AddressPickerDialogState extends State<AddressPickerDialog> {
  late TextEditingController _addressController;
  String _selectedRegion = 'Lilongwe';
  String _selectedArea = 'Area 18';
  
  final List<String> _regions = ['Lilongwe', 'Blantyre', 'Zomba', 'Mzuzu'];
  final Map<String, List<String>> _areas = {
    'Lilongwe': ['Area 18', 'Area 25', 'Area 47', 'Kanengo', 'Lilongwe City Center'],
    'Blantyre': ['Chichiri', 'Limbe', 'Ginnery Corner', 'Blantyre City Center'],
    'Zomba': ['Zomba City Center', 'Chancellor College', 'Zomba Central'],
    'Mzuzu': ['Mzuzu City Center', 'Katoto', 'Luwinga', 'Area 1'],
  };

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.currentAddress);
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery Address',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Region Dropdown
            DropdownButtonFormField<String>(
              value: _selectedRegion,
              decoration: const InputDecoration(
                labelText: 'Region',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _regions.map((region) {
                return DropdownMenuItem(value: region, child: Text(region));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRegion = value!;
                  _selectedArea = _areas[_selectedRegion]?.first ?? '';
                });
              },
            ),
            const SizedBox(height: 12),

            // Area Dropdown
            DropdownButtonFormField<String>(
              value: _selectedArea,
              decoration: const InputDecoration(
                labelText: 'Area',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: (_areas[_selectedRegion] ?? []).map((area) {
                return DropdownMenuItem(value: area, child: Text(area));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedArea = value!;
                });
              },
            ),
            const SizedBox(height: 12),

            // Detailed Address
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Detailed Address / Landmark',
                hintText: 'e.g., House #123, near Shoprite',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final fullAddress = '$_selectedArea, $_selectedRegion - ${_addressController.text}';
                      widget.onAddressSelected(fullAddress);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A1A2B),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}