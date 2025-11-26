import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/medicine_service.dart';
import '../models/medicine.dart';

class MedicineFormScreen extends StatefulWidget {
  final Medicine? medicine;

  const MedicineFormScreen({super.key, this.medicine});

  @override
  State<MedicineFormScreen> createState() => _MedicineFormScreenState();
}

class _MedicineFormScreenState extends State<MedicineFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _categoryController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  late TextEditingController _unitController;
  late TextEditingController _expiryDateController;
  late TextEditingController _supplierController;
  late TextEditingController _batchNumberController;
  late TextEditingController _storageConditionsController;
  late TextEditingController _sideEffectsController;
  late TextEditingController _dosageController;
  late TextEditingController _notesController;

  String? _selectedCategory;
  final List<String> _categories = [
    'Antibiotics',
    'Pain Relief',
    'Vitamins',
    'First Aid',
    'Chronic Conditions',
    'Other',
  ];

  final List<String> _units = [
    'pcs',
    'box',
    'bottle',
    'pack',
    'vial',
    'ampule'
  ];
  String? _selectedUnit;

  @override
  void initState() {
    super.initState();
    final medicine = widget.medicine;

    _nameController = TextEditingController(text: medicine?.name ?? '');
    _descriptionController =
        TextEditingController(text: medicine?.description ?? '');
    _categoryController = TextEditingController(text: medicine?.category ?? '');
    _priceController =
        TextEditingController(text: medicine?.price.toString() ?? '');
    _quantityController =
        TextEditingController(text: medicine?.quantity.toString() ?? '1');
    _unitController = TextEditingController(text: medicine?.unit ?? 'pcs');
    _expiryDateController = TextEditingController(
      text: medicine != null
          ? DateFormat('yyyy-MM-dd').format(medicine.expiryDate)
          : DateFormat('yyyy-MM-dd')
              .format(DateTime.now().add(const Duration(days: 365))),
    );
    _supplierController = TextEditingController(text: medicine?.supplier ?? '');
    _batchNumberController =
        TextEditingController(text: medicine?.batchNumber ?? '');
    _storageConditionsController =
        TextEditingController(text: medicine?.storageConditions ?? '');
    _sideEffectsController =
        TextEditingController(text: medicine?.sideEffects ?? '');
    _dosageController = TextEditingController(text: medicine?.dosage ?? '');
    _notesController = TextEditingController(text: medicine?.notes ?? '');

    _selectedCategory = medicine?.category;
    _selectedUnit = medicine?.unit ?? 'pcs';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _expiryDateController.dispose();
    _supplierController.dispose();
    _batchNumberController.dispose();
    _storageConditionsController.dispose();
    _sideEffectsController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      setState(() {
        _expiryDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final medicineService =
        Provider.of<MedicineService>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final medicine = Medicine(
        id: widget.medicine?.id ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory ?? _categoryController.text.trim(),
        price: double.parse(_priceController.text),
        quantity: int.parse(_quantityController.text),
        unit: _selectedUnit ?? 'pcs',
        expiryDate: DateFormat('yyyy-MM-dd').parse(_expiryDateController.text),
        supplier: _supplierController.text.trim(),
        batchNumber: _batchNumberController.text.trim().isNotEmpty
            ? _batchNumberController.text.trim()
            : null,
        storageConditions: _storageConditionsController.text.trim().isNotEmpty
            ? _storageConditionsController.text.trim()
            : null,
        sideEffects: _sideEffectsController.text.trim().isNotEmpty
            ? _sideEffectsController.text.trim()
            : null,
        dosage: _dosageController.text.trim().isNotEmpty
            ? _dosageController.text.trim()
            : null,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        createdAt: widget.medicine?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.medicine == null) {
        await medicineService.addMedicine(medicine);
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Medicine added successfully')),
        );
      } else {
        await medicineService.updateMedicine(medicine);
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Medicine updated successfully')),
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.medicine == null ? 'Add New Medicine' : 'Edit Medicine'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _submitForm,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Basic Information Section
            const Text(
              'Basic Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Medicine Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medication),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter medicine name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Category Dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue!;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a category';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Stock & Pricing Section
            const Text(
              'Stock & Pricing',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                // Quantity
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // Unit
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedUnit,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                    ),
                    items: _units.map((String unit) {
                      return DropdownMenuItem<String>(
                        value: unit,
                        child: Text(unit),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedUnit = newValue!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Price
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price (₱) *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the price';
                }
                if (double.tryParse(value) == null) {
                  return 'Enter a valid price';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Expiry Date
            TextFormField(
              controller: _expiryDateController,
              decoration: InputDecoration(
                labelText: 'Expiry Date *',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.calendar_today),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: () => _selectDate(context),
                ),
              ),
              readOnly: true,
              onTap: () => _selectDate(context),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select expiry date';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Supplier Information
            const Text(
              'Supplier Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Supplier
            TextFormField(
              controller: _supplierController,
              decoration: const InputDecoration(
                labelText: 'Supplier *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter supplier name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Batch Number
            TextFormField(
              controller: _batchNumberController,
              decoration: const InputDecoration(
                labelText: 'Batch/Lot Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.confirmation_number),
              ),
            ),
            const SizedBox(height: 24),

            // Additional Information
            const Text(
              'Additional Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Storage Conditions
            TextFormField(
              controller: _storageConditionsController,
              decoration: const InputDecoration(
                labelText: 'Storage Conditions',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.storage),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Side Effects
            TextFormField(
              controller: _sideEffectsController,
              decoration: const InputDecoration(
                labelText: 'Side Effects',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.warning),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Dosage
            TextFormField(
              controller: _dosageController,
              decoration: const InputDecoration(
                labelText: 'Recommended Dosage',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medication_liquid),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Additional Notes',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
              child: Text(
                  widget.medicine == null ? 'Add Medicine' : 'Update Medicine'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
