import 'package:flutter/material.dart';

/// A callback function type that takes a Color argument.
typedef ColorSelectionCallback = void Function(Color selectedColor);

/// A responsive color palette widget that displays a list of color swatches.
///
/// When a color swatch is tapped, it triggers a callback with the selected color
/// and visually indicates the selection with a border.
class ColorPalette extends StatefulWidget {
  /// The callback function to be called when a new color is selected.
  final ColorSelectionCallback onColorSelected;

  /// The initial selected color for the palette.
  final Color? initialColor;

  /// A list of colors to display in the palette.
  final List<Color> colors;

  const ColorPalette({
    super.key,
    required this.onColorSelected,
    this.initialColor,
    this.colors = const [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
      Colors.black,
    ],
  });

  @override
  State<ColorPalette> createState() => _ColorPaletteState();
}

class _ColorPaletteState extends State<ColorPalette> {
  // The currently selected color in the palette.
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    // Initialize _selectedColor with initialColor if provided, otherwise with the first color in the list.
    _selectedColor = widget.initialColor ?? widget.colors.first;
    // Trigger the initial selection callback if initialColor is provided
    // or if we default to the first color.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onColorSelected(_selectedColor);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Using a Wrap widget allows the color swatches to flow to the next line
    // when there isn't enough horizontal space, making it responsive.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Wrap(
        alignment: WrapAlignment.center, // Center the swatches if they wrap
        spacing: 8.0, // Horizontal space between swatches
        runSpacing: 8.0, // Vertical space between lines of swatches
        children: widget.colors.map((color) {
          // Determine if the current color swatch is the selected one.
          final isSelected = _selectedColor == color;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedColor = color; // Update the selected color
              });
              widget.onColorSelected(color); // Call the callback with the new color
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200), // Smooth transition for border/size changes
              width: isSelected ? 48.0 : 40.0, // Larger size for selected
              height: isSelected ? 48.0 : 40.0, // Larger size for selected
              decoration: BoxDecoration(
                color: color, // The actual color of the swatch
                shape: BoxShape.circle, // Make it circular
                border: isSelected
                    ? Border.all(
                        color: Colors.white, // White border for selected
                        width: 3.0, // Thicker border
                      )
                    : Border.all(
                        color: Colors.transparent, // Transparent border for unselected
                        width: 0.0, // No visible border
                      ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2), // Shadow for depth
                  ),
                ],
              ),
            ),
          );
        }).toList(), // Convert the iterable of widgets to a List
      ),
    );
  }
}