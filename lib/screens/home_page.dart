import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/customer_provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomerProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Builder(builder: (context) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(
              child: Text('Error: ${provider.error}'),
            );
          }
          if (provider.customers.isEmpty) {
            return const Center(child: Text('No customers found.'));
          }
          return ListView.separated(
            itemCount: provider.customers.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final c = provider.customers[index];
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(c.fullName),
                subtitle: Text(c.address),
              );
            },
          );
        }),
      ),
    );
  }
}
