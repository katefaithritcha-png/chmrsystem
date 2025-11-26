import 'package:flutter/material.dart';
import '../services/population_service.dart' as population_service;

class PopulationTrackingScreen extends StatefulWidget {
  const PopulationTrackingScreen({super.key});

  @override
  State<PopulationTrackingScreen> createState() =>
      _PopulationTrackingScreenState();
}

class _PopulationTrackingScreenState extends State<PopulationTrackingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _currentTabIndex = 0;
  late final population_service.PopulationService _populationService;

  String _residentStatusFilter = 'All';
  String _residentPurokFilter = '';
  String _residentSearchQuery = '';
  String _householdPurokFilter = '';

  @override
  void initState() {
    super.initState();
    _populationService = population_service.PopulationService();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!mounted) return;
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
  }

  Widget _buildHouseholdHighlightCard() {
    return StreamBuilder<Map<String, num>>(
      stream: _populationService.streamHouseholdStats(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildPlaceholderCard('Household Stats');
        }
        final data = snapshot.data;
        final total = data?['households'] ?? 0;
        final avgMembers = data?['avgMembers'] ?? 0;
        return Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Household Snapshot',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Total households: $total'),
                Text('Avg. members per household: '
                    '${avgMembers.toStringAsFixed(1)}'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentMovementsCard() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _populationService.streamRecentMovements(limit: 5),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildPlaceholderCard('Recent Movements');
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildPlaceholderCard('Recent Movements');
        }
        final movements = snapshot.data!;
        return Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Movements',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...movements.map((m) {
                  final status = (m['status'] ?? '').toString();
                  final note = (m['note'] ?? '').toString();
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      status.isEmpty
                          ? note
                          : '$status${note.isEmpty ? '' : ' • $note'}',
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCardStream(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    Stream<int> stream, {
    VoidCallback? onTap,
  }) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snapshot) {
        final value = snapshot.data ?? 0;
        return _buildStatCard(
          context,
          title,
          value.toString(),
          icon,
          color,
          onTap: onTap,
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Population Tracking'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.people), text: 'Residents'),
            Tab(icon: Icon(Icons.home), text: 'Households'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(),
          _buildResidentsTab(),
          _buildHouseholdsTab(),
        ],
      ),
      floatingActionButton:
          _currentTabIndex == 1 ? _buildFloatingActionButton() : null,
    );
  }

  // DASHBOARD
  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCardStream(
                  context,
                  'Total Residents',
                  Icons.people,
                  Colors.blue,
                  _populationService.streamTotalResidents(),
                  onTap: () => _tabController.animateTo(1),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCardStream(
                  context,
                  'Households',
                  Icons.home,
                  Colors.teal,
                  _populationService.streamTotalHouseholds(),
                  onTap: () => _tabController.animateTo(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCardStream(
                  context,
                  'Children (0-5)',
                  Icons.child_care,
                  Colors.orange,
                  _populationService.streamChildren05(),
                  onTap: () => _tabController.animateTo(1),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCardStream(
                  context,
                  'PWDs',
                  Icons.accessible,
                  Colors.purple,
                  _populationService.streamPWDs(),
                  onTap: () => _tabController.animateTo(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildQuickExportsCard(),
          const SizedBox(height: 16),
          _buildGenderRatioCard(),
          const SizedBox(height: 16),
          _buildAgeGroupCard(),
          const SizedBox(height: 16),
          _buildPopulationTrendCard(),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildHouseholdHighlightCard()),
              const SizedBox(width: 12),
              Expanded(child: _buildResidentsByPurokCard()),
            ],
          ),
          const SizedBox(height: 16),
          _buildRecentMovementsCard(),
          const SizedBox(height: 16),
          _buildMonthlySummaryCard(),
        ],
      ),
    );
  }

  Widget _buildQuickExportsCard() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Exports',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _exportButton('Seniors CSV', _exportSeniorsCsv),
                _exportButton('PWD CSV', _exportPwdCsv),
                _exportButton('Pregnant CSV', _exportPregnantCsv),
                _exportButton('Households CSV', _exportHouseholdsCsv),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _exportButton(String label, Future<void> Function() onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: Text(label),
    );
  }

  Future<void> _exportSeniorsCsv() async {
    try {
      final csv = await _populationService.seniorsCsv();
      _showCsvDialog('Seniors CSV', csv);
    } catch (e) {
      _showErrorSnack('Error generating Seniors CSV: $e');
    }
  }

  Future<void> _exportPwdCsv() async {
    try {
      final csv = await _populationService.pwdCsv();
      _showCsvDialog('PWD CSV', csv);
    } catch (e) {
      _showErrorSnack('Error generating PWD CSV: $e');
    }
  }

  Future<void> _exportPregnantCsv() async {
    try {
      final csv = await _populationService.pregnantCsv();
      _showCsvDialog('Pregnant CSV', csv);
    } catch (e) {
      _showErrorSnack('Error generating Pregnant CSV: $e');
    }
  }

  Future<void> _exportHouseholdsCsv() async {
    try {
      final csv = await _populationService.householdSummaryCsv();
      _showCsvDialog('Households CSV', csv);
    } catch (e) {
      _showErrorSnack('Error generating Households CSV: $e');
    }
  }

  void _showCsvDialog(String title, String csv) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(
              csv,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildGenderRatioCard() {
    return StreamBuilder<population_service.PopulationStats>(
      stream: _populationService.watchPopulationStats(),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData) {
          return _buildPlaceholderCard('Gender Ratio');
        }
        final stats = snapshot.data!;
        final male = stats.genderCounts['male'] ?? 0;
        final female = stats.genderCounts['female'] ?? 0;
        final other = stats.genderCounts['other'] ?? 0;
        final total = (male + female + other).clamp(1, 1 << 31);
        String pct(int v) => ((v / total) * 100).toStringAsFixed(1);

        return Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gender Ratio',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Male:   $male (${pct(male)}%)'),
                Text('Female: $female (${pct(female)}%)'),
                if (other > 0) Text('Other:  $other (${pct(other)}%)'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAgeGroupCard() {
    return StreamBuilder<population_service.PopulationStats>(
      stream: _populationService.watchPopulationStats(),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData) {
          return _buildPlaceholderCard('Age Group Distribution');
        }
        final stats = snapshot.data!;
        final groups = stats.ageGroups;
        return Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Age Group Distribution',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...['0-5', '6-12', '13-19', '20-59', '60+'].map((g) {
                  final v = groups[g] ?? 0;
                  return Text('$g years: $v');
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPopulationTrendCard() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _populationService.streamPopulationTrend(months: 6),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildPlaceholderCard(
              'Population Trend (new residents per month)');
        }
        final points = snapshot.data!;
        return Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Population Trend (new residents per month)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...points.map((p) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(p['label'].toString()),
                          Text(p['value'].toString()),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResidentsByPurokCard() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _populationService.streamCountsByPurok(),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildPlaceholderCard('Residents by Purok (click to filter)');
        }
        final items = snapshot.data!;
        return Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Residents by Purok (click to filter)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...items.map((m) {
                  final purok = m['purok'].toString();
                  final count = m['count'] as int? ?? 0;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _residentPurokFilter = purok;
                        _tabController.animateTo(1);
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(purok),
                          Text(count.toString()),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthlySummaryCard() {
    return StreamBuilder<Map<String, int>>(
      stream: _populationService.streamMonthlyChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData) {
          return _buildPlaceholderCard('This Month');
        }
        final data = snapshot.data!;
        final newRes = data['new'] ?? 0;
        final moved = data['moved'] ?? 0;
        final deceased = data['deceased'] ?? 0;
        return Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This Month',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('New Residents: $newRes'),
                Text('Moved Out: $moved'),
                Text('Deceased: $deceased'),
              ],
            ),
          ),
        );
      },
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

  Widget _buildPlaceholderCard(String title) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No data yet.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // RESIDENTS TAB
  Widget _buildResidentsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search residents by name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _residentSearchQuery = value.trim();
              });
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFilterChip(
                  _residentPurokFilter.isEmpty
                      ? 'Purok'
                      : 'Purok: $_residentPurokFilter',
                  onTap: _selectResidentPurok,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDropdownFilter(
                  'Status',
                  ['All', 'Active', 'Inactive'],
                  value: _residentStatusFilter,
                  onSelected: (v) {
                    setState(() {
                      _residentStatusFilter = v;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDropdownFilter(
                  'Age Group',
                  ['All', '0-5', '6-12', '13-18', '19+'],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDropdownFilter(
                  'Category',
                  ['All', 'PWD', 'Senior', 'Pregnant'],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _populationService.streamResidents(
                query: _residentSearchQuery,
                purok:
                    _residentPurokFilter.isEmpty ? null : _residentPurokFilter,
                status: _residentStatusFilter == 'All'
                    ? null
                    : _residentStatusFilter,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final residents = snapshot.data ?? [];
                if (residents.isEmpty) {
                  return const Center(child: Text('No residents'));
                }
                return ListView.builder(
                  itemCount: residents.length,
                  itemBuilder: (context, index) {
                    final r = residents[index];
                    return ListTile(
                      title: Text(r['fullName']?.toString() ?? ''),
                      subtitle: Text(
                          '${r['purok'] ?? 'No purok'} • ${r['status'] ?? ''}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showResidentDetails(r),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, {VoidCallback? onTap}) {
    return Container(
      height: 48,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: InkWell(
        onTap: onTap,
        child: Text(label),
      ),
    );
  }

  Widget _buildDropdownFilter(
    String label,
    List<String> items, {
    String? value,
    ValueChanged<String>? onSelected,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: InkWell(
        onTap: onSelected == null
            ? null
            : () async {
                final selected = await showDialog<String>(
                  context: context,
                  builder: (ctx) => SimpleDialog(
                    title: Text(label),
                    children: items
                        .map(
                          (e) => SimpleDialogOption(
                            onPressed: () => Navigator.pop(ctx, e),
                            child: Text(e),
                          ),
                        )
                        .toList(),
                  ),
                );
                if (selected != null) {
                  onSelected(selected);
                }
              },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(value ?? label),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  // HOUSEHOLDS TAB
  Widget _buildHouseholdsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildFilterChip(
                  _householdPurokFilter.isEmpty
                      ? 'Filter purok'
                      : 'Purok: $_householdPurokFilter',
                  onTap: _selectHouseholdPurok,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: _openAddHousehold,
                  icon: const Icon(Icons.home),
                  label: const Text('Add Household'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _populationService.streamHouseholds(
                purok: _householdPurokFilter.isEmpty
                    ? null
                    : _householdPurokFilter,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final households = snapshot.data ?? [];
                if (households.isEmpty) {
                  return const Center(child: Text('No households'));
                }
                return ListView.builder(
                  itemCount: households.length,
                  itemBuilder: (context, index) {
                    final h = households[index];
                    return ListTile(
                      title: Text(h['address']?.toString() ?? ''),
                      subtitle: Text(
                          'Purok: ${h['purok'] ?? 'N/A'} • Members: ${h['members'] ?? 0}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // FAB
  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _openAddResident,
      child: const Icon(Icons.add),
    );
  }

  Future<void> _openAddResident() async {
    final formKey = GlobalKey<FormState>();
    final firstNameCtrl = TextEditingController();
    final lastNameCtrl = TextEditingController();
    final purokCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    String sex = 'Male';
    DateTime? birthDate;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Resident'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: firstNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'First name *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: lastNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Last name *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: sex,
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (v) {
                    if (v != null) sex = v;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Sex',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Birth date *',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  controller: TextEditingController(
                    text: birthDate == null
                        ? ''
                        : '${birthDate!.year}-${birthDate!.month.toString().padLeft(2, '0')}-${birthDate!.day.toString().padLeft(2, '0')}',
                  ),
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: birthDate ?? DateTime(now.year - 20),
                      firstDate: DateTime(1900),
                      lastDate: now,
                    );
                    if (picked != null) {
                      birthDate = picked;
                      // Rebuild dialog
                      (ctx as Element).markNeedsBuild();
                    }
                  },
                  validator: (_) =>
                      birthDate == null ? 'Please select birth date' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: purokCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Purok',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: contactCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Contact number',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) return;

              final firstName = firstNameCtrl.text.trim();
              final lastName = lastNameCtrl.text.trim();
              final fullName = '$firstName $lastName'.trim();

              try {
                await _populationService.saveResident(
                  population_service.Resident(
                    id: '',
                    firstName: firstName,
                    lastName: lastName,
                    fullName: fullName,
                    sex: sex,
                    birthDate: birthDate!,
                    purok: purokCtrl.text.trim().isEmpty
                        ? null
                        : purokCtrl.text.trim(),
                    contact: contactCtrl.text.trim().isEmpty
                        ? null
                        : contactCtrl.text.trim(),
                    category: null,
                    status: 'Active',
                  ),
                );
                if (!context.mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Resident added')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error adding resident: $e'),
                  ),
                );
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddHousehold() async {
    final nameController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Household'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Household name / ID',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              final address = nameController.text.trim();
              if (address.isNotEmpty) {
                _populationService.addHousehold(
                  address: address,
                  purok: _householdPurokFilter.isEmpty
                      ? null
                      : _householdPurokFilter,
                );
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectResidentPurok() async {
    final controller = TextEditingController(text: _residentPurokFilter);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filter by Purok'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Purok',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('APPLY'),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() {
        _residentPurokFilter = result;
      });
    }
  }

  Future<void> _selectHouseholdPurok() async {
    final controller = TextEditingController(text: _householdPurokFilter);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filter households by Purok'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Purok',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('APPLY'),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() {
        _householdPurokFilter = result;
      });
    }
  }

  void _showResidentDetails(Map<String, dynamic> r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        r['fullName']?.toString() ?? 'Resident Details',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _detailRow('Status', r['status']),
                _detailRow('Sex', r['sex']),
                _detailRow('Purok', r['purok']),
                _detailRow('Address', r['address']),
                _detailRow('Category', r['category']),
                _detailRow('Household ID', r['householdId']),
                _detailRow('Contact', r['contact']),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, dynamic value) {
    final text = (value ?? '').toString();
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }
}
