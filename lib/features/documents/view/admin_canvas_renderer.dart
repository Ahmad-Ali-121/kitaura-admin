// lib/features/documents/view/admin_canvas_renderer.dart
//
// Step 23+ — Read-only canvas renderer for the Document Inspector.
//
// Takes a raw items[] array (as stored in Firestore) and renders the
// document visually at native A4 dimensions (595 × 842 per page),
// scaled down to fit the admin viewport.
//
// Best-effort visual fidelity (~85%): shapes, positioning, rotation,
// flips, borders, and basic Quill text formatting render correctly.
// Custom fonts, advanced Quill features (lists, headers), and image
// content fall back to sensible defaults.

import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class AdminCanvasRenderer extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final String? canvasBackground;

  const AdminCanvasRenderer({
    super.key,
    required this.items,
    this.canvasBackground,
  });

  static const double canvasWidth = 595;
  static const double pageHeight = 842;

  Color get _bgColor =>
      _parseColor(canvasBackground) ?? const Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.lavenderBlush,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.almondSilk),
        ),
        child: const Center(
          child: Text(
            'No items on this canvas.',
            style: TextStyle(color: AppColors.slateGrey, fontSize: 13),
          ),
        ),
      );
    }

    // Compute total canvas height (multi-page support)
    double maxY = 0;
    for (final it in items) {
      final y = _num(it['y']);
      final h = _num(it['h']);
      if (y + h > maxY) maxY = y + h;
    }
    final pageCount = max(1, (maxY / pageHeight).ceil());
    final totalHeight = pageCount * pageHeight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        // Cap scale at 1.0 — never upscale beyond native A4 size
        final scale =
        (available < canvasWidth) ? available / canvasWidth : 1.0;
        final scaledW = canvasWidth * scale;
        final scaledH = totalHeight * scale;

        return Center(
          child: SizedBox(
            width: scaledW,
            height: scaledH,
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: canvasWidth,
                height: totalHeight,
                child: _buildCanvas(pageCount),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCanvas(int pageCount) {
    return Container(
      color: _bgColor,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Page break indicators
          for (int i = 1; i < pageCount; i++)
            Positioned(
              left: 0,
              right: 0,
              top: i * pageHeight,
              child: const _PageBreakLine(),
            ),
          // Items in declared order (front-to-back rendered in array order)
          for (final item in items) _PositionedItem(data: item),
        ],
      ),
    );
  }
}

// ─── ITEM POSITIONING ────────────────────────────────────────────────────

class _PositionedItem extends StatelessWidget {
  final Map<String, dynamic> data;
  const _PositionedItem({required this.data});

  @override
  Widget build(BuildContext context) {
    final x = _num(data['x']);
    final y = _num(data['y']);
    final w = _num(data['w']);
    final h = _num(data['h']);
    final rotation = _num(data['rotation']);
    final flipX = data['flipX'] == true;
    final flipY = data['flipY'] == true;

    Widget child = _ItemContent(data: data, w: w, h: h);

    // Flip
    if (flipX || flipY) {
      child = Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..scaleByDouble(flipX ? -1.0 : 1.0, flipY ? -1.0 : 1.0, 1.0, 1.0),
        child: child,
      );
    }

    // Rotation (degrees → radians)
    if (rotation != 0) {
      child = Transform.rotate(
        angle: rotation * pi / 180,
        child: child,
      );
    }

    return Positioned(
      left: x,
      top: y,
      width: w,
      height: h,
      child: child,
    );
  }
}

// ─── ITEM CONTENT (per-type rendering) ───────────────────────────────────

class _ItemContent extends StatelessWidget {
  final Map<String, dynamic> data;
  final double w;
  final double h;
  const _ItemContent({
    required this.data,
    required this.w,
    required this.h,
  });

