import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../widgets/drawing_canvas_painter.dart';

class DrawingScreen extends StatefulWidget {
  const DrawingScreen({super.key});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  // This variable will hold the Path object for the SVG outline.
  // It's nullable because we might not have an outline loaded yet, or it could be cleared.
  ui.Path? _currentSvgOutline;

  @override
  void initState() {
    super.initState();
    // Initialize with a sample outline path when the screen loads.
    // In a real app, you would load this from an SVG file or a data source.
    _currentSvgOutline = _createSampleSvgOutline();
  }

  /// Creates a simple sample Path resembling an SVG outline.
  /// In a real app, you would use a package like 'flutter_svg'
  /// to parse an SVG string into a ui.Path.
  ui.Path _createSampleSvgOutline() {
    return ui.Path()
      ..moveTo(100, 100) // Start point
      ..lineTo(200, 100) // Line to the right
      ..lineTo(200, 200) // Line down
      ..lineTo(100, 200) // Line left
      ..close(); // Close the path to form a square
  }

  /// Creates another sample Path.
  ui.Path _createAnotherSampleOutline(size) {
    return ui.Path()
      ..moveTo(size.width / 2, 50)
      ..arcToPoint(Offset(size.width - 50, size.height / 2),
          radius: const Radius.circular(50), largeArc: true)
      ..lineTo(50, size.height - 50)
      ..close();
  }
  // Note: size is not available directly here in _createAnotherSampleOutline
  // You'd need to pass it or create the path dynamically inside the build method
  // or after layout is known. For a simple example, let's keep it fixed or
  // pass size as an argument to these helper methods if they were external.
  // For demonstration purposes, _createSampleSvgOutline is simpler.

  /// Method to "clear" the canvas by removing the SVG outline.
  /// This is done by setting the `_currentSvgOutline` to null and
  /// calling `setState` to trigger a repaint.
  void _clearSvgOutline() {
    setState(() {
      _currentSvgOutline = null; // Set to null to effectively clear the outline
    });
  }

  /// Method to load a new SVG path (demonstrative).
  /// In a real app, this would involve loading and parsing a new SVG.
  void _loadNewSvgOutline() {
    setState(() {
      // You could toggle between different paths or load a new one.
      if (_currentSvgOutline == null || _currentSvgOutline!.getBounds().width == 100) {
        _currentSvgOutline = ui.Path()
          ..addOval(Rect.fromLTWH(50, 50, 200, 150)); // An oval
      } else {
        _currentSvgOutline = _createSampleSvgOutline(); // Back to square
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kids Drawing Pad'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearSvgOutline, // Call method to clear the outline
            tooltip: 'Clear SVG Outline',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNewSvgOutline, // Call method to load a new outline
            tooltip: 'Load New SVG Outline',
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          // This Expanded widget houses the CustomPaint canvas
          Expanded(
            child: Container(
              color: Colors.white, // The canvas background color
              // Use CustomPaint here to draw your SVG outline
              child: CustomPaint(
                // Pass an instance of your DrawingCanvasPainter
                // and provide the current SVG path.
                painter: DrawingCanvasPainter(
                  svgOutlinePath: _currentSvgOutline,
                ),
                // You can optionally provide a child to CustomPaint if you want
                // to draw *behind* or *on top* of another widget.
                // If you don't specify a size, CustomPaint will try to take
                // the size of its parent or its child. Expanded helps it fill.
                // size: Size.infinite, // Use this if not inside an Expanded/SizedBox
              ),
            ),
          ),
          // This Container will hold the color palette and control buttons
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.blueGrey[100],
            child: const Column(
              children: <Widget>[
                // Placeholder for color palette
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    CircleAvatar(backgroundColor: Colors.red, radius: 20),
                    CircleAvatar(backgroundColor: Colors.green, radius: 20),
                    CircleAvatar(backgroundColor: Colors.blue, radius: 20),
                    CircleAvatar(backgroundColor: Colors.yellow, radius: 20),
                  ],
                ),
                SizedBox(height: 16.0),
                // Placeholder for control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: null, // This would be for clearing user's drawing strokes
                      child: Text('Clear Drawing'),
                    ),
                    ElevatedButton(
                      onPressed: null, // For undoing user's drawing strokes
                      child: Text('Undo'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}