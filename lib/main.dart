import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';

void main() => runApp(MaterialApp(home: ConverterApp(), debugShowCheckedModeBanner: false));

class ConverterApp extends StatefulWidget {
  @override State<ConverterApp> createState() => _ConverterAppState();
}

class _ConverterAppState extends State<ConverterApp> {
  String selectedQuality = "4K";
  Map<String, String> qualityMap = {"4K": "3840:2160", "2K": "2560:1440", "1080p": "1920:1080"};
  bool isConverting = false;
  double progress = 0;
  String status = "Ready to Clear Convert";
  List<String> convertedFiles = [];
  VideoPlayerController? controller;
  RangeValues trimRange = RangeValues(0, 100);
  int totalDurationMs = 0;
  List<String> inputFiles = [];

  Future<void> pickVideos() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video, allowMultiple: true);
    if (result == null) return;
    inputFiles = result.files.map((f) => f.path!).toList();
    if (inputFiles.isNotEmpty) {
      final info = await FFprobeKit.getMediaInformation(inputFiles.first);
      totalDurationMs = (double.tryParse(info.getMediaInformation()?.getDuration()?? "0")?? 0).toInt() * 1000;
      var c = VideoPlayerController.file(File(inputFiles.first));
      await c.initialize();
      setState(() {
        controller = c;
        status = "${inputFiles.length} Video निवडले";
      });
    }
  }

  String getTargetRes(int w, int h) {
    String base = qualityMap[selectedQuality]!;
    bool isPortrait = h > w;
    if (isPortrait) {
      var parts = base.split(":");
      return "${parts[1]}:${parts[0]}";
    }
    return base;
  }

  Future<void> convertAll() async {
    if (inputFiles.isEmpty) return;
    setState(() { isConverting = true; progress = 0; convertedFiles.clear(); });
    int done = 0;

    for (String inputPath in inputFiles) {
      final info = await FFprobeKit.getMediaInformation(inputPath);
      var mediaInfo = info.getMediaInformation();
      int w = mediaInfo?.getStreams().first.getWidth()?? 1920;
      int h = mediaInfo?.getStreams().first.getHeight()?? 1080;
      int fileDuration = (double.tryParse(mediaInfo?.getDuration()?? "0")?? 0).toInt() * 1000;

      double startSec = (trimRange.start / 100) * fileDuration / 1000;
      double endSec = (trimRange.end / 100) * fileDuration / 1000;

      String target = getTargetRes(w, h);
      String outputPath = "/storage/emulated/0/Movies/CLEAR_${selectedQuality}_${DateTime.now().millisecondsSinceEpoch}_$done.mp4";
      await Directory("/storage/emulated/0/Movies").create(recursive: true);

      String trimCmd = (trimRange.start > 0 || trimRange.end < 100)? "-ss $startSec -to $endSec" : "";

      // NEW CLEAR FILTER - हाच Main Fix आहे
      String clearFilter = "scale=$target:flags=lanczos:force_original_aspect_ratio=increase,crop=$target,setsar=1,unsharp=5:5:1.2
