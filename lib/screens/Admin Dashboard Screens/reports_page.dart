import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  bool _isLoading = false;
  bool _isGeneratingPdf = false;
  List<Map<String, dynamic>> _tickets = [];
  final Map<String, int> _statusCounts = {};
  final Map<String, int> _priorityCounts = {};

  // Filter variables
  String _selectedStatus = 'All';
  String _selectedPriority = 'All';

  final List<String> _statuses = ['All', 'pending', 'completed', 'in progress'];
  final List<String> _priorities = ['All', 'low', 'medium', 'high'];

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      // Build query with filters
      var query = supabase.from('tickets').select('*');

      if (_selectedStatus != 'All') {
        query = query.eq('status', _selectedStatus);
      }

      if (_selectedPriority != 'All') {
        query = query.eq('priority', _selectedPriority);
      }

      final response = await query.order('created_at', ascending: false);
      _tickets = List<Map<String, dynamic>>.from(response);

      _calculateStats();
    } catch (e) {
      _showSnackBar('Error loading data: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _calculateStats() {
    _statusCounts.clear();
    _priorityCounts.clear();

    for (final ticket in _tickets) {
      final status = ticket['status']?.toString() ?? 'pending';
      final priority = ticket['priority']?.toString() ?? 'medium';

      _statusCounts[status] = (_statusCounts[status] ?? 0) + 1;
      _priorityCounts[priority] = (_priorityCounts[priority] ?? 0) + 1;
    }
  }

  Future<void> _generatePdfReport() async {
    setState(() => _isGeneratingPdf = true);

    try {
      final pdf = pw.Document();
      final now = DateTime.now();

      // Add page to PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'IT Ticket System Report',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Generated on ${_formatDate(now)}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  pw.Container(
                    width: 60,
                    height: 60,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue100,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        '📊',
                        style: const pw.TextStyle(fontSize: 30),
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 24),

              // Summary Cards
              pw.Row(
                children: [
                  pw.Expanded(
                    child: _buildPdfCard(
                      'Total Tickets',
                      '${_tickets.length}',
                      PdfColors.blue,
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    child: _buildPdfCard(
                      'Completed',
                      '${_statusCounts['completed'] ?? 0}',
                      PdfColors.green,
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    child: _buildPdfCard(
                      'Pending',
                      '${_statusCounts['pending'] ?? 0}',
                      PdfColors.orange,
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    child: _buildPdfCard(
                      'In Progress',
                      '${_statusCounts['in progress'] ?? 0}',
                      PdfColors.purple,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 32),

              // Status Distribution
              pw.Text(
                'Status Distribution',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              _buildPdfTable(
                ['Status', 'Count', 'Percentage'],
                _statusCounts.entries
                    .map((e) => [
                          e.key.toUpperCase(),
                          e.value.toString(),
                          '${(e.value / _tickets.length * 100).toStringAsFixed(1)}%',
                        ])
                    .toList()
                    .cast<List<String>>(),
              ),

              pw.SizedBox(height: 24),

              // Priority Distribution
              pw.Text(
                'Priority Distribution',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              _buildPdfTable(
                ['Priority', 'Count', 'Percentage'],
                _priorityCounts.entries
                    .map((e) => [
                          e.key.toUpperCase(),
                          e.value.toString(),
                          '${(e.value / _tickets.length * 100).toStringAsFixed(1)}%',
                        ])
                    .toList()
                    .cast<List<String>>(),
              ),

              pw.SizedBox(height: 32),

              // Recent Tickets
              pw.Text(
                'Recent Tickets (Last 10)',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              _buildPdfTable(
                ['ID', 'Title', 'Status', 'Priority', 'Created'],
                _tickets
                    .take(10)
                    .map((ticket) => [
                          '#${ticket['id']?.toString().substring(0, 8) ?? 'N/A'}',
                          (ticket['title']?.toString() ?? 'No Title').length >
                                  30
                              ? '${ticket['title']?.toString().substring(0, 30)}...'
                              : ticket['title']?.toString() ?? 'No Title',
                          (ticket['status']?.toString() ?? 'pending')
                              .toUpperCase(),
                          (ticket['priority']?.toString() ?? 'medium')
                              .toUpperCase(),
                          _formatDate(DateTime.parse(ticket['created_at'])),
                        ])
                    .toList()
                    .cast<List<String>>(),
              ),
            ];
          },
        ),
      );

      // Show print dialog
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'IT_Ticket_Report_${now.year}_${now.month}_${now.day}.pdf',
      );
    } catch (e) {
      _showSnackBar('Error generating PDF: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isGeneratingPdf = false);
    }
  }

  pw.Widget _buildPdfCard(String title, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 2),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfTable(List<String> headers, List<List<String>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: headers
              .map((header) => pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      header,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ))
              .toList(),
        ),
        // Data rows
        ...rows.map((row) => pw.TableRow(
              children: row
                  .map((cell) => pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(cell),
                      ))
                  .toList(),
            )),
      ],
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      key: const ValueKey('reports'),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.analytics_outlined,
                color: Color(0xFF667EEA),
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Reports & Analytics',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const Spacer(),
              if (!isMobile) ...[
                ElevatedButton.icon(
                  onPressed: _isGeneratingPdf ? null : _generatePdfReport,
                  icon: _isGeneratingPdf
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.picture_as_pdf),
                  label: const Text('Export PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667EEA),
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              IconButton(
                onPressed: _loadReportData,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh Data',
              ),
            ],
          ),

          if (isMobile) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGeneratingPdf ? null : _generatePdfReport,
                icon: _isGeneratingPdf
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf),
                label: const Text('Export PDF Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667EEA),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Filters
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: _statuses
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status == 'All'
                                ? status
                                : status.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedStatus = value!);
                    _loadReportData();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: _priorities
                      .map((priority) => DropdownMenuItem(
                            value: priority,
                            child: Text(priority == 'All'
                                ? priority
                                : priority.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedPriority = value!);
                    _loadReportData();
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Summary Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            'Total Tickets',
                            '${_tickets.length}',
                            Icons.confirmation_number,
                            const Color(0xFF667EEA),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSummaryCard(
                            'Completed',
                            '${_statusCounts['completed'] ?? 0}',
                            Icons.check_circle,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSummaryCard(
                            'Pending',
                            '${_statusCounts['pending'] ?? 0}',
                            Icons.pending,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Status Distribution
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Status Distribution',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ..._statusCounts.entries.map(
                              (entry) => _buildProgressBar(
                                entry.key.toUpperCase(),
                                entry.value,
                                _tickets.length,
                                _getStatusColor(entry.key),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Priority Distribution
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Priority Distribution',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ..._priorityCounts.entries.map(
                              (entry) => _buildProgressBar(
                                entry.key.toUpperCase(),
                                entry.value,
                                _tickets.length,
                                _getPriorityColor(entry.key),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Recent Tickets
                    Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'Recent Tickets',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (_tickets.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(40),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.inbox_outlined,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No tickets found',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount:
                                  _tickets.length > 10 ? 10 : _tickets.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final ticket = _tickets[index];

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: _getPriorityColor(
                                            ticket['priority'] ?? 'medium')
                                        .withOpacity(0.1),
                                    child: Icon(
                                      Icons.confirmation_number,
                                      color: _getPriorityColor(
                                          ticket['priority'] ?? 'medium'),
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    ticket['title'] ?? 'No Title',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(
                                                  ticket['status'] ?? 'pending')
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          (ticket['status'] ?? 'pending')
                                              .toString()
                                              .toUpperCase(),
                                          style: TextStyle(
                                            color: _getStatusColor(
                                                ticket['status'] ?? 'pending'),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getPriorityColor(
                                                  ticket['priority'] ??
                                                      'medium')
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          (ticket['priority'] ?? 'medium')
                                              .toString()
                                              .toUpperCase(),
                                          style: TextStyle(
                                            color: _getPriorityColor(
                                                ticket['priority'] ?? 'medium'),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Text(
                                    _formatDate(
                                        DateTime.parse(ticket['created_at'])),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(String label, int value, int total, Color color) {
    final percentage = total > 0 ? (value / total) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$value (${(percentage * 100).toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ],
      ),
    );
  }
}
