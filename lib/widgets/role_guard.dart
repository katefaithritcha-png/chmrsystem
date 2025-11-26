import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class RoleGuard extends StatelessWidget {
  final List<String> allowedRoles; // e.g., ['admin'] or ['worker','health_worker']
  final Widget child;
  const RoleGuard({super.key, required this.allowedRoles, required this.child});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().role;

    if (role == null) {
      // Not logged in; send to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ModalRoute.of(context)?.isCurrent ?? false) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      });
      return const SizedBox.shrink();
    }

    // Accept both 'worker' and 'health_worker' if either is specified
    final normalized = role;
    final effectiveAllowed = {
      for (final r in allowedRoles) r == 'worker' ? 'health_worker' : r,
      for (final r in allowedRoles) r
    };

    if (!effectiveAllowed.contains(normalized) && !(normalized == 'worker' && effectiveAllowed.contains('health_worker'))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ScaffoldMessenger.maybeOf(context) != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You are not authorized to access this page.')),
          );
        }
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      });
      return const SizedBox.shrink();
    }

    return child;
  }
}