  @override
  Widget build(BuildContext context) {
    final type = (data['type'] ?? '').toString();
    final color = _parseColor(data['color']);
    final borderColor = _parseColor(data['borderColor']);
    final borderWidth = _num(data['borderWidth']);

    switch (type) {
      case 'textSection':
        return _TextItem(
          delta: data['delta'],
          color: color,
          borderColor: borderColor,
          borderWidth: borderWidth,
        );
      case 'tableSection':
        return _TableItem(
          tableData: data['tableData'],
          borderColor: borderColor,
          borderWidth: borderWidth,
        );
      case 'rectangle':
        return _RectItem(
          color: color,
          borderColor: borderColor,
          borderWidth: borderWidth,
        );
      case 'line':
        return _RectItem(
          color: color ?? const Color(0xFF000000),
          borderColor: null,
          borderWidth: 0,
        );
      case 'circle':
        return _CircleItem(
          color: color,
          borderColor: borderColor,
          borderWidth: borderWidth,
        );
      case 'triangle':
      case 'star':
      case 'arrow':
      case 'diamond':
      case 'hexagon':
      case 'skewedRectangle':
        return CustomPaint(
          painter: _ShapePainter(
            type: type,
            color: color ?? const Color(0xFF000000),
            borderColor: borderColor,
            borderWidth: borderWidth,
          ),
        );
      case 'imageBox':
        return _PlaceholderItem(
          color: color ?? AppColors.almondSilk,
          icon: Icons.image_outlined,
          label: 'Image',
          borderColor: borderColor,
          borderWidth: borderWidth,
        );
      case 'icon':
        return _PlaceholderItem(
          color: color ?? AppColors.slateGrey,
          icon: Icons.star_outline,
          label: 'Icon',
          borderColor: null,
          borderWidth: 0,
        );
      default:
        return _PlaceholderItem(
          color: AppColors.almondSilk.withValues(alpha: 0.4),
          icon: Icons.help_outline,
          label: type.isEmpty ? '?' : type,
          borderColor: AppColors.almondSilk,
          borderWidth: 1,
        );
    }
  }
}

// ─── BASIC SHAPES ────────────────────────────────────────────────────────

class _RectItem extends StatelessWidget {
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  const _RectItem({
    required this.color,
    required this.borderColor,
    required this.borderWidth,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        border: (borderColor != null && borderWidth > 0)
            ? Border.all(color: borderColor!, width: borderWidth)
            : null,
      ),
    );
  }
}

class _CircleItem extends StatelessWidget {
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  const _CircleItem({
    required this.color,
    required this.borderColor,
    required this.borderWidth,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: (borderColor != null && borderWidth > 0)
            ? Border.all(color: borderColor!, width: borderWidth)
            : null,
      ),
    );
  }
}

