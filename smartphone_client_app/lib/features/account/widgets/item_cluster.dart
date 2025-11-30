import 'package:flutter/material.dart';

class ItemCluster extends StatelessWidget {
  final String? title;
  final List<ClusterItem> children;

  const ItemCluster({super.key, this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final List<Widget> clusterWidgets = [];

    if (title != null && title!.isNotEmpty) {
      clusterWidgets.add(ClusterTitle(title: title!));
    }

    clusterWidgets.add(
      Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Column(
            children: children.asMap().entries.expand((entry) {
              int index = entry.key;
              ClusterItem clusterItem = entry.value;

              // Determine border radius based on position
              BorderRadius itemBorderRadius;
              if (children.length == 1) {
                itemBorderRadius = BorderRadius.circular(10);
              } else if (index == 0) {
                itemBorderRadius = const BorderRadius.vertical(
                  top: Radius.circular(10),
                );
              } else if (index == children.length - 1) {
                itemBorderRadius = const BorderRadius.vertical(
                  bottom: Radius.circular(10),
                );
              } else {
                itemBorderRadius = BorderRadius.zero;
              }

              // Create child with correct border radius
              final childWithRadius = ClusterItem(
                icon: clusterItem.icon,
                title: clusterItem.title,
                subtitle: clusterItem.subtitle,
                onTap: clusterItem.onTap,
                trailing: clusterItem.trailing,
                borderRadius: itemBorderRadius,
              );

              // Add divider between items (not after last item)
              if (index > 0) {
                return [
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                  childWithRadius,
                ];
              }
              return [childWithRadius];
            }).toList(),
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: clusterWidgets,
    );
  }
}

class ClusterTitle extends StatelessWidget {
  final String title;

  const ClusterTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 16, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class ClusterItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final BorderRadius? borderRadius;

  const ClusterItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: ListTile(
          leading: Icon(icon, color: colorScheme.onSurface),
          title: Text(title),
          subtitle: subtitle,
          trailing:
              trailing ??
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 0,
          ),
        ),
      ),
    );
  }
}
