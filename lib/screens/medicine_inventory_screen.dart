import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import '../models/medicine.dart';
import '../services/medicine_service.dart';

class MedicineInventoryScreen extends StatefulWidget {
  const MedicineInventoryScreen({super.key});

  @override
  State<MedicineInventoryScreen> createState() =>
      _MedicineInventoryScreenState();
}

class _MedicineInventoryScreenState extends State<MedicineInventoryScreen>
    with SingleTickerProviderStateMixin {
  final MedicineService _medicineService = MedicineService();
  late TabController _tabController;
  bool _isLoading = false;
  final _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  // Removed unused variables

  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController(text: 'pcs');
  final _supplierController = TextEditingController();
  final _batchNumberController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();
  final _priceController = TextEditingController();

  // Form state
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));
  Medicine? _editingMedicine;
  final List<String> _categories = [
    'Antibiotics',
    'Pain Relief',
    'Vitamins',
    'First Aid',
    'Chronic Conditions',
    'Other'
  ];
  String _inventorySearch = '';
  String _selectedCategoryFilter = 'All';
  String _selectedStockFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Initialize with default values for testing
    if (kDebugMode) {
      _nameController.text = 'Test Medicine';
      _descriptionController.text = 'Test Description';
      _categoryController.text = 'Test Category';
      _quantityController.text = '100';
      _unitController.text = 'pcs';
      _priceController.text = '10.50';
      _supplierController.text = 'Test Supplier';
      _expiryDate = DateTime.now().add(const Duration(days: 365));
    }
  }

  Widget _buildIssueToPatientTab() {
    final patientNameController = TextEditingController();
    final medicineNameController = TextEditingController();
    final quantityController = TextEditingController();
    final purposeController = TextEditingController();
    final staffController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    Future<void> pickDate() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime.now().subtract(const Duration(days: 365)),
        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      );
      if (picked != null) {
        selectedDate = picked;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Issue Medicine to Patient',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFormField(
              controller: patientNameController,
              label: 'Patient name (from CHRMS database)',
              icon: Icons.person,
            ),
            const SizedBox(height: 12),
            _buildFormField(
              controller: medicineNameController,
              label: 'Medicine issued (exact name)',
              icon: Icons.medication,
            ),
            const SizedBox(height: 12),
            _buildFormField(
              controller: quantityController,
              label: 'Quantity',
              icon: Icons.numbers,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _buildFormField(
              controller: purposeController,
              label: 'Purpose / illness',
              icon: Icons.description,
            ),
            const SizedBox(height: 12),
            _buildFormField(
              controller: staffController,
              label: 'Staff who issued',
              icon: Icons.badge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: pickDate,
                icon: const Icon(Icons.calendar_today),
                label: Text('Date: ${_formatDate(selectedDate)}'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (patientNameController.text.trim().isEmpty ||
                      medicineNameController.text.trim().isEmpty ||
                      quantityController.text.trim().isEmpty) {
                    _showError(
                        'Please fill in patient, medicine, and quantity.');
                    return;
                  }

                  _showSuccessMessage(
                      'Medicine issued (mock, hook up backend).');
                },
                icon: const Icon(Icons.add),
                label: const Text('Issue Medicine'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockLogsTab() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Stock Logs',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          CircularProgressIndicator(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _supplierController.dispose();
    _batchNumberController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // Format date for display
  String _formatDate(DateTime date) {
    return DateFormat('MMM d, y').format(date);
  }

  Future<void> _saveMedicine() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final medicine = Medicine(
        id: _editingMedicine?.id ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _categoryController.text.trim(),
        quantity: int.tryParse(_quantityController.text) ?? 0,
        unit: _unitController.text.trim(),
        price: double.tryParse(_priceController.text) ?? 0.0,
        supplier: _supplierController.text.trim(),
        batchNumber: _batchNumberController.text.trim().isEmpty
            ? null
            : _batchNumberController.text.trim(),
        dosage: _dosageController.text.trim().isEmpty
            ? null
            : _dosageController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        expiryDate: _expiryDate,
        createdAt: _editingMedicine?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_editingMedicine == null) {
        await _medicineService.addMedicine(medicine);
        if (!mounted) return;
        _showSuccessMessage('Medicine added successfully');
      } else {
        await _medicineService.updateMedicine(medicine);
        if (!mounted) return;
        _showSuccessMessage('Medicine updated successfully');
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showSuccessMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _editMedicine(Medicine medicine) {
    setState(() {
      _editingMedicine = medicine;
      _nameController.text = medicine.name;
      _descriptionController.text = medicine.description;
      _categoryController.text = medicine.category;
      _quantityController.text = medicine.quantity.toString();
      _unitController.text = medicine.unit;
      _priceController.text = medicine.price.toStringAsFixed(2);
      _supplierController.text = medicine.supplier;
      _batchNumberController.text = medicine.batchNumber ?? '';
      _dosageController.text = medicine.dosage ?? '';
      _notesController.text = medicine.notes ?? '';
      _expiryDate = medicine.expiryDate;
    });
    _showMedicineForm();
  }

  Future<void> _deleteMedicine(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medicine'),
        content: const Text('Are you sure you want to delete this medicine?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _medicineService.deleteMedicine(id);
      if (!mounted) return;
      _showSuccessMessage('Medicine deleted successfully');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _showMedicineForm() async {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color:
                  Theme.of(context).colorScheme.onSurface.withValues(alpha: 25),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _editingMedicine == null
                          ? 'Add New Medicine'
                          : 'Edit Medicine',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: _nameController,
                  label: 'Medicine Name',
                  hint: 'Enter medicine name',
                  icon: Icons.medication,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a medicine name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildFormField(
                  controller: _descriptionController,
                  label: 'Description',
                  hint: 'Enter description (optional)',
                  icon: Icons.description,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildFormField(
                        controller: _quantityController,
                        label: 'Quantity',
                        hint: '0',
                        icon: Icons.numbers,
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFormField(
                        controller: _unitController,
                        label: 'Unit',
                        hint: 'pcs, mg, ml, etc.',
                        icon: Icons.scale,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildFormField(
                  controller: _priceController,
                  label: 'Price',
                  hint: '0.00',
                  icon: Icons.attach_money,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildFormField(
                  controller: _supplierController,
                  label: 'Supplier',
                  hint: 'Enter supplier name',
                  icon: Icons.business,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter supplier name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildFormField(
                  controller: _batchNumberController,
                  label: 'Batch Number',
                  hint: 'Enter batch number (optional)',
                  icon: Icons.confirmation_number,
                ),
                const SizedBox(height: 12),
                _buildFormField(
                  controller: _categoryController,
                  label: 'Category',
                  hint: 'Select category',
                  icon: Icons.category,
                  readOnly: true,
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => _buildCategorySelector(),
                    );
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildDateField(
                  label: 'Expiry Date',
                  value: _expiryDate,
                  onChanged: (date) {
                    if (date != null) {
                      setState(() {
                        _expiryDate = date;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveMedicine,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text(
                            _editingMedicine == null
                                ? 'Add Medicine'
                                : 'Update Medicine',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                if (_editingMedicine != null)
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.pop(context);
                            _deleteMedicine(_editingMedicine!.id);
                          },
                    child: const Text(
                      'Delete Medicine',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    TextInputType? keyboardType,
    int? maxLines,
    bool readOnly = false,
    Function()? onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime value,
    required Function(DateTime?) onChanged,
  }) {
    return ListTile(
      title: Text(label),
      subtitle: Text(_formatDate(value)),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 3650)),
        );
        if (date != null) {
          onChanged(date);
        }
      },
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Select Category',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._categories.map((category) => ListTile(
              title: Text(category),
              onTap: () {
                setState(() {
                  _categoryController.text = category;
                });
                Navigator.pop(context);
              },
            )),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildInventoryTab() {
    return StreamBuilder<List<Medicine>>(
      stream: _medicineService.getMedicines(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final medicines = snapshot.data ?? [];
        // Apply search and filter
        List<Medicine> filtered = medicines;
        if (_inventorySearch.isNotEmpty) {
          final q = _inventorySearch.toLowerCase();
          filtered =
              filtered.where((m) => m.name.toLowerCase().contains(q)).toList();
        }
        if (_selectedCategoryFilter != 'All') {
          filtered = filtered
              .where((m) =>
                  m.category.toLowerCase() ==
                  _selectedCategoryFilter.toLowerCase())
              .toList();
        }
        if (_selectedStockFilter != 'All') {
          filtered = filtered.where((m) {
            switch (_selectedStockFilter) {
              case 'Low Stock':
                return m.quantity > 0 && m.quantity < 10;
              case 'Out of Stock':
                return m.quantity <= 0;
              case 'Expiring Soon':
                final now = DateTime.now();
                final soon = now.add(const Duration(days: 30));
                return m.expiryDate.isBefore(soon);
            }
            return true;
          }).toList();
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search medicines by name',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _inventorySearch = value.trim();
                  });
                },
              ),
              const SizedBox(height: 12),
              // Filter "chips" row 1
              Row(
                children: [
                  Expanded(
                    child: _buildFilterPill(
                      label: 'Category',
                      value: _selectedCategoryFilter,
                      onTap: () async {
                        final selected = await _pickCategoryFilter();
                        if (selected != null) {
                          setState(() {
                            _selectedCategoryFilter = selected;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFilterPill(
                      label: 'Stock',
                      value: _selectedStockFilter,
                      onTap: () async {
                        final selected = await _pickStockFilter();
                        if (selected != null) {
                          setState(() {
                            _selectedStockFilter = selected;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Register / Restock row (actions similar to image layout)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showMedicineForm,
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Register'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (medicines.isEmpty) {
                          _showError('No medicines to restock yet.');
                          return;
                        }
                        _showMedicineForm();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Restock'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text('No medicines found.'),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final medicine = filtered[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 0, vertical: 4),
                        child: ListTile(
                          title: Text(medicine.name),
                          subtitle: Text(
                              '${medicine.quantity} ${medicine.unit} • ${medicine.category}'),
                          trailing: Text(
                            medicine.price > 0
                                ? '\\${medicine.price.toStringAsFixed(2)}'
                                : '-',
                          ),
                          onTap: () => _editMedicine(medicine),
                          onLongPress: () => _deleteMedicine(medicine.id),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterPill({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onPressed: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ],
      ),
    );
  }

  Future<String?> _pickCategoryFilter() async {
    final options = ['All', ..._categories];
    return showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: options
              .map(
                (c) => ListTile(
                  title: Text(c),
                  onTap: () => Navigator.of(ctx).pop(c),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Future<String?> _pickStockFilter() async {
    const options = ['All', 'Low Stock', 'Out of Stock', 'Expiring Soon'];
    return showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: options
              .map(
                (c) => ListTile(
                  title: Text(c),
                  onTap: () => Navigator.of(ctx).pop(c),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Inventory Summary',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<Medicine>>(
            stream: _medicineService.getMedicines(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final meds = snapshot.data ?? [];
              final totalItems = meds.length;
              const lowStockThreshold = 10;
              final lowStockCount = meds
                  .where(
                      (m) => (m.quantity) < lowStockThreshold && m.quantity > 0)
                  .length;
              final now = DateTime.now();
              final soon = now.add(const Duration(days: 30));
              final expiringCount =
                  meds.where((m) => m.expiryDate.isBefore(soon)).length;
              final outOfStockCount =
                  meds.where((m) => (m.quantity) <= 0).length;

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Total Items',
                          totalItems.toString(),
                          Icons.medication,
                          Colors.blue,
                          onTap: () => _tabController.animateTo(1),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Low Stock',
                          lowStockCount.toString(),
                          Icons.warning_amber,
                          Colors.orange,
                          onTap: () => _tabController.animateTo(1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Expiring Soon',
                          expiringCount.toString(),
                          Icons.calendar_today,
                          Colors.red,
                          onTap: () => _tabController.animateTo(1),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Out of Stock',
                          outOfStockCount.toString(),
                          Icons.block,
                          Colors.redAccent,
                          onTap: () => _tabController.animateTo(1),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Low Stock Items',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildLowStockList(context),
          const SizedBox(height: 24),
          const Text(
            'Expiring Soon',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildNearExpiryList(context),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  Icon(icon, color: color),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLowStockList(BuildContext context) {
    return StreamBuilder<List<Medicine>>(
      stream: _medicineService.getMedicines(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        final medicines = snapshot.data ?? [];
        final lowStockItems = medicines.where((m) => m.quantity < 10).toList();

        if (lowStockItems.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No low stock items'),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: lowStockItems.length,
          itemBuilder: (context, index) {
            final medicine = lowStockItems[index];
            return ListTile(
              title: Text(medicine.name),
              subtitle: Text('${medicine.quantity} ${medicine.unit} remaining'),
              trailing: IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () {
                  _editMedicine(medicine);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNearExpiryList(BuildContext context) {
    return StreamBuilder<List<Medicine>>(
      stream: _medicineService.getMedicines(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        final medicines = snapshot.data ?? [];
        final now = DateTime.now();
        final thirtyDaysFromNow = now.add(const Duration(days: 30));

        final nearExpiryItems = medicines
            .where((m) => m.expiryDate.isBefore(thirtyDaysFromNow))
            .toList()
          ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

        if (nearExpiryItems.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No items expiring soon'),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: nearExpiryItems.length,
          itemBuilder: (context, index) {
            final medicine = nearExpiryItems[index];
            final daysUntilExpiry = medicine.expiryDate.difference(now).inDays;

            return ListTile(
              title: Text(medicine.name),
              subtitle: Text(
                'Expires in $daysUntilExpiry days • ${_formatDate(medicine.expiryDate)}',
              ),
              trailing: Text('${medicine.quantity} ${medicine.unit}'),
              onTap: () => _editMedicine(medicine),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Inventory'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.medication), text: 'Inventory List'),
            Tab(icon: Icon(Icons.add_circle_outline), text: 'Issue to Patient'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Stock Logs'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate:
                    _MedicineSearchDelegate(_medicineService, _editMedicine),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(),
          _buildInventoryTab(),
          _buildIssueToPatientTab(),
          _buildStockLogsTab(),
        ],
      ),
    );
  }
}

class _MedicineSearchDelegate extends SearchDelegate<Medicine?> {
  final MedicineService _medicineService;
  final Function(Medicine) _onMedicineSelected;

  _MedicineSearchDelegate(this._medicineService, this._onMedicineSelected);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    return StreamBuilder<List<Medicine>>(
      stream: _medicineService.getMedicines(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final medicines = snapshot.data ?? [];
        final results = query.isEmpty
            ? medicines
            : medicines
                .where((m) =>
                    m.name.toLowerCase().contains(query.toLowerCase()) ||
                    m.category.toLowerCase().contains(query.toLowerCase()) ||
                    (m.batchNumber
                            ?.toLowerCase()
                            .contains(query.toLowerCase()) ??
                        false))
                .toList();

        if (results.isEmpty) {
          return const Center(child: Text('No medicines found'));
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final medicine = results[index];
            return ListTile(
              title: Text(medicine.name),
              subtitle: Text(
                  '${medicine.category} • ${medicine.quantity} ${medicine.unit}'),
              trailing: Text('\$${medicine.price.toStringAsFixed(2)}'),
              onTap: () {
                _onMedicineSelected(medicine);
                close(context, medicine);
              },
            );
          },
        );
      },
    );
  }
}
