import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/population_service.dart' as population_service;

class ResidentDetailScreen extends StatelessWidget {
  final population_service.Resident resident;
  final population_service.PopulationService _svc;

  ResidentDetailScreen({super.key, required this.resident})
      : _svc = population_service.PopulationService();

  @override
  Widget build(BuildContext context) {
    // Handle resident data
    final id = resident.id;
    final fullName =
        resident.fullName.isNotEmpty ? resident.fullName : 'Unnamed Resident';
    final sex = resident.sex.isNotEmpty ? resident.sex : 'Not specified';
    final purok =
        resident.purok?.isNotEmpty == true ? resident.purok : 'Not specified';
    final addr = resident.address?.isNotEmpty == true
        ? resident.address
        : 'Not specified';
    final status = resident.status.isNotEmpty ? resident.status : 'Active';
    final contact = resident.contact?.isNotEmpty == true
        ? resident.contact
        : 'Not specified';
    final category = resident.category?.isNotEmpty == true
        ? resident.category
        : 'Not specified';
    final civilStatus = resident.civilStatus?.isNotEmpty == true
        ? resident.civilStatus
        : 'Not specified';

    // Calculate age
    final age = (DateTime.now().difference(resident.birthDate).inDays ~/ 365)
        .toString();

    // Format date of birth
    final dobStr = DateFormat('MMMM d, y').format(resident.birthDate.toLocal());

    return Scaffold(
      appBar: AppBar(title: const Text('Resident Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(
                              fullName.isNotEmpty
                                  ? fullName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 32,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            fullName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 32),
                    _infoRow('Age', age),
                    _infoRow('Sex', sex),
                    _infoRow('Date of Birth', dobStr),
                    _infoRow('Civil Status', civilStatus),
                    _infoRow('Contact Number', contact),
                    _infoRow('Category', category),
                    const SizedBox(height: 8),
                    const Text(
                      'Address Information',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _infoRow('Purok', purok ?? 'Not specified'),
                    _infoRow('Full Address', addr ?? 'Not specified',
                        isMultiline: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 24),
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildActionButton(
                  context: context,
                  icon: Icons.edit,
                  label: 'Edit',
                  color: Colors.blue,
                  onPressed: () {
                    // TODO: Implement edit functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Edit functionality coming soon')),
                    );
                  },
                ),
                _buildStatusButton(
                  context: context,
                  status: 'Active',
                  icon: Icons.check_circle_outline,
                  label: 'Active',
                  color: Colors.green,
                ),
                _buildStatusButton(
                  context: context,
                  status: 'Moved out',
                  icon: Icons.logout,
                  label: 'Moved Out',
                  color: Colors.orange,
                ),
                _buildStatusButton(
                  context: context,
                  status: 'Deceased',
                  icon: Icons.close,
                  label: 'Deceased',
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text(
                  'Movement History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    // TODO: Implement view all history
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('View all history coming soon')),
                    );
                  },
                  icon: const Text('View All'),
                  label: const Icon(Icons.arrow_forward_ios, size: 14),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _svc.streamMovementsForResident(id),
              builder: (context, snap) {
                final items = snap.data ?? const [];
                if (items.isEmpty) {
                  return const Card(child: ListTile(title: Text('No history')));
                }
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 1,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.take(5).length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (_, i) {
                      final m = items[i];
                      final status = (m['status'] ?? '').toString();
                      final ts = m['at'];
                      String when = '';
                      String timeAgo = '';

                      if (ts is Timestamp) {
                        final date = ts.toDate();
                        when = DateFormat('MMM d, y hh:mm a').format(date);
                        final difference = DateTime.now().difference(date);

                        if (difference.inDays > 0) {
                          timeAgo =
                              '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
                        } else if (difference.inHours > 0) {
                          timeAgo =
                              '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
                        } else if (difference.inMinutes > 0) {
                          timeAgo =
                              '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
                        } else {
                          timeAgo = 'Just now';
                        }
                      }

                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                _getStatusColor(status).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getStatusIcon(status),
                            color: _getStatusColor(status),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          status,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(timeAgo),
                        trailing: Text(
                          when,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: color,
        backgroundColor: color.withValues(alpha: 0.1),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withValues(alpha: 0.5), width: 1),
        ),
      ),
    );
  }

  Widget _buildStatusButton({
    required BuildContext context,
    required String status,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final bool isCurrentStatus =
        resident.status.toLowerCase() == status.toLowerCase();

    return _buildActionButton(
      context: context,
      icon: icon,
      label: isCurrentStatus ? 'Current: $label' : label,
      color: isCurrentStatus ? Colors.grey : color,
      onPressed: isCurrentStatus
          ? () {}
          : () => _showStatusConfirmationDialog(context, status, label, color),
    );
  }

  Future<void> _showStatusConfirmationDialog(
    BuildContext context,
    String status,
    String statusLabel,
    Color statusColor,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Status Change'),
        content: Text(
            'Are you sure you want to mark this resident as "$statusLabel"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: statusColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (confirmed == true) {
      await _updateStatus(context, status, statusLabel);
    }
  }

  Future<void> _updateStatus(
    BuildContext context,
    String status,
    String statusLabel,
  ) async {
    if (resident.id.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Invalid resident ID'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      await _svc.updateResidentStatus(resident.id, status);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to $statusLabel'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error updating status: $e');
      debugPrint('Stack trace: $stackTrace');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to update status. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _updateStatus(context, status, statusLabel),
            ),
          ),
        );
      }
    }
  }

  Widget _infoRow(String label, dynamic value, {bool isMultiline = false}) {
    final displayValue = (value?.toString().trim() ?? 'Not specified').isEmpty
        ? '—'
        : (value?.toString() ?? 'Not specified');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment:
            isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(':', style: TextStyle(color: Colors.black54)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              displayValue,
              style: const TextStyle(fontSize: 15),
              maxLines: isMultiline ? 3 : 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'moved out':
        return Colors.orange;
      case 'deceased':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Icons.check_circle_outline;
      case 'moved out':
        return Icons.logout;
      case 'deceased':
        return Icons.close;
      default:
        return Icons.info_outline;
    }
  }
}
