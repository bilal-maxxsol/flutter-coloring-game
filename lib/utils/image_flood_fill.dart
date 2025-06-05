import 'dart:typed_data';
import 'dart:ui' as ui; // Alias for dart:ui
import 'package:image/image.dart' as img;

/// Performs an iterative (queue-based) flood fill algorithm on a given image.
///
/// This function modifies a contiguous area of a target color starting from
/// `startX`, `startY` and fills it with `newFillColor`.
///
/// [image]: The ui.Image to perform the flood fill on. This image will be
///          converted to raw pixel data for modification.
/// [startX], [startY]: The starting coordinates (x, y) for the flood fill.
/// [targetColor]: The color of the contiguous area to be replaced. This is
///                the color of the pixel at (startX, startY) usually.
/// [newFillColor]: The color to fill the area with.
///
/// Returns a new ui.Image with the filled area, or the original image if
/// no fill is necessary or if the start point is out of bounds.
Future<ui.Image> floodFill(
  ui.Image image,
  int startX,
  int startY,
  ui.Color targetColor,
  ui.Color newFillColor,
) async {
  final int width = image.width;
  final int height = image.height;


  // --- 1. Initial Checks and Setup ---
  if (startX < 0 || startX >= width || startY < 0 || startY >= height) {
    print('FloodFill: Start point ($startX, $startY) out of bounds.');
    return image;
  }

  final ByteData? byteData = await image.toByteData(
    format: ui.ImageByteFormat.rawRgba,
  );
  if (byteData == null) {
    print('FloodFill: Could not get byte data from image.');
    return image;
  }

  final Uint8List pixels = byteData.buffer.asUint8List();

  // Convert targetColor to its RGBA byte components.
  final int targetValue = targetColor.toARGB32(); // Use toARGB32() now
  final int targetA = (targetValue >> 24) & 0xFF;
  final int targetR = (targetValue >> 16) & 0xFF;
  final int targetG = (targetValue >> 8) & 0xFF;
  final int targetB = targetValue & 0xFF;

  // FIXED: Convert newFillColor to its RGBA byte components.
  final int newFillValue = newFillColor.toARGB32(); // Use toARGB32() now
  final int newFillA = (newFillValue >> 24) & 0xFF;
  final int newFillR = (newFillValue >> 16) & 0xFF;
  final int newFillG = (newFillValue >> 8) & 0xFF;
  final int newFillB = newFillValue & 0xFF;

  final int startIndex = (startY * width + startX) * 4;

  // Get the actual color of the starting pixel in the image.
  final int startPixelR = pixels[startIndex];
  final int startPixelG = pixels[startIndex + 1];
  final int startPixelB = pixels[startIndex + 2];
  final int startPixelA = pixels[startIndex + 3];

  // Removed print statement

  // Check if the starting pixel's color is already the new fill color.
  if (startPixelR == newFillR &&
      startPixelG == newFillG &&
      startPixelB == newFillB &&
      startPixelA == newFillA) {
    print('FloodFill: Start pixel already has the new fill color. Returning.');
    return image;
  }

  // Check if the starting pixel's color matches the target color to replace.
  // If it doesn't, it means the user clicked on a boundary or an already different area.
  if (startPixelR != targetR ||
      startPixelG != targetG ||
      startPixelB != targetB ||
      startPixelA != targetA) {
    print(
      'FloodFill: Start pixel color does not match target color. Returning. (Actual: $startPixelR,$startPixelG,$startPixelB,$startPixelA vs Target: $targetR,$targetG,$targetB,$targetA)',
    );
    return image;
  }

  // --- 2. Iterative Flood Fill Algorithm (Queue-based) ---
  final List<List<int>> queue = [];
  queue.add([startX, startY]);

  // Immediately change the color of the starting pixel.
  pixels[startIndex] = newFillR;
  pixels[startIndex + 1] = newFillG;
  pixels[startIndex + 2] = newFillB;
  pixels[startIndex + 3] = newFillA;

  int head = 0;

  // A boolean array to keep track of visited pixels to prevent infinite loops and re-processing.
  // This is crucial for efficiency and correctness.
  final List<bool> visited = List.filled(width * height, false);
  visited[startY * width + startX] = true; // Mark starting pixel as visited

  while (head < queue.length) {
    final List<int> currentPoint = queue[head++];
    final int cx = currentPoint[0];
    final int cy = currentPoint[1];

    final List<List<int>> directions = [
      [1, 0], // Right
      [-1, 0], // Left
      [0, 1], // Down
      [0, -1], // Up
    ];

    for (final dir in directions) {
      final int nx = cx + dir[0];
      final int ny = cy + dir[1];

      // Calculate the 1D index for visited array
      final int newIndex1D = ny * width + nx;

      // Check if the neighbor is within bounds AND has not been visited yet.
      if (nx >= 0 &&
          nx < width &&
          ny >= 0 &&
          ny < height &&
          !visited[newIndex1D]) {
        final int neighborPixelIndex = newIndex1D * 4;

        // Get the current color of the neighbor pixel from the pixel data.
        final int neighborR = pixels[neighborPixelIndex];
        final int neighborG = pixels[neighborPixelIndex + 1];
        final int neighborB = pixels[neighborPixelIndex + 2];
        final int neighborA = pixels[neighborPixelIndex + 3];

        // Check if the neighbor's color matches the original target color.
        if (neighborR == targetR &&
            neighborG == targetG &&
            neighborB == targetB &&
            neighborA == targetA) {
          // If it matches, change its color to the new fill color,
          // mark it as visited, and enqueue it for further processing.
          pixels[neighborPixelIndex] = newFillR;
          pixels[neighborPixelIndex + 1] = newFillG;
          pixels[neighborPixelIndex + 2] = newFillB;
          pixels[neighborPixelIndex + 3] = newFillA;

          visited[newIndex1D] = true; // Mark as visited
          queue.add([nx, ny]); // Enqueue the neighbor
        }
      }
    }
  }

  // --- 3. Create New ui.Image from Modified Pixels ---
  try {
  // 1. Create an img.Image from your raw Uint8List pixels
  img.Image? baseImage = img.Image.fromBytes(
    width: width,
    height: height,
    bytes: pixels.buffer,
    format: img.Format.uint8,
    numChannels: 4,
    order: img.ChannelOrder.rgba,
  );

  if (baseImage == null) {
    print('🚨 FloodFill: Failed to create img.Image from raw pixels.');
    // Fallback or error handling
    return image; // Return original image if conversion fails
  }

  // 2. Encode the img.Image to PNG format
  final Uint8List encodedPng = img.encodePng(baseImage);

  // 3. Use Flutter's ui.instantiateImageCodec to decode the PNG and get a ui.Image
  ui.Codec codec = await ui.instantiateImageCodec(encodedPng);
  final ui.FrameInfo frameInfo = await codec.getNextFrame();

  return frameInfo.image;

} catch (e) {
  print('🚨 Error during image reconstruction with package:image: $e');
  // Re-throw or return original image on failure
  return image;
}
}
