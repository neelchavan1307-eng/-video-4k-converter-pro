import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/statistics.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(MaterialApp(home: MergedApp(), debugShowCheckedModeBanner: false));
}

class MergedApp extends StatefulWidget {
  @override
  State<MergedApp> createState() => _MergedAppState();
}

class _MergedAppState extends State<MergedApp> {
  File? pickedFile;
  VideoPlayerController? _c;
  String status = "Video Select Kara";
  bool processing = false;
  bool showComparison = true;
  double previewProgress = 0;
  double convertProgress = 0;

  double focusFilter = 50;
  double fourKFilter = 70;
  double whitening = 25;
  double brilliance = 20;
  double sharpen = 60;
  String selectedMode = "Devi Glow";
  double intensity = 40;
  String selectedCategory = "Cinematic";
  String selectedFilter = "Oppenheimer";

  Map<String, List<String>> categories = {
    "Cinematic": ["Green Orange", "Sicily", "Oppenheimer",
