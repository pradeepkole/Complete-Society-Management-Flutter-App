import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class SocietyLogoWidget extends StatelessWidget {
  final String? logoUrl;
  final String fallbackText;
  final double size;
  final double borderRadius;
  final Color? backgroundColor;

  // In-memory cache for ultra-fast permanent rendering without re-decoding
  static final Map<String, Uint8List> _bytesCache = {};

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
      if (trimmed.startsWith('data:image') || (!trimmed.startsWith('http') && trimmed.length > 80)) {
        try {
          Uint8List? bytes = _bytesCache[trimmed];
          if (bytes == null) {
            final cleanBase64 = (trimmed.contains(',') ? trimmed.split(',').last : trimmed)
                .replaceAll(RegExp(r'\s+'), '');
            bytes = base64Decode(cleanBase64);
            _bytesCache[trimmed] = bytes;
          }
          return ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Image.memory(
              bytes,
              width: size,
              height: size,
              fit: BoxFit.cover,
              gaplessPlayback: true,
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
            gaplessPlayback: true,
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
