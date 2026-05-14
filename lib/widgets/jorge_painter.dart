import 'package:flutter/material.dart';

/// JorgePainter — CustomPainter que desenha o personagem Jorge.

class JorgePainter extends CustomPainter {
  const JorgePainter();

  static const Color _skin      = Color(0xFFD4956A);
  static const Color _pants     = Color(0xFF3D2B1A);
  static const Color _boots     = Color(0xFF1A0F05);
  static const Color _body      = Color(0xFF6B3A1F); 
  static const Color _belt      = Color(0xFF2A1505);
  static const Color _buckle    = Color(0xFFBF8A30); 
  static const Color _hat       = Color(0xFF4A2800);
  static const Color _hatRibbon = Color(0xFFBF8A30);
  static const Color _eye       = Color(0xFF1A0A00);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w / 2, h * 0.95), width: w * 0.6, height: h * 0.06),
      Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    final pantsPaint = Paint()..color = _pants;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.30, h * 0.62, w * 0.16, h * 0.32),
          const Radius.circular(4)),
      pantsPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.54, h * 0.62, w * 0.16, h * 0.32),
          const Radius.circular(4)),
      pantsPaint,
    );

    final bootPaint = Paint()..color = _boots;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.27, h * 0.88, w * 0.20, h * 0.08),
          const Radius.circular(3)),
      bootPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.53, h * 0.88, w * 0.20, h * 0.08),
          const Radius.circular(3)),
      bootPaint,
    );

    final bodyPaint = Paint()..color = _body;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.22, h * 0.34, w * 0.56, h * 0.30),
          const Radius.circular(6)),
      bodyPaint,
    );

    canvas.drawRect(
        Rect.fromLTWH(w * 0.22, h * 0.60, w * 0.56, h * 0.04),
        Paint()..color = _belt);
    canvas.drawRect(
        Rect.fromLTWH(w * 0.45, h * 0.595, w * 0.10, h * 0.05),
        Paint()..color = _buckle);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.06, h * 0.34, w * 0.18, h * 0.26),
          const Radius.circular(5)),
      bodyPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.76, h * 0.34, w * 0.18, h * 0.26),
          const Radius.circular(5)),
      bodyPaint,
    );

    final skinPaint = Paint()..color = _skin;
    canvas.drawRect(
        Rect.fromLTWH(w * 0.42, h * 0.22, w * 0.16, h * 0.14), skinPaint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.28, h * 0.06, w * 0.44, h * 0.22),
          const Radius.circular(8)),
      skinPaint,
    );

    final eyePaint = Paint()..color = _eye;
    canvas.drawOval(
        Rect.fromLTWH(w * 0.36, h * 0.11, w * 0.08, h * 0.05), eyePaint);
    canvas.drawOval(
        Rect.fromLTWH(w * 0.56, h * 0.11, w * 0.08, h * 0.05), eyePaint);

    final hatPaint = Paint()..color = _hat;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.16, h * 0.065, w * 0.68, h * 0.06),
          const Radius.circular(3)),
      hatPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.30, h * -0.01, w * 0.40, h * 0.09),
          const Radius.circular(4)),
      hatPaint,
    );
  
    canvas.drawRect(
        Rect.fromLTWH(w * 0.30, h * 0.065, w * 0.40, h * 0.015),
        Paint()..color = _hatRibbon);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}