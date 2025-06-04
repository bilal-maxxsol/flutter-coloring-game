import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:coloring_game/utils/image_flood_fill.dart';
import 'package:flutter/material.dart';

import '../models/coloring_picture.dart';
import '../services/picture_service.dart';
import '../widgets/color_palette.dart';
import '../widgets/drawing_canvas_painter.dart';

class DrawingScreen extends StatefulWidget {
  final PictureService pictureService;
  const DrawingScreen({super.key, required this.pictureService});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  // State variables for the current drawing
  ui.Picture? _currentSvgOutlinePicture; // SVG picture from flutter_svg
  ui.Image? _currentDrawingImage; // The image representing the user's drawing
  Color _selectedDrawingColor = Colors.black; // Color from palette

  // GlobalKey to get the size and position of the CustomPaint widget
  final GlobalKey _drawingAreaKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Load the initial picture and drawing state
    _loadPictureAndDrawingState(widget.pictureService.currentPicture);
  }

  @override
  void dispose() {
    // Dispose of the PictureService when the screen is removed
    widget.pictureService.dispose();
    super.dispose();
  }

  /// Loads the SVG for the given picture and its saved drawing state.
  Future<void> _loadPictureAndDrawingState(ColoringPicture picture) async {
    // 1. Load SVG outline
    final loadedSvgPicture = await widget.pictureService
        .loadCurrentPictureSvg();

    // 2. Load saved drawing state (raw pixel data)
    final Uint8List? savedPixelData = await widget.pictureService
        .loadDrawingState(picture.id);

    ui.Image? loadedDrawingImage;
    if (savedPixelData != null) {
      // Decode the saved pixel data back into a ui.Image
      // We need width and height to decode the image.
      // For now, let's assume a default fixed size for the canvas or infer from SVG.
      // In a real app, you might save width/height along with pixel data.
      // For demonstration, let's assume a square image for simplicity.
      // You'd need to ensure the savedPixelData matches the actual canvas dimensions.
      // If the dimensions change, the old saved image might not fit correctly.
      try {
        final ui.ImmutableBuffer buffer =
            await ui.ImmutableBuffer.fromUint8List(savedPixelData);
        final ui.Codec codec = await ui.ImageDescriptor.raw(
          buffer,
          width: 300, // Example: Assuming a fixed canvas width for saved image
          height:
              300, // Example: Assuming a fixed canvas height for saved image
          rowBytes: 300 * 4, // width * 4 bytes per pixel (RGBA)
          pixelFormat: ui.PixelFormat.rgba8888,
        ).instantiateCodec();
        final ui.FrameInfo frameInfo = await codec.getNextFrame();
        loadedDrawingImage = frameInfo.image;
        print('Successfully decoded saved image for ${picture.id}');
      } catch (e) {
        print('Error decoding saved image for ${picture.id}: $e');
        loadedDrawingImage = null; // Fallback if decoding fails
      }
    }

    setState(() {
      _currentSvgOutlinePicture = loadedSvgPicture;
      _currentDrawingImage = loadedDrawingImage;
    });
  }

  // --- Helper to capture current CustomPaint content as ui.Image ---
  Future<ui.Image> _captureDrawingAreaAsImage() async {
    final RenderBox? renderBox =
        _drawingAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      throw Exception("Drawing area not rendered or GlobalKey not attached.");
    }

    final Size size = renderBox.size;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    // Ensure the background is drawn first (white or existing image)
    if (_currentDrawingImage != null) {
      final Rect src = Rect.fromLTWH(
        0,
        0,
        _currentDrawingImage!.width.toDouble(),
        _currentDrawingImage!.height.toDouble(),
      );
      final Rect dst = Rect.fromLTWH(0, 0, size.width, size.height);
      canvas.drawImageRect(_currentDrawingImage!, src, dst, Paint());
    } else {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.white,
      );
    }

    // Then draw the SVG outline on top (as it's part of the picture).
    // This is important for flood fill to work correctly on the outlines.
    if (_currentSvgOutlinePicture != null) {
      canvas.drawPicture(_currentSvgOutlinePicture!);
    }

    // If there were any other custom drawing strokes/paths on top of the image,
    // they would be drawn here as well.
    // E.g., if you had `List<Path> _drawingStrokes`, you would iterate and draw them.

    final ui.Picture picture = recorder.endRecording();
    return await picture.toImage(size.width.toInt(), size.height.toInt());
  }

  // --- Event Handlers ---
  void _handleColorSelected(Color color) {
    setState(() {
      _selectedDrawingColor = color;
    });
    print('Selected drawing color: $_selectedDrawingColor');
  }

  Future<void> _handleFloodFillTap(TapUpDetails details) async {
    final RenderBox? renderBox =
        _drawingAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Offset localPosition = renderBox.globalToLocal(
      details.globalPosition,
    );
    final int tapX = localPosition.dx.toInt();
    final int tapY = localPosition.dy.toInt();

    print('Tapped at: ($tapX, $tapY)');

    try {
      // 1. Capture the current visible state of the canvas as an image
      ui.Image currentImage = await _captureDrawingAreaAsImage();

      // 2. Determine the target color at the tapped point
      final ByteData? byteData = await currentImage.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (byteData == null) {
        print('Failed to get byte data for flood fill target color.');
        return;
      }
      final Uint8List pixels = byteData.buffer.asUint8List();
      final int pixelIndex = (tapY * currentImage.width + tapX) * 4;

      if (pixelIndex < 0 || pixelIndex >= pixels.length - 3) {
        print('Tap point out of bounds for pixel data array.');
        return;
      }

      final Color targetColorAtTap = Color.fromARGB(
        pixels[pixelIndex + 3], // Alpha
        pixels[pixelIndex], // Red
        pixels[pixelIndex + 1], // Green
        pixels[pixelIndex + 2], // Blue
      );
      print('Target color at tap: $targetColorAtTap');

      // Prevent filling if target color is the new fill color or black outline
      if (targetColorAtTap == _selectedDrawingColor ||
          targetColorAtTap == Colors.black) {
        print(
          'Skipping fill: Target color is already selected color or black outline.',
        );
        return;
      }

      // 3. Perform the flood fill algorithm
      ui.Image filledImage = await floodFill(
        currentImage,
        tapX,
        tapY,
        targetColorAtTap, // Actual color at tap point
        _selectedDrawingColor, // New color from palette
      );

      // 4. Update the state with the new filled image
      setState(() {
        _currentDrawingImage = filledImage;
      });

      // 5. Save the updated drawing state to Hive
      // 1. Await the Future to get the ByteData object (which might be null)
      final ByteData? filledImageByteData = await filledImage.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );

      // 2. Now, safely access the buffer if byteData is not null
      final Uint8List? filledImageData = filledImageByteData?.buffer.asUint8List();
      if (filledImageData != null) {
        await widget.pictureService.saveDrawingState(
          widget.pictureService.currentPicture.id,
          filledImageData,
        );
      }
      print('Flood fill completed and drawing state saved.');
    } catch (e) {
      print('Error during flood fill: $e');
    }
  }

  Future<void> _handleNextPicture() async {
    widget.pictureService.nextPicture();
    await _loadPictureAndDrawingState(widget.pictureService.currentPicture);
  }

  Future<void> _handlePreviousPicture() async {
    widget.pictureService.previousPicture();
    await _loadPictureAndDrawingState(widget.pictureService.currentPicture);
  }

  Future<void> _handleClearDrawing() async {
    // Clear the current in-memory drawing image
    setState(() {
      _currentDrawingImage = null; // Or create a blank white image if preferred
    });
    // Also clear from persistent storage
    await widget.pictureService.clearDrawingState(
      widget.pictureService.currentPicture.id,
    );
    print('Drawing cleared for ${widget.pictureService.currentPicture.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kids Coloring: ${widget.pictureService.currentPicture.id}',
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handlePreviousPicture,
            tooltip: 'Previous Picture',
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: _handleNextPicture,
            tooltip: 'Next Picture',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: Container(
              color: Colors.white, // Default canvas background
              child: GestureDetector(
                onTapUp: _handleFloodFillTap, // Detect taps for flood fill
                child: CustomPaint(
                  key: _drawingAreaKey, // Attach GlobalKey here
                  painter: DrawingCanvasPainter(
                    svgPictureOutline: _currentSvgOutlinePicture,
                    backgroundImage:
                        _currentDrawingImage, // Pass the current drawing image
                  ),
                  // The size should be determined by the Expanded widget
                  // You might consider a Fixed size box for predictable image saving/loading.
                  // size: Size.infinite,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.blueGrey[100],
            child: Column(
              children: <Widget>[
                ColorPalette(
                  onColorSelected: _handleColorSelected,
                  initialColor: _selectedDrawingColor,
                ),
                const SizedBox(height: 10.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: _handleClearDrawing, // Link to clear drawing
                      child: const Text('Clear Drawing'),
                    ),
                    ElevatedButton(
                      onPressed: null, // Undo/Redo logic would go here
                      child: const Text('Undo'),
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
