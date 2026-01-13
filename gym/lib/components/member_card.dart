import 'package:flutter/material.dart';
import '../models/user.dart';
import '../config/constants.dart';
import '../config/theme_constants.dart';

class MemberCard extends StatelessWidget {
  final User member;
  final VoidCallback onToggleStatus;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isGridView;

  const MemberCard({
    super.key,
    required this.member,
    required this.onToggleStatus,
    required this.onEdit,
    required this.onDelete,
    this.isGridView = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showMemberDetails(context),
      child: isGridView ? _buildGridLayout(context) : _buildListLayout(context),
    );
  }

  void _showMemberDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75, // 75% height
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 300,
                    automaticallyImplyLeading: false,
                    backgroundColor: AppColors.background,
                    flexibleSpace: FlexibleSpaceBar(
                      background: _buildFullBleedImage(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  member.name,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              _buildStatusBadge(),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            member.email,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            "Membership Details",
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const Divider(
                            color: AppColors.surfaceVariant,
                            height: 24,
                          ),
                          _buildDetailRow(
                            Icons.fitness_center,
                            "Package",
                            member.package?.name ?? "N/A",
                          ),
                          if (member.package?.price != null)
                            _buildDetailRow(
                              Icons.attach_money,
                              "Price",
                              "\$${member.package!.price}",
                            ),
                          if (member.membershipStatus == 'active') ...[
                            _buildDetailRow(
                              Icons.calendar_today,
                              "Status",
                              "Active Member",
                            ),
                          ],
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                onToggleStatus();
                              },
                              icon: Icon(
                                member.membershipStatus == 'active'
                                    ? Icons.block
                                    : Icons.check_circle,
                                color: member.membershipStatus == 'active'
                                    ? AppColors.error
                                    : AppColors.background,
                              ),
                              label: Text(
                                member.membershipStatus == 'active'
                                    ? "Deactivate Membership"
                                    : "Activate Membership",
                                style: TextStyle(
                                  color: member.membershipStatus == 'active'
                                      ? AppColors.error
                                      : AppColors.background,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    member.membershipStatus == 'active'
                                    ? AppColors.surfaceVariant
                                    : AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullBleedImage() {
    final hasImage =
        member.profilePicture != null && member.profilePicture!.isNotEmpty;
    if (hasImage) {
      return Image.network(
        member.profilePicture!.startsWith('http')
            ? member.profilePicture!
            : '${AppConstants.serverUrl}${member.profilePicture!}',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppColors.primary,
          child: Center(
            child: Text(
              member.name[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
      );
    } else {
      return Container(
        color: AppColors.primary,
        child: Center(
          child: Text(
            member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridLayout(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAvatar(radius: 30),
                const SizedBox(height: 12),
                Text(
                  member.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  member.email,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                _buildStatusBadge(),
              ],
            ),
          ),
          Positioned(top: 4, right: 4, child: _buildMenuButton()),
        ],
      ),
    );
  }

  Widget _buildListLayout(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildAvatar(radius: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  member.email,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          _buildStatusBadge(),
          const SizedBox(width: 8),
          _buildMenuButton(),
        ],
      ),
    );
  }

  Widget _buildAvatar({required double radius}) {
    final hasImage =
        member.profilePicture != null && member.profilePicture!.isNotEmpty;
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withOpacity(0.1),
      backgroundImage: hasImage
          ? NetworkImage(
              member.profilePicture!.startsWith('http')
                  ? member.profilePicture!
                  : '${AppConstants.serverUrl}${member.profilePicture!}',
            )
          : null,
      child: !hasImage
          ? Text(
              member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.8,
              ),
            )
          : null,
    );
  }

  Widget _buildStatusBadge() {
    final isActive = member.membershipStatus?.toLowerCase() == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? Colors.green : Colors.grey,
          width: 1,
        ),
      ),
      child: Text(
        member.membershipStatus?.toUpperCase() ?? 'NONE',
        style: TextStyle(
          color: isActive ? Colors.green : Colors.grey,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMenuButton({bool overlay = false}) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: overlay ? Colors.black.withOpacity(0.6) : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        icon: Icon(
          Icons.more_horiz,
          color: overlay ? Colors.white : AppColors.textSecondary,
          size: 20,
        ),
        color: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (val) {
          if (val == 'toggle') onToggleStatus();
          if (val == 'edit') onEdit();
          if (val == 'delete') onDelete();
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: const [
                Icon(Icons.edit, size: 18, color: AppColors.textPrimary),
                SizedBox(width: 8),
                Text('Edit'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'toggle',
            child: Row(
              children: [
                Icon(
                  member.membershipStatus == 'active'
                      ? Icons.block
                      : Icons.check_circle,
                  size: 18,
                  color: AppColors.textPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  member.membershipStatus == 'active'
                      ? 'Deactivate'
                      : 'Activate',
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: const [
                Icon(Icons.delete, size: 18, color: Colors.redAccent),
                SizedBox(width: 8),
                Text('Delete', style: TextStyle(color: Colors.redAccent)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
