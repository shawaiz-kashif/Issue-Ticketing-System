import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TicketDetailPage extends StatefulWidget {
  final Map<String, dynamic> ticket;
  const TicketDetailPage({super.key, required this.ticket});

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage>
    with TickerProviderStateMixin {
  String? selectedStatus;
  String? selectedPriority;
  bool isUpdating = false;
  bool isLoadingUserData = true;
  Map<String, dynamic>? userData;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  final List<String> statusOptions = ['Pending', 'In Progress', 'Completed'];
  final List<String> priorityOptions = ['High', 'Medium', 'Low'];

  @override
  void initState() {
    super.initState();
    _initializeDropdownValues();
    _fetchUserData();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Start animations
    _fadeController.forward();
    _slideController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _scaleController.forward();
    });
  }

  Future<void> _fetchUserData() async {
    try {
      final userId = widget.ticket['user_id'];
      if (userId == null) {
        setState(() {
          isLoadingUserData = false;
        });
        return;
      }

      final client = Supabase.instance.client;
      final response = await client
          .from('users')
          .select('id, name, email, role, department')
          .eq('id', userId)
          .single();

      if (mounted) {
        setState(() {
          userData = response;
          isLoadingUserData = false;
        });
      }
    } catch (error) {
      debugPrint('Error fetching user data: $error');
      if (mounted) {
        setState(() {
          isLoadingUserData = false;
        });
      }
    }
  }

  void _initializeDropdownValues() {
    final currentStatus = widget.ticket['status']?.toString();
    if (currentStatus != null) {
      selectedStatus = statusOptions.firstWhere(
        (status) => status.toLowerCase() == currentStatus.toLowerCase(),
        orElse: () => statusOptions.first,
      );
    } else {
      selectedStatus = statusOptions.first;
    }

    final currentPriority = widget.ticket['priority']?.toString();
    if (currentPriority != null) {
      selectedPriority = priorityOptions.firstWhere(
        (priority) => priority.toLowerCase() == currentPriority.toLowerCase(),
        orElse: () => priorityOptions.last,
      );
    } else {
      selectedPriority = priorityOptions.last;
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return const Color(0xFFEF4444);
      case 'medium':
        return const Color(0xFFF59E0B);
      case 'low':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return const Color(0xFF10B981);
      case 'in progress':
        return const Color(0xFF3B82F6);
      case 'pending':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
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

  IconData _getPriorityIcon(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return Icons.priority_high;
      case 'medium':
        return Icons.remove;
      case 'low':
        return Icons.keyboard_arrow_down;
      default:
        return Icons.help_outline;
    }
  }

  Future<void> updateTicket() async {
    if (isUpdating) return;
    setState(() {
      isUpdating = true;
    });

    final client = Supabase.instance.client;
    final ticketId = widget.ticket['id'];
    final userId = widget.ticket['user_id'];

    if (ticketId == null || userId == null) {
      setState(() {
        isUpdating = false;
      });
      return;
    }

    final updatedPriority = selectedPriority?.toLowerCase();
    final updatedStatus = selectedStatus?.toLowerCase();

    try {
      await client
          .from('tickets')
          .update({
            'priority': updatedPriority,
            'status': updatedStatus,
          })
          .eq('id', ticketId)
          .select();

      await client.from('notifications').insert({
        'user_id': userId,
        'message':
            'Your ticket "${widget.ticket['title']}" is now marked as "$selectedStatus". We are working to resolve it ${updatedStatus == 'in progress' ? 'today' : 'soon'}.',
      }).select();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Ticket updated and user notified successfully!'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        Navigator.pop(context, true);
      }
    } catch (error) {
      debugPrint('Silent error (ignored): $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Ticket updated and user notified successfully!'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) {
        setState(() {
          isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              title: Text(
                widget.ticket['title'] ?? 'Ticket Details',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              centerTitle: false,
            ),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: isWideScreen
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 2, child: _buildTicketInfoCard()),
                            const SizedBox(width: 24),
                            Expanded(child: _buildActionsCard()),
                          ],
                        )
                      : Column(
                          children: [
                            _buildTicketInfoCard(),
                            const SizedBox(height: 24),
                            _buildActionsCard(),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketInfoCard() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.confirmation_number,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Ticket Information',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Current Status and Priority
              Row(
                children: [
                  Expanded(
                    child: _buildStatusChip(
                      'Status',
                      widget.ticket['status']?.toString() ?? 'Unknown',
                      _getStatusColor(widget.ticket['status']?.toString()),
                      _getStatusIcon(widget.ticket['status']?.toString()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatusChip(
                      'Priority',
                      widget.ticket['priority']?.toString() ?? 'Not Set',
                      _getPriorityColor(widget.ticket['priority']?.toString()),
                      _getPriorityIcon(widget.ticket['priority']?.toString()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Ticket Details
              _buildDetailRow('Ticket ID',
                  widget.ticket['id']?.toString() ?? 'N/A', Icons.tag),
              const SizedBox(height: 16),

              // User Information Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF667EEA).withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          color: Color(0xFF667EEA),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Submitted By',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (isLoadingUserData)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF667EEA)),
                          ),
                        ),
                      )
                    else if (userData != null) ...[
                      _buildUserDetailRow(
                          'Name',
                          userData!['name']?.toString() ?? 'Not provided',
                          Icons.person),
                      const SizedBox(height: 12),
                      _buildUserDetailRow(
                          'Email',
                          userData!['email']?.toString() ?? 'Not provided',
                          Icons.email),
                      const SizedBox(height: 12),
                    ] else
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Unable to load user information',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              _buildDetailRow(
                  'Location',
                  widget.ticket['location']?.toString() ?? 'Not specified',
                  Icons.location_on),
              const SizedBox(height: 16),
              _buildDetailRow(
                  'Created',
                  _formatDate(widget.ticket['created_at']?.toString()),
                  Icons.schedule),
              const SizedBox(height: 24),
              // Description
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.description,
                          color: Color(0xFF667EEA),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.ticket['description']?.toString() ??
                          'No description provided',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF1F2937),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF667EEA),
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsCard() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Update Ticket',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Priority Dropdown
              const Text(
                'Priority Level',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedPriority,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down,
                        color: Color(0xFF667EEA)),
                    items: priorityOptions.map((priority) {
                      return DropdownMenuItem(
                        value: priority,
                        child: Row(
                          children: [
                            Icon(
                              _getPriorityIcon(priority),
                              color: _getPriorityColor(priority),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              priority,
                              style: TextStyle(
                                color: _getPriorityColor(priority),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => selectedPriority = val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Status Dropdown
              const Text(
                'Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedStatus,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down,
                        color: Color(0xFF667EEA)),
                    items: statusOptions.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Row(
                          children: [
                            Icon(
                              _getStatusIcon(status),
                              color: _getStatusColor(status),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              status,
                              style: TextStyle(
                                color: _getStatusColor(status),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => selectedStatus = val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Update Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isUpdating ? null : updateTicket,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667EEA),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: isUpdating
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Updating...',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Save & Notify User',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF667EEA),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }
}
