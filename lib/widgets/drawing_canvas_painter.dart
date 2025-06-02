import 'package:flutter/material.dart';
import 'dart:ui' as ui; // Alias for dart:ui, often used for Path, Canvas, Paint

/// A CustomPainter that draws a given SVG outline path onto the canvas.
///
/// This painter is designed to display a static outline. For interactive drawing
/// (like user strokes), you would typically manage a list of paths.
class DrawingCanvasPainter extends CustomPainter {
  /// The Path object representing the SVG outline to be drawn.
  /// If null, nothing will be drawn for the outline.
  final ui.Path? svgOutlinePath;

  /// Constructor for DrawingCanvasPainter.
  ///
  /// [svgOutlinePath] is the path generated from your SVG data.
  /// You would typically load this path from an SVG string or file.
  DrawingCanvasPainter({
    this.svgOutlinePath,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Define the style for painting the SVG outline.
    // This will typically be a stroke (outline) with a specific color and width.
    final Paint outlinePaint = Paint()
      ..color = Colors.black // The color of the SVG outline
      ..style = PaintingStyle.stroke // Draw only the outline, not fill the shape
      ..strokeWidth = 2.0 // The thickness of the outline
      ..isAntiAlias = true; // For smoother edges

    // If an SVG path is provided, draw it on the canvas.
    // The canvas is the area where you can draw shapes, paths, images, etc.
    if (svgOutlinePath != null) {
      canvas.drawPath(svgOutlinePath!, outlinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant DrawingCanvasPainter oldDelegate) {
    // This method is crucial for performance. It tells Flutter whether
    // the CustomPaint widget needs to be repainted.
    //
    // We should repaint if the 'svgOutlinePath' has changed.
    // If other properties were added (e.g., outlineColor, strokeWidth),
    // they should also be compared here.
    return oldDelegate.svgOutlinePath != svgOutlinePath;
  }
}