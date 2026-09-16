import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';

/// Dashed dropzone. Tapping opens the file picker; while uploading the
/// dashes fill with the progress bar so the same element shows state.
class Dropzone extends StatelessWidget {
  const Dropzone({super.key, required this.onTap, this.progress, this.uploading = false});
  final VoidCallback? onTap;
  final double? progress;
  final bool uploading;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return Semantics(
      button: true,
      label: 'Upload your resume, PDF or DOCX up to 10 MB',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: uploading ? null : onTap,
          borderRadius: JmRadius.lgR,
          child: CustomPaint(
            foregroundPainter: _DashedBorder(color: uploading ? c.ocean : c.lineStrong, radius: JmRadius.lg),
            child: AnimatedContainer(
              duration: JmMotion.state,
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
              decoration: BoxDecoration(
                color: uploading ? c.skyTint.withValues(alpha: .5) : c.card,
                borderRadius: JmRadius.lgR,
              ),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: c.skyTint, borderRadius: BorderRadius.circular(12)),
                    child: Icon(
                      uploading ? Icons.cloud_upload_rounded : Icons.upload_file_rounded,
                      color: c.skyDeep,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    uploading ? 'Uploading your resume' : 'Tap to choose your resume',
                    style: context.type.heading.copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    uploading ? '${((progress ?? 0) * 100).round()}%' : 'PDF or DOCX, up to 10 MB',
                    style: context.type.meta.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                  if (uploading) ...[
                    const SizedBox(height: 18),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(value: progress, minHeight: 6),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  _DashedBorder({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()..addRRect(RRect.fromRectAndRadius((Offset.zero & size).deflate(1), Radius.circular(radius)));
    const dash = 7.0, gap = 5.0;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color || old.radius != radius;
}
