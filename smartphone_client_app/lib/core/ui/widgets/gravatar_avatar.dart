import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

/// A reusable widget that displays a user's Gravatar profile picture
/// from their email address, with fallback to identicon
class GravatarAvatar extends StatelessWidget {
  final String email;
  final double radius;
  final Color? backgroundColor;

  const GravatarAvatar({
    super.key,
    required this.email,
    this.radius = 30,
    this.backgroundColor,
  });

  /// Generates Gravatar URL from email address
  /// Uses MD5 hash of normalized email
  String _getGravatarUrl(String email, {int size = 200}) {
    try {
      final normalized = email.trim().toLowerCase();
      final hash = md5.convert(utf8.encode(normalized));
      return 'https://www.gravatar.com/avatar/$hash?s=$size&d=identicon';
    } catch (e) {
      // Fallback to default avatar if email processing fails
      return 'https://www.gravatar.com/avatar/00000000000000000000000000000000?s=$size&d=identicon';
    }
  }

  @override
  Widget build(BuildContext context) {
    final gravatarUrl = _getGravatarUrl(email, size: (radius * 2 * 2).toInt());
    final bgColor = backgroundColor ??
        Theme.of(context).colorScheme.surfaceContainerHigh;

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: gravatarUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: (context, url) => Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          errorWidget: (context, url, error) => Icon(
            Icons.person,
            size: radius,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
