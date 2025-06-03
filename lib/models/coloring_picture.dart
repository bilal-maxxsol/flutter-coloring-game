// lib/models/coloring_picture.dart
class ColoringPicture {
  final String id;
  final String svgAssetPath;

  ColoringPicture({
    required this.id,
    required this.svgAssetPath,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColoringPicture &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}