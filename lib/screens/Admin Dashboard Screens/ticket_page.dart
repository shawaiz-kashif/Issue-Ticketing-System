import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ticket_gen/screens/Admin%20Dashboard%20Screens/ticket_detail_page.dart';

extension StringCasingExtension on String {
  String capitalize() {
    if (isEmpty) return '';
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}

class TicketPage extends StatefulWidget {
  const TicketPage({super.key});

  @override
  State<TicketPage> createState() => _TicketPageState();
}

class _TicketPageState extends State<TicketPage> {
  bool _readyToStream = false;

  @override
  void initState() {
    super.initState();

    // Add a short delay to ensure Supabase and network are ready
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _readyToStream = true;
      });
    });
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in progress':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'in progress':
        return Icons.hourglass_empty;
      case 'pending':
        return Icons.pending;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.confirmation_number_outlined,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Support Tickets',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    Text('Manage and track all support requests',
                        style: TextStyle(fontSize: 14, color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _readyToStream
                  ? StreamBuilder<List<Map<String, dynamic>>>(
                      stream: supabase
                          .from('tickets')
                          .stream(primaryKey: ['id']).order('created_at',
                              ascending: false),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        }

                        final tickets = snapshot.data;
                        if (tickets == null || tickets.isEmpty) {
                          return const Center(
                              child: Text('No tickets available.'));
                        }

                        return ListView.builder(
                          itemCount: tickets.length,
                          cacheExtent: 1000,
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            final ticket = tickets[index];
                            final isRead = ticket['is_read'] ?? false;

                            return GestureDetector(
                              onTap: () async {
                                if (!isRead) {
                                  await supabase.from('tickets').update(
                                      {'is_read': true}).eq('id', ticket['id']);
                                }
                                if (!context.mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        TicketDetailPage(ticket: ticket),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildTicketCard(context, ticket),
                              ),
                            );
                          },
                        );
                      },
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context, Map<String, dynamic> ticket) {
    final rawPriority = (ticket['priority'] ?? '').toString().trim();
    final priority = rawPriority.capitalize();
    final status = ticket['status'] ?? 'Pending';
    final isRead = ticket['is_read'] ?? false;

    return Container(
      decoration: BoxDecoration(
        color: isRead ? Colors.white : const Color(0xFFDCEFFF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ticket['title'] ?? 'No title',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getStatusIcon(status),
                              size: 14, color: _getStatusColor(status)),
                          const SizedBox(width: 4),
                          Text(
                            status,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(status),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        priority,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              ticket['description'] ?? 'No description provided',
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF4B5563), height: 1.5),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
