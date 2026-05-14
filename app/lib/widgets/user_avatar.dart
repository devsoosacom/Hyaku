import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.photoUrl,
    required this.displayName,
    this.radius = 16,
    this.fontSize = 13,
  });

  final String? photoUrl;
  final String displayName;
  final double radius;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      final provider = _imageProvider(photoUrl!);
      if (provider != null) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: const Color(0xFF2A2A2A),
          backgroundImage: provider,
          onBackgroundImageError: (_, __) {},
        );
      }
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF2A2A2A),
      child: Text(
        displayName.isNotEmpty ? displayName[0] : '?',
        style: GoogleFonts.notoSerifJp(
          fontSize: fontSize,
          color: const Color(0xFFCC0000),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  ImageProvider? _imageProvider(String url) {
    try {
      if (url.startsWith('data:')) {
        final base64Str = url.split(',').last;
        final bytes = base64Decode(base64Str);
        return MemoryImage(Uint8List.fromList(bytes));
      }
      return NetworkImage(url);
    } catch (_) {
      return null;
    }
  }
}
