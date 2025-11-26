// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../models/common_models.dart';

class UserDetailScreen extends StatelessWidget {
  final AppUser user;
  const UserDetailScreen({super.key, required this.user});

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.indigo;
      case 'worker':
        return Colors.teal;
      case 'patient':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Details'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor:
                              _roleColor(user.role).withValues(alpha: .12),
                          child: Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: _roleColor(user.role),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color:
                                          _roleColor(user.role).withValues(alpha: .1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.verified_user,
                                            size: 16,
                                            color: _roleColor(user.role)),
                                        const SizedBox(width: 6),
                                        Text(
                                          user.role.toUpperCase(),
                                          style: TextStyle(
                                            color: _roleColor(user.role),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.email_outlined,
                                          size: 16, color: Colors.black54),
                                      const SizedBox(width: 6),
                                      Text(user.email,
                                          style: const TextStyle(
                                              color: Colors.black87)),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Back'),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Edit coming soon')),
                                );
                              },
                              icon: const Icon(Icons.edit),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: const StadiumBorder(),
                              ),
                              label: const Text('Edit'),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Info + Activity layout
                  Flex(
                    direction: isMobile ? Axis.vertical : Axis.horizontal,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          margin: EdgeInsets.only(
                              right: isMobile ? 0 : 12,
                              bottom: isMobile ? 12 : 0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Profile Information',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 12),
                              _InfoRow(
                                  icon: Icons.badge_outlined,
                                  label: 'Full Name'),
                              _InfoRow(
                                  icon: Icons.alternate_email,
                                  label: 'Email Address'),
                              _InfoRow(icon: Icons.work_outline, label: 'Role'),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Recent Activity',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              ...List.generate(
                                  6, (i) => _ActivityRow(index: i + 1)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF5F7FB),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final int index;
  const _ActivityRow({required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 10, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(child: Text('Activity item #$index')),
          Text(
              '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}'),
        ],
      ),
    );
  }
}
