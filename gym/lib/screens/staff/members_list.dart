import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/user.dart';
import '../../config/constants.dart';
import '../../components/member_card.dart';
import '../../config/theme_constants.dart';

class StaffMembersList extends StatefulWidget {
  const StaffMembersList({super.key});

  @override
  State<StaffMembersList> createState() => _StaffMembersListState();
}

class _StaffMembersListState extends State<StaffMembersList> {
  final ApiService _apiService = ApiService();
  List<User> _allMembers = [];
  List<User> _filteredMembers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterStatus = 'All';

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    try {
      final response = await _apiService.get('/management/members');
      final List data = response.data['data'];
      setState(() {
        _allMembers = data.map((json) => User.fromJson(json)).toList();
        _filteredMembers = _allMembers;
        _isLoading = false;
      });
      _filterMembers(); // Re-filter after fetch
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterMembers() {
    setState(() {
      _filteredMembers = _allMembers.where((member) {
        final matchesSearch =
            member.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            member.email.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesStatus =
            _filterStatus == 'All' ||
            (member.membershipStatus?.toLowerCase() ==
                _filterStatus.toLowerCase());
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  Future<void> _toggleStatus(User member) async {
    try {
      await _apiService.post('/management/members/${member.id}/toggle');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated for ${member.name}')),
        );
        _fetchMembers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status')),
        );
      }
    }
  }

  bool _isGridView = false;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Search & Filter Header
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search members...',
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                      ),
                      style: const TextStyle(color: AppColors.textPrimary),
                      onChanged: (val) {
                        _searchQuery = val;
                        _filterMembers();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Grid/List Toggle
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isGridView ? Icons.view_list : Icons.grid_view,
                        color: AppColors.primary,
                      ),
                      onPressed: () =>
                          setState(() => _isGridView = !_isGridView),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Filter Dropdown (Styled)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _filterStatus,
                    isExpanded: true,
                    dropdownColor: AppColors.surface,
                    icon: const Icon(
                      Icons.filter_list,
                      color: AppColors.textSecondary,
                    ),
                    style: const TextStyle(color: AppColors.textPrimary),
                    items: ['All', 'Active', 'Inactive']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _filterStatus = val;
                          _filterMembers();
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchMembers,
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            child: _isGridView
                ? GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: _filteredMembers.length,
                    itemBuilder: (context, index) {
                      return MemberCard(
                        member: _filteredMembers[index],
                        onToggleStatus: () =>
                            _toggleStatus(_filteredMembers[index]),
                        onEdit: () => _editMember(_filteredMembers[index]),
                        onDelete: () => _deleteMember(_filteredMembers[index]),
                        isGridView: true,
                      );
                    },
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _filteredMembers.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: MemberCard(
                          member: _filteredMembers[index],
                          onToggleStatus: () =>
                              _toggleStatus(_filteredMembers[index]),
                          onEdit: () => _editMember(_filteredMembers[index]),
                          onDelete: () =>
                              _deleteMember(_filteredMembers[index]),
                          isGridView: false,
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  void _editMember(User member) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit functionality coming soon!')),
    );
  }

  Future<void> _deleteMember(User member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Member',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete ${member.name}? This action cannot be undone.',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _apiService.deleteMember(member.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${member.name} deleted successfully')),
          );
          _fetchMembers();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete member (Admin only)'),
            ),
          );
        }
      }
    }
  }
}
