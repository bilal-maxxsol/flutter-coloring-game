import 'package:coloring_game/screens/drawing_screen.dart';
import 'package:flutter/material.dart';

import '../services/picture_service.dart';

class DrawingApp extends StatelessWidget {
  final PictureService pictureService;
  const DrawingApp({super.key, required this.pictureService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kids Drawing App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: DrawingScreen(pictureService: pictureService),
    );
  }
}