import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ticket_gen/widgets/statcard.dart';
import 'package:ticket_gen/widgets/tickets_bar_chart.dart';

class GeneralPage extends StatelessWidget {
  const GeneralPage({super.key});

  Future<Map<String, int>> fetchTicketStats() async {
    final supabase = Supabase.instance.client;
    final response = await supabase.from('tickets').select('status');

    final data = response;
    final stats = {
      'total': data.length,
      'pending': 0,
      'in_progress': 0,
      'completed': 0,
    };

    for (var item in data) {
      final status = item['status'];
      if (status == 'pending') {
        stats['pending'] = stats['pending']! + 1;
      } else if (status == 'in progress') {
        stats['in_progress'] = stats['in_progress']! + 1;
      } else if (status == 'completed') {
        stats['completed'] = stats['completed']! + 1;
      }
    }

    return stats;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: fetchTicketStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error loading stats: ${snapshot.error}'));
        }

        final stats = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  int crossAxisCount;
                  double childAspectRatio;
                  double spacing;

                  if (screenWidth < 500) {
                    // Very small screens - single column
                    crossAxisCount = 1;
                    childAspectRatio = 3.0; // Wide cards
                    spacing = 12;
                  } else if (screenWidth < 700) {
                    // Small screens - 2 columns
                    crossAxisCount = 2;
                    childAspectRatio = 2.0; // Rectangular cards
                    spacing = 14;
                  } else if (screenWidth < 1000) {
                    // Medium screens - 2 columns with better ratio
                    crossAxisCount = 2;
                    childAspectRatio = 2.2;
                    spacing = 16;
                  } else {
                    // Large screens - 4 columns
                    crossAxisCount = 4;
                    childAspectRatio = 1.8; // Slightly taller
                    spacing = 16;
                  }

                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    childAspectRatio:
                        childAspectRatio, // 👈 Better aspect ratios
                    children: [
                      StatCard(
                        title: 'Total Tickets',
                        value: stats['total'].toString(),
                        icon: Icons.confirmation_number,
                        color: Colors.blue,
                      ),
                      StatCard(
                        title: 'Pending',
                        value: stats['pending'].toString(),
                        icon: Icons.pending,
                        color: Colors.orange,
                      ),
                      StatCard(
                        title: 'In Progress',
                        value: stats['in_progress'].toString(),
                        icon: Icons.hourglass_empty,
                        color: Colors.purple,
                      ),
                      StatCard(
                        title: 'Completed',
                        value: stats['completed'].toString(),
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
              const SizedBox(
                height: 300,
                child: TicketsBarChart(),
              ),
            ],
          ),
        );
      },
    );
  }
}
