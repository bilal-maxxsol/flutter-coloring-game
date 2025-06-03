import 'dart:ui' as ui;

import 'package:coloring_game/utils/image_flood_fill.dart';
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
  Color _selectedDrawingColor =
      Colors.black; // New: To store the selected drawing color

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
      if (_currentSvgOutline == null ||
          _currentSvgOutline!.getBounds().width == 100) {
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

  // Method to capture the current state of the CustomPaint as an Image
  Future<ui.Image> _captureDrawingAreaAsImage() async {
    // Create a PictureRecorder to record drawing operations.
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    // Create a Canvas that draws onto the recorder.
    final Canvas canvas = Canvas(recorder);

    // Get the size of the drawing area. You might need to store this in your state
    // or get it from a GlobalKey on the CustomPaint or its parent.
    // For simplicity, let's assume a fixed size or derive it from context size.
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Size size = renderBox.size; // Get the size of the widget

    // Draw the background color
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    // Create a temporary painter instance for the current outline
    final DrawingCanvasPainter currentPainter = DrawingCanvasPainter(
      svgOutlinePath: _currentSvgOutline,
    );

    // Call the paint method on the temporary painter with the current canvas and size.
    // This re-draws the SVG outline onto our recorder's canvas.
    currentPainter.paint(canvas, size);

    // End recording and convert the Picture to an Image.
    final ui.Picture picture = recorder.endRecording();
    return await picture.toImage(size.width.toInt(), size.height.toInt());
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
                const SizedBox(
                  height: 10.0,
                ), // Spacing between palette and buttons
                // Placeholder for control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: () async {
                        if (_currentSvgOutline != null) {
                          // 1. Get the current image from the drawing canvas
                          ui.Image currentImage =
                              await _captureDrawingAreaAsImage();

                          // For demonstration, let's pick a center point for flood fill
                          final RenderBox renderBox =
                              context.findRenderObject() as RenderBox;
                          final Size canvasSize = renderBox.size;
                          int startX = (canvasSize.width / 2).toInt();
                          int startY = (canvasSize.height / 2).toInt();

                          // 2. Get the target color (color at the start point)
                          // This requires reading pixel data from currentImage
                          // This part is complex. For a simple example, let's assume
                          // the target color is the background white for the SVG drawing.
                          // In a real scenario, you'd get the pixel color at (startX, startY)
                          // from `currentImage`'s raw data.
                          // For now, let's assume we want to fill the white background.
                          Color inferredTargetColor = Colors
                              .white; // Or read from image[startX, startY]

                          // 3. Perform the flood fill
                          ui.Image filledImage = await floodFill(
                            currentImage,
                            startX,
                            startY,
                            inferredTargetColor, // Replace this with the actual color of the area to fill
                            _selectedDrawingColor, // Use the color from your palette
                          );

                          // 4. Update your state to display the new filled image.
                          // You might need a new state variable like `ui.Image? _filledImage;`
                          // and then draw this `_filledImage` in your CustomPaint.
                          // This requires a CustomPainter that can draw a ui.Image.
                          // For simplicity, let's just update the _currentSvgOutline for visual demo.
                          // This is NOT ideal for flood fill as it's meant to draw over an existing image.
                          // A better approach would be to have a painter that draws a background image,
                          // and then possibly strokes on top.

                          // To actually display the filled image, you'd modify your painter
                          // to take an image as well as paths, or draw the image directly.
                          // Let's create a temporary painter that can draw an image.
                          setState(() {
                            // How to display: You need to pass the filledImage to your painter.
                            // If your painter only handles paths, you'd need a new painter
                            // or modify DrawingCanvasPainter to accept a background image.
                            // For now, let's just confirm it worked.
                            print("Flood fill complete! Image generated.");
                            // To actually show this, you would change your DrawingCanvasPainter
                            // or use a new painter that draws a ui.Image.
                            // Example:
                            // _displayedFilledImage = filledImage; // Add this state variable
                          });
                        }
                      },
                      child: const Text('Fill Area'),
                    ),
                    ElevatedButton(
                      onPressed: null,
                      child: Text('Clear Drawing'),
                    ),
                    ElevatedButton(onPressed: null, child: Text('Undo')),
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
