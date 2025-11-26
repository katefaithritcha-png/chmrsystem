import 'package:flutter/material.dart';
import '../services/immunization_service.dart';

class ImmunizationScreen extends StatefulWidget {
  const ImmunizationScreen({super.key});

  @override
  State<ImmunizationScreen> createState() => _ImmunizationScreenState();
}

class _ImmunizationScreenState extends State<ImmunizationScreen> {
  String _vaxCat = 'All'; // Category filter retained for future use
  final ImmunizationService _immunization = ImmunizationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Immunization Module'),
        actions: const [],
      ),
      backgroundColor: const Color(0xFFF5F7FB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, cons) {
                final w = cons.maxWidth;
                if (w < 600) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      StreamBuilder<int>(
                        stream: _immunization.missedCount(),
                        initialData: 0,
                        builder: (ctx, snap) => _Kpi(
                          label: 'Missed / Follow-ups',
                          value: '${snap.data ?? 0}',
                          icon: Icons.vaccines,
                          color: Colors.blue,
                          onTap: () => _showMissedFollowUps(context),
                          expanded: false,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const SizedBox.shrink(),
                    ],
                  );
                }
                if (w < 1000) {
                  final tileW = (w - 12) / 2; // 2 columns with spacing
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: tileW,
                        child: StreamBuilder<int>(
                          stream: _immunization.missedCount(),
                          initialData: 0,
                          builder: (ctx, snap) => _Kpi(
                            label: 'Missed / Follow-ups',
                            value: '${snap.data ?? 0}',
                            icon: Icons.vaccines,
                            color: Colors.blue,
                            onTap: () => _showMissedFollowUps(context),
                            expanded: false,
                          ),
                        ),
                      ),
                      const SizedBox.shrink(),
                    ],
                  );
                }
                return Row(
                  children: [
                    StreamBuilder<int>(
                      stream: _immunization.missedCount(),
                      initialData: 0,
                      builder: (ctx, snap) => _Kpi(
                        label: 'Missed / Follow-ups',
                        value: '${snap.data ?? 0}',
                        icon: Icons.vaccines,
                        color: Colors.blue,
                        onTap: () => _showMissedFollowUps(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Category filters: single-line horizontal scroll
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final cat in const [
                    'All',
                    'Infant',
                    'Measles/MMR',
                    'Adult'
                  ]) ...[
                    ChoiceChip(
                      label: Text(cat),
                      selected: _vaxCat == cat,
                      showCheckmark: true,
                      onSelected: (_) => setState(() => _vaxCat = cat),
                    ),
                    const SizedBox(width: 8),
                  ]
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Due list (empty state until data source defined)
            Container(
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(16),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Due/Upcoming',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('No items available.'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Recent vaccinations (empty state until data source defined)
            Container(
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(16),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recent Vaccinations',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('No recent records.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool expanded;
  const _Kpi(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color,
      this.onTap,
      this.expanded = true});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              Text(label,
                  style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                      fontSize: 12)),
            ],
          ),
        ],
      ),
    );
    final child = onTap == null ? card : InkWell(onTap: onTap, child: card);
    return expanded ? Expanded(child: child) : child;
  }
}

void _showMissedFollowUps(BuildContext context) {
  final svc = ImmunizationService();
  showModalBottomSheet(
    context: context,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Missed / Follow-ups',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          StreamBuilder<List<Map<String, Object>>>(
            stream: svc.missedList(limit: 25),
            initialData: const [],
            builder: (c, snap) {
              final items = snap.data ?? const [];
              if (items.isEmpty) return const Text('No missed follow-ups.');
              return Column(
                children: items
                    .map((e) => ListTile(
                          leading: const Icon(Icons.warning_amber_rounded,
                              color: Colors.orange),
                          title:
                              Text('${e['patientName']} (${e['patientId']})'),
                          subtitle: Text('${e['detail']} • Due: ${e['due']}'),
                          trailing: TextButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              Navigator.pushNamed(context, '/patients');
                            },
                            icon: const Icon(Icons.schedule),
                            label: const Text('Follow-up'),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    ),
  );
}
