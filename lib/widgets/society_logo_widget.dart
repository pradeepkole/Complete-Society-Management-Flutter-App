import 'dart:convert';
import 'package:flutter/material.dart';

class SocietyLogoWidget extends StatelessWidget {
  final String? logoUrl;
  final String fallbackText;
  final double size;
  final double borderRadius;
  final Color? backgroundColor;

  const SocietyLogoWidget({
    super.key,
    required this.logoUrl,
    required this.fallbackText,
    this.size = 38,
    this.borderRadius = 8,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (logoUrl != null && logoUrl!.trim().isNotEmpty) {
      final trimmed = logoUrl!.trim();
      
      // Base64 Data URI or raw Base64 string
      if (trimmed.startsWith('data:image') || (!trimmed.startsWith('http') && trimmed.length > 100)) {
        try {
          final cleanBase64 = trimmed.contains(',') ? trimmed.split(',').last : trimmed;
          final bytes = base64Decode(cleanBase64);
          return ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Image.memory(
              bytes,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildFallback(),
            ),
          );
        } catch (_) {
          return _buildFallback();
        }
      } else if (trimmed.startsWith('http')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Image.network(
            trimmed,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildFallback(),
          ),
        );
      }
    }
    return _buildFallback();
  }

  Widget _buildFallback() {
    final initial = fallbackText.trim().isNotEmpty
        ? fallbackText.trim().characters.first.toUpperCase()
        : 'S';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withOpacity(0.35)),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.45,
          ),
        ),
      ),
    );
  }
}
