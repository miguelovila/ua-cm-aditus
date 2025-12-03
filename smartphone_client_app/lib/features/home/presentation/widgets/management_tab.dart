import 'package:flutter/material.dart';

class ManagementTab extends StatelessWidget {
  const ManagementTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Admin Management',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage users, groups, doors, and access control',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Management Options
        _ManagementCard(
          icon: Icons.groups,
          title: 'Group Management',
          description: 'Create and manage user groups',
          color: Colors.blue,
          onTap: () {
            Navigator.pushNamed(context, '/admin/groups');
          },
        ),
        const SizedBox(height: 12),
        _ManagementCard(
          icon: Icons.people,
          title: 'User Management',
          description: 'Manage user accounts and permissions',
          color: Colors.green,
          onTap: () {
            Navigator.pushNamed(context, '/admin/users');
          },
        ),
        const SizedBox(height: 12),
        _ManagementCard(
          icon: Icons.door_front_door,
          title: 'Door Management',
          description: 'Configure doors and locations',
          color: Colors.orange,
          onTap: () {
            Navigator.pushNamed(context, '/admin/doors');
          },
        ),
        const SizedBox(height: 12),
        _ManagementCard(
          icon: Icons.history,
          title: 'System Logs',
          description: 'View access logs and activity',
          color: Colors.teal,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('System Logs - Coming soon')),
            );
          },
        ),
      ],
    );
  }
}

class _ManagementCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _ManagementCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