class _PlaceholderItem extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final Color? borderColor;
  final double borderWidth;

  const _PlaceholderItem({
    required this.color,
    required this.icon,
    required this.label,
    required this.borderColor,
    required this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        border: (borderColor != null && borderWidth > 0)
            ? Border.all(color: borderColor!, width: borderWidth)
            : Border.all(
          color: AppColors.almondSilk.withValues(alpha: 0.6),
          width: 0.5,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color.withValues(alpha: 0.7)),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontFamily: 'Poppins',
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── COMPLEX SHAPES (custom paths) ───────────────────────────────────────

class _ShapePainter extends CustomPainter {
  final String type;
  final Color color;
  final Color? borderColor;
  final double borderWidth;

  _ShapePainter({
    required this.type,
    required this.color,
    required this.borderColor,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildPath(size);

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );

    if (borderColor != null && borderWidth > 0) {
      canvas.drawPath(
        path,
        Paint()
          ..color = borderColor!
          ..strokeWidth = borderWidth
          ..style = PaintingStyle.stroke,
      );
    }
  }

  Path _buildPath(Size size) {
    switch (type) {
      case 'triangle':
        return Path()
          ..moveTo(size.width / 2, 0)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
      case 'diamond':
        return Path()
          ..moveTo(size.width / 2, 0)
          ..lineTo(size.width, size.height / 2)
          ..lineTo(size.width / 2, size.height)
          ..lineTo(0, size.height / 2)
          ..close();
      case 'star':
        return _starPath(size);
      case 'hexagon':
        return _hexagonPath(size);
      case 'arrow':
        return _arrowPath(size);
      case 'skewedRectangle':
        return _skewedPath(size);
      default:
        return Path()..addRect(Offset.zero & size);
    }
  }

  Path _starPath(Size size) {
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outer = min(size.width, size.height) / 2;
    final inner = outer * 0.4;
    for (int i = 0; i < 10; i++) {
      final angle = -pi / 2 + i * pi / 5;
      final r = i.isEven ? outer : inner;
      final x = cx + cos(angle) * r;
      final y = cy + sin(angle) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  Path _hexagonPath(Size size) {
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rX = size.width / 2;
    final rY = size.height / 2;
    for (int i = 0; i < 6; i++) {
      final angle = i * pi / 3;
      final x = cx + cos(angle) * rX;
      final y = cy + sin(angle) * rY;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  Path _arrowPath(Size size) {
    final w = size.width;
    final h = size.height;
    final shaftTop = h * 0.3;
    final shaftBottom = h * 0.7;
    final headStart = w * 0.6;
    return Path()
      ..moveTo(0, shaftTop)
      ..lineTo(headStart, shaftTop)
      ..lineTo(headStart, 0)
      ..lineTo(w, h / 2)
      ..lineTo(headStart, h)
      ..lineTo(headStart, shaftBottom)
      ..lineTo(0, shaftBottom)
      ..close();
  }

  Path _skewedPath(Size size) {
    final skew = size.width * 0.15;
    return Path()
      ..moveTo(skew, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width - skew, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldRepaint(_ShapePainter old) =>
      old.type != type ||
          old.color != color ||
          old.borderColor != borderColor ||
          old.borderWidth != borderWidth;
}

// ─── TEXT (Quill delta) ──────────────────────────────────────────────────

class _TextItem extends StatelessWidget {
  final dynamic delta;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;

  const _TextItem({
    required this.delta,
    required this.color,
    required this.borderColor,
    required this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color,
        border: (borderColor != null && borderWidth > 0)
            ? Border.all(color: borderColor!, width: borderWidth)
            : null,
      ),
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minHeight: 0,
          maxHeight: double.infinity,
          child: _DeltaRenderer(delta: delta),
        ),
      ),
    );
  }
}

class _DeltaRenderer extends StatelessWidget {
  final dynamic delta;
  const _DeltaRenderer({required this.delta});

  @override
  Widget build(BuildContext context) {
    if (delta is! List) {
      return const Text(
        '(empty)',
        style: TextStyle(
          fontSize: 10,
          color: AppColors.slateGrey,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final lines = _splitIntoLines(delta as List);
    if (lines.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: lines.map((line) {
        if (line.spans.isEmpty) {
          return const SizedBox(height: 4);
        }
        final align = line.blockAttrs['align'] as String?;
        final textAlign = _parseAlign(align);
        return Padding(
          padding: const EdgeInsets.only(bottom: 1),
          child: RichText(
            textAlign: textAlign,
            text: TextSpan(
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.prussianBlue,
                fontFamily: 'OpenSans',
                height: 1.3,
              ),
              children: line.spans
                  .map((s) => TextSpan(
                text: s.text,
                style: _buildStyle(s.attrs),
              ))
                  .toList(),
            ),
          ),
        );
      }).toList(),
    );
  }

  List<_Line> _splitIntoLines(List delta) {
    final lines = <_Line>[];
    var current = _Line();
    for (final raw in delta) {
      if (raw is! Map) continue;
      final insert = raw['insert'];
      final attrs = raw['attributes'] is Map
          ? Map<String, dynamic>.from(raw['attributes'])
          : <String, dynamic>{};
      if (insert is! String) continue;
      if (insert == '\n') {
        // Block attrs ride on the newline op
        current.blockAttrs = attrs;
        lines.add(current);
        current = _Line();
      } else if (insert.isNotEmpty) {
        current.spans.add(_Span(insert, attrs));
      }
    }
    if (current.spans.isNotEmpty) lines.add(current);
    return lines;
  }

  TextAlign _parseAlign(String? a) {
    switch (a) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      case 'justify':
        return TextAlign.justify;
      default:
        return TextAlign.left;
    }
  }

  TextStyle _buildStyle(Map<String, dynamic> attrs) {
    return TextStyle(
      fontWeight: attrs['bold'] == true ? FontWeight.bold : null,
      fontStyle: attrs['italic'] == true ? FontStyle.italic : null,
      decoration: attrs['underline'] == true ? TextDecoration.underline : null,
      color: _parseColor(attrs['color']),
      fontSize: _parseFontSize(attrs['size']),
      fontFamily: attrs['font'] as String?,
    );
  }
}

class _Line {
  final List<_Span> spans = [];
  Map<String, dynamic> blockAttrs = {};
}

class _Span {
  final String text;
  final Map<String, dynamic> attrs;
  _Span(this.text, this.attrs);
}

// ─── TABLE ───────────────────────────────────────────────────────────────

class _TableItem extends StatelessWidget {
  final dynamic tableData;
  final Color? borderColor;
  final double borderWidth;

  const _TableItem({
    required this.tableData,
    required this.borderColor,
    required this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    if (tableData is! Map) return const SizedBox.shrink();
    final td = Map<String, dynamic>.from(tableData);

    final headers = (td['headers'] is List)
        ? (td['headers'] as List).map((e) => e.toString()).toList()
        : <String>[];
    final rows = (td['rows'] is List)
        ? (td['rows'] as List)
        .whereType<List>()
        .map((r) => r.map((c) => c.toString()).toList())
        .toList()
        : <List<String>>[];
    final showHeader = td['showHeader'] != false;
    final headerBg = _parseColor(td['headerBgColor']) ??
        AppColors.prussianBlue;
    final headerTextColor =
        _parseColor(td['headerTextColor']) ?? AppColors.white;
    final cellTextColor =
        _parseColor(td['cellTextColor']) ?? AppColors.prussianBlue;
    final tableBorderColor = _parseColor(td['borderColor']) ??
        borderColor ??
        AppColors.almondSilk;
    final fontSize = _num(td['fontSize']);
    final effectiveFontSize = fontSize > 0 ? fontSize : 10.0;

    return DefaultTextStyle(
      style: TextStyle(
        fontSize: effectiveFontSize,
        color: cellTextColor,
        fontFamily: 'OpenSans',
      ),
      child: Table(
        border: TableBorder.all(color: tableBorderColor, width: 0.5),
        children: [
          if (showHeader && headers.isNotEmpty)
            TableRow(
              decoration: BoxDecoration(color: headerBg),
              children: headers
                  .map((h) => Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  h,
                  style: TextStyle(
                    color: headerTextColor,
                    fontWeight: FontWeight.w700,
                    fontSize: effectiveFontSize,
                  ),
                ),
              ))
                  .toList(),
            ),
          for (final row in rows)
            TableRow(
              children: row
                  .map((cell) => Padding(
                padding: const EdgeInsets.all(4),
                child: Text(cell),
              ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

// ─── PAGE BREAK ──────────────────────────────────────────────────────────

class _PageBreakLine extends StatelessWidget {
  const _PageBreakLine();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: CustomPaint(painter: _DashedLinePainter()),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.magentaBloom.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    const dash = 6.0;
    const gap = 4.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + dash, 0),
        paint,
      );
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => false;
}

// ─── PARSERS ─────────────────────────────────────────────────────────────

double _num(dynamic v) => v is num ? v.toDouble() : 0.0;

Color? _parseColor(dynamic raw) {
  if (raw is! String) return null;
  var h = raw.replaceFirst('#', '');
  if (h.length == 6) h = 'FF$h';
  if (h.length != 8) return null;
  final v = int.tryParse(h, radix: 16);
  return v == null ? null : Color(v);
}

double? _parseFontSize(dynamic raw) {
  if (raw is num) return raw.toDouble();
  if (raw is String) {
    final v = double.tryParse(raw);
    if (v != null) return v;
    // Quill sometimes uses named sizes like 'small'/'large'
    switch (raw) {
      case 'small':
        return 9;
      case 'large':
        return 16;
      case 'huge':
        return 22;
    }
  }
  return null;
}