import 'package:flutter/material.dart';

class SignalStrengthIndicator extends StatelessWidget {
  final int rssi;

  const SignalStrengthIndicator({
    super.key,
    required this.rssi,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColorForQuality(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _getIconForQuality(),
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          '$rssi dBm',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontSize: 12,
              ),
        ),
      ],
    );
  }

  int _getSignalQuality() {
    if (rssi >= -50) return 3; // Excellent
    if (rssi >= -70) return 2; // Good
    if (rssi >= -85) return 1; // Weak
    return 0; // Poor
  }

  IconData _getIconForQuality() {
    final quality = _getSignalQuality();
    switch (quality) {
      case 3:
        return Icons.signal_cellular_alt;
      case 2:
        return Icons.signal_cellular_alt_2_bar;
      case 1:
        return Icons.signal_cellular_alt_1_bar;
      default:
        return Icons.signal_cellular_0_bar;
    }
  }

  Color _getColorForQuality(BuildContext context) {
    final quality = _getSignalQuality();
    switch (quality) {
      case 3:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 1:
        return Colors.orange.shade700;
      default:
        return Colors.red;
    }
  }
}
