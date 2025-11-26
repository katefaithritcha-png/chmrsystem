import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../models/common_models.dart';
import 'user_detail_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _service = UserService();
  late Future<List<AppUser>> _future;
  final TextEditingController _searchCtrl = TextEditingController();
  String _roleFilter = 'all';

  @override
  void initState() {
    super.initState();
    _future = _service.fetchUsers();
  }

  void _refresh() {
    setState(() {
      _future = _service.fetchUsers();
    });
  }

  Future<void> _showEditDialog(AppUser user) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _UserFormSheet(
          title: 'Edit User',
          initialName: user.name,
          initialEmail: user.email,
          initialRole: user.role,
          submitLabel: 'Save',
          onSubmit: (name, role, email) async {
            await _service.updateUser(user.id,
                name: name, role: role, email: email);
          },
        ),
      ),
    );
    if (ok == true) _refresh();
  }

  Future<void> _confirmDelete(AppUser user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.name}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await _service.deleteUser(user.id);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      // No add button; users are created via registration/login
      body: FutureBuilder<List<AppUser>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return const Center(child: Text('Failed to load users'));
          }
          final users = snap.data ?? const <AppUser>[];
          if (users.isEmpty) {
            return const Center(child: Text('No users found'));
          }
          // Apply simple client-side filtering
          final q = _searchCtrl.text.toLowerCase();
          final filtered = users.where((u) {
            final roleOk = _roleFilter == 'all' || u.role == _roleFilter;
            final qOk = q.isEmpty ||
                u.name.toLowerCase().contains(q) ||
                u.email.toLowerCase().contains(q) ||
                u.id.toLowerCase().contains(q);
            return roleOk && qOk;
          }).toList();

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Search & Filters
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Search box
                            Expanded(
                              child: TextField(
                                controller: _searchCtrl,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: 'Search by name, email, or ID',
                                  prefixIcon: const Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Role filter
                            SizedBox(
                              width: 180,
                              child: DropdownButtonFormField<String>(
                                initialValue: _roleFilter,
                                items: const [
                                  DropdownMenuItem(
                                      value: 'all', child: Text('All roles')),
                                  DropdownMenuItem(
                                      value: 'admin', child: Text('Admin')),
                                  DropdownMenuItem(
                                      value: 'health_worker',
                                      child: Text('Health Worker')),
                                  DropdownMenuItem(
                                      value: 'patient', child: Text('Patient')),
                                ],
                                onChanged: (v) =>
                                    setState(() => _roleFilter = v ?? 'all'),
                                decoration:
                                    const InputDecoration(labelText: 'Role'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Users list
                    Expanded(
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final u = filtered[index];
                            return ListTile(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          UserDetailScreen(user: u)),
                                );
                              },
                              leading: CircleAvatar(
                                  child: Text(
                                      u.name.isNotEmpty ? u.name[0] : '?')),
                              title: Text(u.name),
                              subtitle: Text('${u.role} • ${u.email}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _showEditDialog(u),
                                    tooltip: 'Edit',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _confirmDelete(u),
                                    tooltip: 'Delete',
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _UserFormSheet extends StatefulWidget {
  final String title;
  final String? initialName;
  final String? initialEmail;
  final String? initialRole;
  final String submitLabel;
  final Future<void> Function(String name, String role, String email) onSubmit;

  const _UserFormSheet({
    required this.title,
    required this.onSubmit,
    this.initialName,
    this.initialEmail,
    this.initialRole,
    this.submitLabel = 'Add',
  });

  @override
  State<_UserFormSheet> createState() => _UserFormSheetState();
}

class _UserFormSheetState extends State<_UserFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late String _role;
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName ?? '');
    _emailCtrl = TextEditingController(text: widget.initialEmail ?? '');
    _role = widget.initialRole ?? 'health_worker';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    await widget.onSubmit(_nameCtrl.text.trim(), _role, _emailCtrl.text.trim());
    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Name', border: OutlineInputBorder()),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                    labelText: 'Email', border: OutlineInputBorder()),
                validator: (v) {
                  final s = v?.trim() ?? '';
                  if (s.isEmpty) return 'Enter an email';
                  if (!s.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _role,
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(
                      value: 'health_worker', child: Text('Health Worker')),
                  DropdownMenuItem(value: 'patient', child: Text('Patient')),
                ],
                onChanged: (v) => setState(() => _role = v ?? _role),
                decoration: const InputDecoration(
                    labelText: 'Role', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _submitting ? null : _handleSubmit,
                    child: _submitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(widget.submitLabel),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
