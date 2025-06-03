import 'package:coloring_game/widgets/drawing_app.dart';
import 'package:flutter/material.dart';

import 'services/picture_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize the PictureService when the app starts
  final pictureService = PictureService();
  await pictureService.initialize();
  runApp(DrawingApp(pictureService: pictureService));
}
