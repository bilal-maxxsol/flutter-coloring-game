import 'dart:typed_data';
import 'dart:ui' as ui; // Alias for dart:ui

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
  // Ensure the starting coordinates are within the image bounds.
  if (startX < 0 || startX >= width || startY < 0 || startY >= height) {
    return image; // Start point out of bounds, no fill possible.
  }

  // Convert the image to raw RGBA 8888 byte data for pixel manipulation.
  // This is an asynchronous operation.
  final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (byteData == null) {
    return image; // Could not get byte data.
  }

  // Create a mutable Uint8List view of the byte data for easier pixel access.
  final Uint8List pixels = byteData.buffer.asUint8List();

  // Convert Color objects to their individual RGBA byte components.
  final int targetR = (targetColor.r * 255.0).round() & 0xff;
  final int targetG = (targetColor.g * 255.0).round() & 0xff;
  final int targetB = (targetColor.b * 255.0).round() & 0xff;
  final int targetA = (targetColor.a * 255.0).round() & 0xff;

  final int newFillR = (targetColor.r * 255.0).round() & 0xff;
  final int newFillG = (targetColor.g * 255.0).round() & 0xff;
  final int newFillB = (targetColor.b * 255.0).round() & 0xff;
  final int newFillA = (targetColor.a * 255.0).round() & 0xff;

  // Get the color of the starting pixel.
  // Calculate the byte index for the starting pixel. Each pixel is 4 bytes (R,G,B,A).
  final int startIndex = (startY * width + startX) * 4;

  // Check if the starting pixel's color is already the new fill color.
  // If so, there's nothing to do.
  if (pixels[startIndex] == newFillR &&
      pixels[startIndex + 1] == newFillG &&
      pixels[startIndex + 2] == newFillB &&
      pixels[startIndex + 3] == newFillA) {
    return image; // Already filled with the new color.
  }

  // Double-check: If the color at startX, startY is different from `targetColor`
  // passed into the function, it means the user clicked on an already
  // changed area or a boundary. In a typical drawing app, `targetColor`
  // would be inferred from the `image` at `(startX, startY)`.
  // For this function, we'll assume `targetColor` is the exact color to replace.
  // If the color at the start point doesn't match `targetColor`, we don't proceed.
  if (pixels[startIndex] != targetR ||
      pixels[startIndex + 1] != targetG ||
      pixels[startIndex + 2] != targetB ||
      pixels[startIndex + 3] != targetA) {
    return image; // Start pixel does not match the target color, no fill.
  }


  // --- 2. Iterative Flood Fill Algorithm (Queue-based) ---
  // Using a List as a queue and managing it with a head pointer for efficiency
  // (avoids constant reallocation of the list if using removeAt(0)).
  final List<List<int>> queue = [];
  queue.add([startX, startY]); // Add the starting pixel to the queue

  int head = 0; // Manual queue head pointer

  while (head < queue.length) {
    final List<int> currentPoint = queue[head++]; // Dequeue the current pixel
    final int cx = currentPoint[0];
    final int cy = currentPoint[1];

    // Define the 4 directions to check (right, left, down, up)
    final List<List<int>> directions = [
      [1, 0],  // Right
      [-1, 0], // Left
      [0, 1],  // Down
      [0, -1], // Up
    ];

    for (final dir in directions) {
      final int nx = cx + dir[0];
      final int ny = cy + dir[1];

      // Calculate the byte index for the potential neighbor pixel.
      final int neighborPixelIndex = (ny * width + nx) * 4;

      // Check if the neighbor is within bounds AND its color matches the target color.
      if (nx >= 0 && nx < width && ny >= 0 && ny < height &&
          pixels[neighborPixelIndex] == targetR &&
          pixels[neighborPixelIndex + 1] == targetG &&
          pixels[neighborPixelIndex + 2] == targetB &&
          pixels[neighborPixelIndex + 3] == targetA) {
        
        // If it matches, change its color to the new fill color immediately
        // and enqueue it for further processing.
        pixels[neighborPixelIndex] = newFillR;
        pixels[neighborPixelIndex + 1] = newFillG;
        pixels[neighborPixelIndex + 2] = newFillB;
        pixels[neighborPixelIndex + 3] = newFillA;

        queue.add([nx, ny]); // Enqueue the neighbor
      }
    }
  }

  // --- 3. Create New ui.Image from Modified Pixels ---
  // Create an ImmutableBuffer from the modified Uint8List.
  final ui.ImmutableBuffer immutableBuffer = await ui.ImmutableBuffer.fromUint8List(pixels);

  // Decode the new image from the modified pixel data.
  // The 'pixelFormat' argument is required here. We specify rgba8888 as
  // that's what we used when getting the byte data.
  final ui.Codec codec = await ui.ImageDescriptor.raw(
    immutableBuffer, // Use the ImmutableBuffer
    width: width,
    height: height,
    rowBytes: width * 4, // 4 bytes per pixel (RGBA)
    pixelFormat: ui.PixelFormat.rgba8888, // Correctly added the required pixelFormat
  ).instantiateCodec();
  final ui.FrameInfo frameInfo = await codec.getNextFrame();
  return frameInfo.image;
}