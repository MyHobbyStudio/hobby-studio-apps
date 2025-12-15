import 'dart:io';
import 'package:flutter/material.dart';

class CardImageViewerScreen extends StatelessWidget {
  final File imageFile;
  final String heroTag;

  const CardImageViewerScreen({
    super.key,
    required this.imageFile,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: Hero(
            tag: heroTag,
            child: Image.file(
              imageFile,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}