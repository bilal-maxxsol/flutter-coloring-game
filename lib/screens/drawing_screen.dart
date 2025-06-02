import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../widgets/color_palette.dart';
import '../widgets/drawing_canvas_painter.dart';

class DrawingScreen extends StatefulWidget {
  const DrawingScreen({super.key});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  ui.Path? _currentSvgOutline;
  Color _selectedDrawingColor = Colors.black; // New: To store the selected drawing color

  @override
  void initState() {
    super.initState();
    _currentSvgOutline = _createSampleSvgOutline();
  }

  ui.Path _createSampleSvgOutline() {
    return ui.Path()
      ..moveTo(100, 100)
      ..lineTo(200, 100)
      ..lineTo(200, 200)
      ..lineTo(100, 200)
      ..close();
  }

  void _clearSvgOutline() {
    setState(() {
      _currentSvgOutline = null;
    });
  }

  void _loadNewSvgOutline() {
    setState(() {
      if (_currentSvgOutline == null || _currentSvgOutline!.getBounds().width == 100) {
        _currentSvgOutline = ui.Path()
          ..addOval(Rect.fromLTWH(50, 50, 200, 150));
      } else {
        _currentSvgOutline = _createSampleSvgOutline();
      }
    });
  }

  // New: Callback method to receive the selected color from ColorPalette
  void _handleColorSelected(Color color) {
    setState(() {
      _selectedDrawingColor = color;
      // You could now use _selectedDrawingColor to update the drawing tool
      // For example, if you were drawing, this would be the current stroke color.
      print('Selected drawing color: $_selectedDrawingColor');
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
            onPressed: _clearSvgOutline,
            tooltip: 'Clear SVG Outline',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNewSvgOutline,
            tooltip: 'Load New SVG Outline',
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              color: Colors.white,
              child: CustomPaint(
                painter: DrawingCanvasPainter(
                  svgOutlinePath: _currentSvgOutline,
                ),
              ),
            ),
          ),
          // Replace the old color palette placeholder with your new ColorPalette widget
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.blueGrey[100],
            child: Column(
              children: <Widget>[
                // Your new ColorPalette widget goes here!
                ColorPalette(
                  onColorSelected: _handleColorSelected, // Pass your callback
                  initialColor: _selectedDrawingColor, // Pass the initial color
                ),
                const SizedBox(height: 10.0), // Spacing between palette and buttons
                // Placeholder for control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: null,
                      child: Text('Clear Drawing'),
                    ),
                    ElevatedButton(
                      onPressed: null,
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