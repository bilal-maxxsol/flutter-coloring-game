import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/coloring_picture.dart';

/// A service to manage coloring pictures, load SVG assets, navigate between
/// pictures, and persist/retrieve drawing states using Hive.
class PictureService {
  static const String _boxName = 'drawingStates'; // Hive box name

  // List of placeholder coloring pictures
  final List<ColoringPicture> _pictures = [
    ColoringPicture(id: 'pic_1', svgAssetPath: 'assets/svgs/shape_1.svg'),
    ColoringPicture(id: 'pic_2', svgAssetPath: 'assets/svgs/shape_2.svg'),
    ColoringPicture(id: 'pic_3', svgAssetPath: 'assets/svgs/goku.svg'),
    ColoringPicture(id: 'pic_4', svgAssetPath: 'assets/svgs/shape_4.svg'),
  ];

  int _currentIndex = 0; // Current picture index
  late Box<Uint8List> _drawingBox; // Hive box for storing drawing data

  /// Initializes the PictureService, including Hive.
  Future<void> initialize() async {
    await Hive.initFlutter();

    // Open the Hive box where drawing states will be stored.
    // If the box doesn't exist, Hive will create it.
    _drawingBox = await Hive.openBox<Uint8List>(_boxName);
  }

  Future<void> dispose() async {
    await _drawingBox.close();
  }

  /// Returns the currently active coloring picture.
  ColoringPicture get currentPicture => _pictures[_currentIndex];

  /// Loads the SVG asset for the current picture and prepares it for CustomPaint.
  ///
  /// Returns a [ui.Picture] that can be drawn on a canvas, or null if loading fails.
  /// A [ui.Picture] is more flexible for SVG rendering than just a [ui.Path].
  Future<ui.Picture?> loadCurrentPictureSvg() async {
  final String svgAssetPath = currentPicture.svgAssetPath;
  try {
    final String svgString = await rootBundle.loadString(svgAssetPath);

    // Use SvgStringLoader to provide the SVG data to vg.loadPicture.
    // SvgStringLoader implements PictureProvider.
    final SvgStringLoader svgStringLoader = SvgStringLoader(svgString);

    // Load the picture and get PictureInfo, which contains both the ui.Picture and its size.
    // The second argument (stream) can be null if providing a synchronous loader like SvgStringLoader.
    final PictureInfo pictureInfo = await vg.loadPicture(svgStringLoader, null);
    final ui.Picture originalSvgPicture = pictureInfo.picture; // Extract the ui.Picture

    // Determine the intrinsic size from PictureInfo
    final double svgIntrinsicWidth = pictureInfo.size.width;
    final double svgIntrinsicHeight = pictureInfo.size.height;

    // Define the target dimensions for the recorded Picture.
    // We'll use the intrinsic size for the recorder's canvas,
    // falling back to a default if the SVG's intrinsic size is zero or not defined.
    // This ensures the recorded picture has valid dimensions.
    final double targetWidth = svgIntrinsicWidth > 0 ? svgIntrinsicWidth : 300.0;
    final double targetHeight = svgIntrinsicHeight > 0 ? svgIntrinsicHeight : 300.0;

    // Create a PictureRecorder to record the SVG drawing operations onto a new Picture.
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    // Define the canvas bounds for the recorder, using the target dimensions.
    final ui.Canvas canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, targetWidth, targetHeight));

    // Apply scaling if the target dimensions differ from the intrinsic SVG dimensions.
    // This scales the *drawing operations* to fit the canvas.
    if (svgIntrinsicWidth > 0 && svgIntrinsicHeight > 0) {
      canvas.scale(targetWidth / svgIntrinsicWidth, targetHeight / svgIntrinsicHeight);
    }

    // Draw the original SVG picture onto the recorder's canvas.
    canvas.drawPicture(originalSvgPicture);

    final ui.Picture recordedPicture = recorder.endRecording();

    // IMPORTANT: Dispose of the original ui.Picture from PictureInfo to free up resources.
    // The `recordedPicture` is a new Picture and manages its own resources.
    originalSvgPicture.dispose();

    return recordedPicture;
  } catch (e) {
    print('Error loading SVG from $svgAssetPath: $e');
    return null;
  }
}

  /// Navigates to the next picture in the list.
  ///
  /// Returns the new current picture.
  ColoringPicture nextPicture() {
    _currentIndex = (_currentIndex + 1) % _pictures.length;
    return currentPicture;
  }

  /// Navigates to the previous picture in the list.
  ///
  /// Returns the new current picture.
  ColoringPicture previousPicture() {
    _currentIndex = (_currentIndex - 1 + _pictures.length) % _pictures.length;
    return currentPicture;
  }

  /// Stores the current drawing state (raw pixel data) for the given picture ID.
  ///
  /// [pictureId]: The ID of the picture.
  /// [pixelData]: The raw RGBA pixel data (Uint8List) of the canvas.
  Future<void> saveDrawingState(String pictureId, Uint8List pixelData) async {
    await _drawingBox.put(pictureId, pixelData);
  }

  /// Retrieves the stored drawing state (raw pixel data) for a given picture ID.
  ///
  /// [pictureId]: The ID of the picture.
  /// Returns the raw RGBA pixel data (Uint8List) if found, otherwise null.
  Future<Uint8List?> loadDrawingState(String pictureId) async {
    final Uint8List? pixelData = _drawingBox.get(pictureId);
    return pixelData;
  }

  /// Clears the saved drawing state for a specific picture.
  Future<void> clearDrawingState(String pictureId) async {
    await _drawingBox.delete(pictureId);
  }
}
