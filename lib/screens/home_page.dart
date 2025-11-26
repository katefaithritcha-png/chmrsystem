import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/customer_provider.dart';
import '../core/responsive/responsive_helper.dart';
import '../core/responsive/responsive_text.dart';
import '../shared/widgets/responsive_grid.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomerProvider>();
    final responsivePadding = ResponsiveHelper.getResponsivePadding(context);
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: const ResponsiveHeading2('Customers'),
        elevation: 0,
      ),
      body: Padding(
        padding: responsivePadding,
        child: Builder(builder: (context) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(
              child: ResponsiveBody('Error: ${provider.error}'),
            );
          }
          if (provider.customers.isEmpty) {
            return const Center(child: ResponsiveBody('No customers found.'));
          }

          if (isMobile) {
            return ListView.separated(
              itemCount: provider.customers.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final c = provider.customers[index];
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: ResponsiveBody(c.fullName),
                  subtitle: ResponsiveCaption(c.address),
                );
              },
            );
          }

          // Grid layout for tablet and desktop
          return ResponsiveGrid(
            mobileColumns: 1,
            tabletColumns: 2,
            desktopColumns: 3,
            children: provider.customers.map((c) {
              return Card(
                child: Padding(
                  padding: responsivePadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ResponsiveHeading3(c.fullName),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ResponsiveBody(c.address),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        }),
      ),
    );
  }
}

class ResponsiveCaption extends StatelessWidget {
  final String text;
  final Color? color;

  const ResponsiveCaption(
    this.text, {
    Key? key,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveText(
      text,
      mobileSize: 12,
      tabletSize: 13,
      desktopSize: 14,
      color: color,
    );
  }
}
